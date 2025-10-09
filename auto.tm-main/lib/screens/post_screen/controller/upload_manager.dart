import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart'; // for compute
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import 'post_controller.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../global_controllers/connection_controller.dart';

/// Upload phases for a post task.
enum UploadPhase {
  preparing,
  uploadingVideo,
  uploadingPhotos,
  finalizing,
  complete,
  failed,
  cancelled,
}

/// High level failure categories for differentiated messaging / UI.
enum UploadFailureType { network, validation, cancelled, unknown }

/// Immutable snapshot of the form/media at the moment user pressed Post.
class PostUploadSnapshot {
  final String? brandUuid;
  final String? modelUuid;
  final String brandName;
  final String modelName;
  final List<int> photoBytesLengths; // size metadata only
  final List<String> photoBase64; // persisted for retry after app restart
  final bool hasVideo;
  final File? videoFile; // reference only (not copied)
  final bool usedCompressedVideo;
  final File? compressedVideoFile;
  final int originalVideoBytes;
  final int compressedVideoBytes;
  final String price;
  final String description;
  final String draftId; // can be empty if not tied to an existing draft
  PostUploadSnapshot({
    required this.brandUuid,
    required this.modelUuid,
    required this.brandName,
    required this.modelName,
    required this.photoBytesLengths,
    required this.photoBase64,
    required this.hasVideo,
    required this.videoFile,
    required this.usedCompressedVideo,
    required this.compressedVideoFile,
    required this.originalVideoBytes,
    required this.compressedVideoBytes,
    required this.price,
    required this.description,
    required this.draftId,
  });

  Map<String, dynamic> toMap() => {
    'brandUuid': brandUuid,
    'modelUuid': modelUuid,
    'brandName': brandName,
    'modelName': modelName,
    'photoBytesLengths': photoBytesLengths,
    'photoBase64': photoBase64,
    'hasVideo': hasVideo,
    'videoPath': videoFile?.path,
    'usedCompressedVideo': usedCompressedVideo,
    'compressedVideoPath': compressedVideoFile?.path,
    'originalVideoBytes': originalVideoBytes,
    'compressedVideoBytes': compressedVideoBytes,
    'price': price,
    'description': description,
    'draftId': draftId,
  };

  factory PostUploadSnapshot.fromMap(Map<String, dynamic> m) =>
      PostUploadSnapshot(
        brandUuid: m['brandUuid'] as String?,
        modelUuid: m['modelUuid'] as String?,
        brandName: (m['brandName'] ?? '') as String,
        modelName: (m['modelName'] ?? '') as String,
        photoBytesLengths:
            (m['photoBytesLengths'] as List?)?.whereType<int>().toList() ?? [],
        photoBase64:
            (m['photoBase64'] as List?)?.whereType<String>().toList() ?? [],
        hasVideo: m['hasVideo'] == true,
        videoFile:
            m['videoPath'] != null && (m['videoPath'] as String).isNotEmpty
            ? File(m['videoPath'])
            : null,
        usedCompressedVideo: m['usedCompressedVideo'] == true,
        compressedVideoFile:
            m['compressedVideoPath'] != null &&
                (m['compressedVideoPath'] as String).isNotEmpty
            ? File(m['compressedVideoPath'])
            : null,
        originalVideoBytes: (m['originalVideoBytes'] ?? 0) as int,
        compressedVideoBytes: (m['compressedVideoBytes'] ?? 0) as int,
        price: (m['price'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        draftId: (m['draftId'] ?? '') as String,
      );
}

class UploadTask {
  UploadTask({required this.id, required this.snapshot})
    : createdAt = DateTime.now(),
      phase = UploadPhase.preparing.obs,
      overallProgress = 0.0.obs,
      videoProgress = 0.0.obs,
      photosProgress = 0.0.obs,
      status = 'Preparing upload...'.obs,
      isCompleted = false.obs,
      isFailed = false.obs,
      isCancelled = false.obs,
      error = RxnString(),
      publishedPostId = RxnString(),
      failureType = Rx<UploadFailureType>(UploadFailureType.unknown),
      speedDisplay = '—'.obs,
      etaDisplay = '--:--'.obs;

  final String id;
  final DateTime createdAt;
  final PostUploadSnapshot snapshot;

  final Rx<UploadPhase> phase;
  final RxDouble overallProgress;
  final RxDouble videoProgress;
  final RxDouble photosProgress;
  final RxString status;
  final RxBool isCompleted;
  final RxBool isFailed;
  final RxBool isCancelled;
  final RxnString error;
  // Set when upload succeeds so UI can navigate to the new post details
  final RxnString publishedPostId;
  final Rx<UploadFailureType> failureType; // classification when failed
  // Smoothed speed and estimated remaining time (media phases)
  final RxString speedDisplay; // e.g. "1.2 MB/s" or '—'
  final RxString etaDisplay; // e.g. "00:34" or '--:--'
  // Media size metadata (populated when task starts)
  int videoBytes = 0;
  int photosBytes = 0;
  // Cached weights (assigned when pipeline starts) for continuous progress blending
  double weightCreate = 0;
  double weightMedia = 0;
  double weightFinalize = 0;
  // Byte accounting (new unified source of truth)
  int uploadedVideoBytes = 0;
  int uploadedPhotoBytes = 0;
  int get uploadedMediaBytes => uploadedVideoBytes + uploadedPhotoBytes;
  int get totalMediaBytes => videoBytes + photosBytes;
}

/// Manages a single active upload task (Phase 1). Future: queue/multiple.
class UploadManager extends GetxService {
  // Telemetry counters (in-memory only; reset on app restart)
  final RxInt retryCount = 0.obs;
  final RxInt discardCount = 0.obs;
  static UploadManager get to => Get.find<UploadManager>();

  final Rxn<UploadTask> currentTask = Rxn<UploadTask>();
  // Unified lock flag for UI to disable post / edit / delete draft actions
  final RxBool isLocked = false.obs;
  // Broadcast stream for external listeners to observe progress/state transitions.
  final StreamController<UploadProgressEvent> _progressCtrl =
      StreamController<UploadProgressEvent>.broadcast();
  Stream<UploadProgressEvent> get progressStream => _progressCtrl.stream;
  final _uuid = const Uuid();
  final _box = GetStorage();
  static const _persistKey = 'ACTIVE_UPLOAD_TASK_V1';
  final _notifications = FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;
  // Rolling speed samples (timestamp, uploadedBytes)
  final List<_SpeedSample> _speedSamples = [];

  bool get hasActive =>
      currentTask.value != null &&
      !(currentTask.value!.isCompleted.value ||
          currentTask.value!.isFailed.value ||
          currentTask.value!.isCancelled.value);

  // Convenience proxies for legacy UI bindings. Prefer accessing currentTask
  // directly for richer state (speed for active task only).
  RxString get speedDisplay => currentTask.value?.speedDisplay ?? '—'.obs;
  RxString get etaDisplay => currentTask.value?.etaDisplay ?? '--:--'.obs;

  Future<UploadManager> init() async {
    _recoverPersisted();
    await _initNotifications();
    return this;
  }

  Future<void> _initNotifications() async {
    if (_notificationsInitialized) return;
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (resp) {
          final payload = resp.payload;
          if (payload != null && payload.startsWith('post:')) {
            final id = payload.substring(5);
            if (id.isNotEmpty) {
              // Navigate if possible
              if (Get.isRegistered<PostController>()) {
                Get.toNamed('/post-details', arguments: id);
              }
            }
          }
        },
      );
      _notificationsInitialized = true;
    } catch (_) {
      // Silent; notifications are best-effort.
    }
  }

  Future<void> _showNotif({
    required String title,
    required String body,
    int id = 1001,
    String? payload,
  }) async {
    if (!_notificationsInitialized) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        'uploads',
        'Upload Status',
        channelDescription: 'Notifications about post upload status',
        importance: Importance.high,
        priority: Priority.high,
        showProgress: false,
      );
      const details = NotificationDetails(android: androidDetails);
      await _notifications.show(id, title, body, details, payload: payload);
    } catch (_) {}
  }

  Future<UploadTask> startFromController(
    PostController controller, {
    String draftId = '',
  }) async {
    if (hasActive) {
      throw StateError('An upload is already in progress');
    }
    // Copy image list locally to avoid mutation during async work
    final images = controller.selectedImages.toList();
    final photoBytesLengths = images.map((e) => e.lengthInBytes).toList();
    // Encode in parallel isolates (compute) to keep main thread responsive
    Future<String> encode(Uint8List bytes) async => base64Encode(bytes);
    final photoBase64 = await Future.wait(
      images.map((img) => compute(encode, img)),
    );
    final snap = PostUploadSnapshot(
      brandUuid: controller.selectedBrandUuid.value.isEmpty
          ? null
          : controller.selectedBrandUuid.value,
      modelUuid: controller.selectedModelUuid.value.isEmpty
          ? null
          : controller.selectedModelUuid.value,
      brandName: controller.selectedBrand.value,
      modelName: controller.selectedModel.value,
      photoBytesLengths: photoBytesLengths,
      photoBase64: photoBase64,
      hasVideo: controller.selectedVideo.value != null,
      videoFile: controller.selectedVideo.value,
      usedCompressedVideo: controller.usedCompressedVideo.value,
      compressedVideoFile: controller.compressedVideoFile.value,
      originalVideoBytes: controller.originalVideoBytes.value,
      compressedVideoBytes: controller.compressedVideoBytes.value,
      price: controller.price.text,
      description: controller.description.text,
      draftId: draftId,
    );
    final task = UploadTask(id: _uuid.v4(), snapshot: snap);
    // Populate media byte sizes early for speed/ETA calculations
    try {
      if (snap.videoFile != null && snap.videoFile!.existsSync()) {
        task.videoBytes = snap.videoFile!.lengthSync();
      } else if (snap.compressedVideoFile != null &&
          snap.compressedVideoFile!.existsSync()) {
        task.videoBytes = snap.compressedVideoFile!.lengthSync();
      }
    } catch (_) {}
    try {
      task.photosBytes = snap.photoBytesLengths.fold<int>(0, (a, b) => a + b);
    } catch (_) {}
    currentTask.value = task;
    _bindControllerMirrors(controller, task); // legacy UI mirror only (one-way)
    _persist(task);
    // Kick pipeline in microtask so caller can navigate immediately
    Future.microtask(() => _runWeightedPipeline(controller, task));
    return task;
  }

  void _bindControllerMirrors(PostController c, UploadTask t) {
    ever<double>(t.overallProgress, (v) => c.uploadProgress.value = v);
    ever<String>(t.status, (s) => c.uploadStatus.value = s);
    ever<double>(t.videoProgress, (v) => c.videoUploadProgress.value = v);
    ever<double>(t.photosProgress, (v) => c.photosUploadProgress.value = v);
    ever<bool>(t.isCompleted, (v) => c.isUploadComplete.value = v);
    ever<bool>(t.isFailed, (v) => c.isUploadFailed.value = v);
  }

  // Mirror controller media progress back into task and compute smoothed speed/ETA.
  // Throttled media progress binding to reduce speed/ETA recompute frequency
  // New byte delta ingress -> updates task progress & speed/ETA
  void _onMediaDelta(
    UploadTask t, {
    required int deltaBytes,
    required bool video,
  }) {
    if (deltaBytes <= 0) return;
    if (video) {
      t.uploadedVideoBytes += deltaBytes;
    } else {
      t.uploadedPhotoBytes += deltaBytes;
    }
    // Update granular progress fractions for UI timelines
    if (t.videoBytes > 0) {
      t.videoProgress.value = (t.uploadedVideoBytes / t.videoBytes).clamp(0, 1);
    }
    if (t.photosBytes > 0) {
      t.photosProgress.value = (t.uploadedPhotoBytes / t.photosBytes).clamp(
        0,
        1,
      );
    }
    // Overall: create weight already counted, add proportional media weight
    final total = t.totalMediaBytes;
    if (t.weightMedia > 0 && total > 0) {
      final mediaFrac = (t.uploadedMediaBytes / total).clamp(0.0, 1.0);
      final targetOverall = (t.weightCreate + (t.weightMedia * mediaFrac))
          .clamp(0.0, 0.999);
      if (targetOverall > t.overallProgress.value) {
        t.overallProgress.value = targetOverall;
      }
    }
    _recomputeSpeedEta(
      t,
    ); // reuse existing smoothing window (bytes derived via video/photo progress times sizes earlier -> we now convert directly)
    _emitMirror(t);
  }

  void _update(
    UploadTask t, {
    double? overall,
    double? video,
    double? photos,
    String? status,
    UploadPhase? phase,
  }) {
    if (overall != null) t.overallProgress.value = overall;
    if (video != null) t.videoProgress.value = video;
    if (photos != null) t.photosProgress.value = photos;
    if (status != null) t.status.value = status;
    if (phase != null) t.phase.value = phase;
    // Emit structured event
    _recomputeLock();
    _progressCtrl.add(
      UploadProgressEvent(
        taskId: t.id,
        phase: t.phase.value,
        overall: t.overallProgress.value,
        video: t.videoProgress.value,
        photos: t.photosProgress.value,
        status: t.status.value,
        isCompleted: t.isCompleted.value,
        isFailed: t.isFailed.value,
        isCancelled: t.isCancelled.value,
        error: t.error.value,
        failureType: t.failureType.value,
        isLocked: isLocked.value,
        speed: t.speedDisplay.value,
        eta: t.etaDisplay.value,
      ),
    );
  }

  void _emitMirror(UploadTask t) {
    // Emit progress event without changing status/phase
    _recomputeLock();
    _progressCtrl.add(
      UploadProgressEvent(
        taskId: t.id,
        phase: t.phase.value,
        overall: t.overallProgress.value,
        video: t.videoProgress.value,
        photos: t.photosProgress.value,
        status: t.status.value,
        isCompleted: t.isCompleted.value,
        isFailed: t.isFailed.value,
        isCancelled: t.isCancelled.value,
        error: t.error.value,
        failureType: t.failureType.value,
        isLocked: isLocked.value,
        speed: t.speedDisplay.value,
        eta: t.etaDisplay.value,
      ),
    );
  }

  // ---- Weighted Step Pipeline ----
  Future<void> _runWeightedPipeline(
    PostController controller,
    UploadTask task,
  ) async {
    // Dynamic weighting: create (fixed base), media (proportional to bytes), finalize (fixed tail)
    const baseCreate = 0.12;
    const baseFinalize = 0.10;
    // Compute media bytes (video + photos)
    int videoBytes = 0;
    try {
      if (task.snapshot.videoFile != null &&
          task.snapshot.videoFile!.existsSync()) {
        videoBytes = task.snapshot.videoFile!.lengthSync();
      } else if (task.snapshot.compressedVideoFile != null &&
          task.snapshot.compressedVideoFile!.existsSync()) {
        videoBytes = task.snapshot.compressedVideoFile!.lengthSync();
      }
    } catch (_) {}
    int photosBytes = 0;
    try {
      photosBytes = task.snapshot.photoBytesLengths.fold<int>(
        0,
        (a, b) => a + b,
      );
    } catch (_) {}
    final totalMediaBytes = (videoBytes + photosBytes).clamp(0, 1 << 62);
    double mediaWeight;
    if (totalMediaBytes == 0) {
      // No media -> redistribute to create/finalize proportionally
      mediaWeight = 0.0;
    } else {
      // Allocate remaining after base weights
      final remaining = 1.0 - (baseCreate + baseFinalize);
      mediaWeight = remaining; // all remaining goes to media for now
    }
    // Normalize in case of edge cases
    final totalCheck = baseCreate + baseFinalize + mediaWeight;
    final normFactor = totalCheck == 0 ? 1.0 : (1.0 / totalCheck);
    final wCreate = (baseCreate * normFactor).clamp(0.0, 1.0);
    final wFinalize = (baseFinalize * normFactor).clamp(0.0, 1.0);
    final wMedia = (mediaWeight * normFactor).clamp(0.0, 1.0);

    final steps = <_PipelineStep>[
      _PipelineStep(
        name: 'create',
        weight: wCreate,
        phase: UploadPhase.preparing,
        run: () async {
          final id = await controller.postDetails();
          if (id == null) throw Exception('Failed to create post');
          task.publishedPostId.value = id;
        },
        retry: 2,
      ),
      if (wMedia > 0)
        _PipelineStep(
          name: 'media',
          weight: wMedia,
          phase: UploadPhase.uploadingPhotos,
          run: () async {
            if (task.publishedPostId.value == null) {
              throw Exception('Missing post id for media upload');
            }
            // Sequential enforcement: video first (if any), then photos one by one updating status
            final postId = task.publishedPostId.value!;
            // Video
            final snap = task.snapshot;
            if (snap.hasVideo &&
                (snap.compressedVideoFile?.existsSync() == true ||
                    snap.videoFile?.existsSync() == true)) {
              // Mark explicit phase for UI timeline
              task.phase.value = UploadPhase.uploadingVideo;
              task.status.value = 'Uploading video…'.tr;
              _emitMirror(task);
              final videoOk = await _runWithNetworkWait(
                controller,
                task,
                () => controller.uploadSingleVideo(
                  postId,
                  snap,
                  onBytes: (delta) =>
                      _onMediaDelta(task, deltaBytes: delta, video: true),
                ),
              );
              if (!videoOk) {
                throw Exception(
                  controller.uploadError.value.isEmpty
                      ? 'Video upload failed'
                      : controller.uploadError.value,
                );
              }
            }
            // Photos sequential
            final totalPhotos = snap.photoBase64.length;
            for (var i = 0; i < totalPhotos; i++) {
              // Switch phase only once (first photo) if we had video or starting photos
              if (task.phase.value != UploadPhase.uploadingPhotos) {
                task.phase.value = UploadPhase.uploadingPhotos;
              }
              task.status.value = 'Uploading photo @current of @total…'
                  .trParams({'current': '${i + 1}', 'total': '$totalPhotos'});
              _emitMirror(task);
              final ok = await _runWithNetworkWait(
                controller,
                task,
                () => controller.uploadSinglePhoto(
                  postId,
                  snap,
                  i,
                  onBytes: (delta) =>
                      _onMediaDelta(task, deltaBytes: delta, video: false),
                ),
              );
              if (!ok) {
                throw Exception(
                  controller.uploadError.value.isEmpty
                      ? 'Photo upload failed'
                      : controller.uploadError.value,
                );
              }
            }
            if (controller.isUploadCancelled.value) {
              throw _Cancelled();
            }
          },
          retry: 2,
        ),
      _PipelineStep(
        name: 'finalize',
        weight: wFinalize,
        phase: UploadPhase.finalizing,
        run: () async {
          await controller.fetchMyPosts();
        },
        retry: 1,
      ),
    ];

    // Store weights on task for continuous overall calculation during media phase
    task.weightCreate = wCreate;
    task.weightMedia = wMedia;
    task.weightFinalize = wFinalize;

    double progressed = 0.0;
    for (final step in steps) {
      _update(
        task,
        status: _statusForStep(step),
        phase: step.phase,
        overall: progressed,
      );
      final success = await _executeWithRetries(step, controller, task);
      if (!success) {
        _handleFailure(task);
        return;
      }
      progressed += step.weight;
      // If this was the media step, progressed might already be close to end of weight window via dynamic updates
      if (step.name == 'media') {
        // Ensure we at least reach start + weight (avoid being below due to rounding) but don't overshoot 1.0
        if (task.overallProgress.value < progressed) {
          task.overallProgress.value = progressed.clamp(0.0, 0.999);
        }
      } else {
        _update(task, overall: progressed);
      }
    }
    // Clamp to 1.0 and mark complete
    _update(
      task,
      overall: 1.0,
  status: 'common_success'.tr,
      phase: UploadPhase.complete,
    );
    _handleSuccess(controller, task);
  }

  String _statusForStep(_PipelineStep s) {
    switch (s.name) {
      case 'create':
        return 'Creating post…';
      case 'media':
        return 'Preparing media…'
            .tr; // refined: real-time status set during loop
      case 'finalize':
        return 'Finalizing…';
      default:
        return 'Working…';
    }
  }

  Future<bool> _executeWithRetries(
    _PipelineStep step,
    PostController controller,
    UploadTask task,
  ) async {
    int attempt = 0;
    final maxAttempts = step.retry + 1;
    while (attempt < maxAttempts) {
      try {
        await step.run();
        return true;
      } on _Cancelled {
        task.isCancelled.value = true;
  _update(task, status: 'post_upload_cancelled_hint'.tr, phase: UploadPhase.cancelled);
        _clearPersisted();
        return false;
      } catch (e) {
        attempt++;
        task.error.value = e.toString();
        if (attempt >= maxAttempts) {
          return false;
        }
        // Exponential backoff: 500ms * 2^(attempt-1)
        final delayMs = 500 * (1 << (attempt - 1));
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    return false;
  }

  Future<void> cancelActive(PostController controller) async {
    final task = currentTask.value;
    if (task == null) return;
    await controller.cancelOngoingUpload();
    task.isCancelled.value = true;
    task.isFailed.value = true; // treat as retry-able terminal state
    task.failureType.value = UploadFailureType.cancelled;
    task.status.value = 'Cancelled (needs retry)';
    task.error.value = 'User cancelled';
    _persist(task); // keep snapshot so user can retry or discard later
    _update(task, status: 'post_upload_cancelled_hint'.tr, phase: UploadPhase.cancelled);
    _showNotif(
      title: 'post_upload_cancelled_hint'.tr,
      body: 'post_upload_cancelled_hint'.tr,
    );
    // Do NOT auto-clear; user must decide (aligns with failed logic)
    _maybeCleanupMedia(task, success: false);
  }

  void _handleSuccess(PostController controller, UploadTask task) {
    task.isCompleted.value = true;
    _clearPersisted();
    _showNotif(
      title: 'post_upload_success_title'.tr,
      body: 'post_upload_success_body'.tr,
      payload: task.publishedPostId.value != null
          ? 'post:${task.publishedPostId.value}'
          : null,
    );
    _scheduleAutoClear();
    _maybeCleanupMedia(task, success: true);
    // Draft cleanup removed (multi-draft feature deprecated).
    // Delayed form reset so user briefly sees success state; skip if task cleared early
    try {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (task.isCompleted.value && Get.isRegistered<PostController>()) {
          try {
            controller.reset();
          } catch (_) {}
        }
      });
    } catch (_) {}
  }

  void _handleFailure(UploadTask task) {
    task.isFailed.value = true;
    // Classify error
    task.failureType.value = _classifyFailure(task.error.value);
    _persist(task); // keep snapshot so user can retry
  _showNotif(title: 'common_error'.tr, body: _friendlyError(task)); // body already user-friendly, could map to keys
    // Do NOT auto-clear; user decides retry/discard
  }

  // Wrap an async media upload operation to wait for network connectivity if lost.
  // Returns the underlying function's boolean result. If offline persists beyond
  // a generous timeout (e.g., 5 minutes), we surface failure so user can retry.
  Future<bool> _runWithNetworkWait(
    PostController controller,
    UploadTask task,
    Future<bool> Function() action,
  ) async {
    // Fast path: try once immediately
    if (!Get.isRegistered<ConnectionController>()) {
      return await action();
    }
    final conn = Get.find<ConnectionController>();
    const maxOffline = Duration(minutes: 5);
    final offlineStart = DateTime.now();
    while (true) {
      if (controller.isUploadCancelled.value) return false;
      if (conn.hasConnection.value) {
        // Attempt action
        return await action();
      }
      // Show waiting status (preserve phase but annotate)
      final base = task.status.value.split(' • ').first;
      task.status.value = '$base • Waiting for network…';
      _emitMirror(task);
      if (DateTime.now().difference(offlineStart) > maxOffline) {
        task.error.value = 'Network unavailable for too long';
        return false;
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  UploadFailureType _classifyFailure(String? message) {
    if (message == null || message.isEmpty) return UploadFailureType.unknown;
    final m = message.toLowerCase();
    if (m.contains('cancel')) return UploadFailureType.cancelled;
    if (m.contains('socket') ||
        m.contains('timeout') ||
        m.contains('network') ||
        m.contains('failed host') ||
        m.contains('connection')) {
      return UploadFailureType.network;
    }
    if (m.contains('validation') ||
        m.contains('required') ||
        m.contains('invalid') ||
        m.contains('missing')) {
      return UploadFailureType.validation;
    }
    return UploadFailureType.unknown;
  }

  String _friendlyError(UploadTask task) {
    switch (task.failureType.value) {
      case UploadFailureType.network:
        return 'Network issue. Please check connection and retry.';
      case UploadFailureType.validation:
        return 'Some required data was invalid or missing.';
      case UploadFailureType.cancelled:
        return 'Upload was cancelled.';
      case UploadFailureType.unknown:
        return task.error.value ?? 'Unknown error';
    }
  }

  void clearIfTerminal() {
    final t = currentTask.value;
    if (t == null) return;
    if (t.isCompleted.value || t.isFailed.value || t.isCancelled.value) {
      currentTask.value = null;
      _progressCtrl.add(
        UploadProgressEvent(
          taskId: t.id,
          phase: t.phase.value,
          overall: t.overallProgress.value,
          video: t.videoProgress.value,
          photos: t.photosProgress.value,
          status: t.status.value,
          isCompleted: t.isCompleted.value,
          isFailed: t.isFailed.value,
          isCancelled: t.isCancelled.value,
          error: t.error.value,
          terminal: true,
          failureType: t.failureType.value,
          isLocked: false,
          speed: t.speedDisplay.value,
          eta: t.etaDisplay.value,
        ),
      );
      _recomputeLock();
    }
  }

  @override
  void onClose() {
    try {
      _progressCtrl.close();
    } catch (_) {}
    super.onClose();
  }

  /// Discard a failed or cancelled (but not completed) task.
  void discardTerminal() {
    final t = currentTask.value;
    if (t == null) return;
    if ((t.isFailed.value || t.isCancelled.value) && !t.isCompleted.value) {
      discardCount.value++;
      // ignore: avoid_print
      print(
        '[UploadManager] discardCount=${discardCount.value} retryCount=${retryCount.value}',
      );
      _clearPersisted();
      currentTask.value = null;
      _recomputeLock();
    }
  }

  void _recomputeLock() {
    final t = currentTask.value;
    if (t == null) {
      isLocked.value = false;
      return;
    }
    // Locked while task exists and not successfully completed & cleared
    isLocked.value = !t
        .isCompleted
        .value; // failure/cancelled keep lock until discarded or retried to success
  }

  // -------- Auto clear & media cleanup --------
  void _scheduleAutoClear({bool failed = false}) {
    // Give UI 2.5s to show final state; if failed we keep task for retry (do not clear automatically)
    if (failed) return; // user decides when to retry; tile persists
    Future.delayed(const Duration(milliseconds: 2500), () {
      clearIfTerminal();
    });
  }

  void _maybeCleanupMedia(UploadTask task, {required bool success}) {
    try {
      // If a compressed video exists and was not actually used, delete it to free disk
      if (task.snapshot.compressedVideoFile != null &&
          task.snapshot.compressedVideoFile!.existsSync()) {
        // Heuristic: remove if success and compressed not used OR file older than 1 day
        final f = task.snapshot.compressedVideoFile!;
        final age = DateTime.now().difference(f.lastModifiedSync());
        final shouldDelete =
            (success && !task.snapshot.usedCompressedVideo) || age.inHours > 24;
        if (shouldDelete) {
          try {
            f.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  // ---------------- Persistence -----------------
  void _persist(UploadTask task) {
    try {
      final map = {
        'id': task.id,
        'createdAt': task.createdAt.toIso8601String(),
        'snapshot': task.snapshot.toMap(),
        'phase': task.phase.value.index,
        'overall': task.overallProgress.value,
        'video': task.videoProgress.value,
        'photos': task.photosProgress.value,
        'status': task.status.value,
        'isCompleted': task.isCompleted.value,
        'isFailed': task.isFailed.value,
        'isCancelled': task.isCancelled.value,
        'error': task.error.value,
        'failureType': task.failureType.value.index,
      };
      _box.write(_persistKey, map);
    } catch (_) {}
  }

  void _clearPersisted() {
    _box.remove(_persistKey);
  }

  void _recoverPersisted() {
    try {
      final raw = _box.read(_persistKey);
      if (raw is Map) {
        final snapRaw = raw['snapshot'];
        if (snapRaw is Map) {
          final snap = PostUploadSnapshot.fromMap(
            Map<String, dynamic>.from(snapRaw),
          );
          final task = UploadTask(id: raw['id'] ?? _uuid.v4(), snapshot: snap);
          currentTask.value = task;
          // Mark as failed needing retry (cannot resume mid-flight)
          task.isFailed.value = true;
          task.error.value = 'App restarted. Tap to retry.';
          task.status.value = 'Needs retry';
          task.phase.value = UploadPhase.failed;
          final ftIndex = raw['failureType'];
          if (ftIndex is int &&
              ftIndex >= 0 &&
              ftIndex < UploadFailureType.values.length) {
            task.failureType.value = UploadFailureType.values[ftIndex];
          }
        }
      }
    } catch (_) {}
  }

  // --------------- Retry -----------------
  Future<void> retryActive(PostController controller) async {
    final task = currentTask.value;
    if (task == null) return;
    if (!task.isFailed.value) return; // only failed tasks retried

    // Hydrate controller form/media if empty (best-effort)
    _hydrateController(controller, task.snapshot);
    // Reset task flags
    task.isFailed.value = false;
    task.error.value = null;
    task.isCancelled.value = false;
    task.isCompleted.value = false;
    // Telemetry: count retries
    retryCount.value++;
    // ignore: avoid_print
    print(
      '[UploadManager] retryCount=${retryCount.value} discardCount=${discardCount.value}',
    );
    _update(
      task,
      overall: 0,
      video: 0,
      photos: 0,
      status: 'Preparing upload...',
      phase: UploadPhase.preparing,
    );
    _persist(task);
    _runWeightedPipeline(controller, task);
  }

  void _hydrateController(PostController c, PostUploadSnapshot snap) {
    // Only populate if controller has no images loaded (avoid overwriting user edits)
    if (c.selectedImages.isEmpty && snap.photoBase64.isNotEmpty) {
      try {
        c.selectedImages.assignAll(
          snap.photoBase64.map((b64) {
            try {
              return base64Decode(b64);
            } catch (_) {
              return Uint8List(0); // fallback empty
            }
          }).toList(),
        );
      } catch (_) {}
    }
    if (c.selectedVideo.value == null &&
        snap.videoFile != null &&
        snap.videoFile!.existsSync()) {
      c.selectedVideo.value = snap.videoFile;
      c.usedCompressedVideo.value = snap.usedCompressedVideo;
      if (snap.usedCompressedVideo &&
          snap.compressedVideoFile != null &&
          snap.compressedVideoFile!.existsSync()) {
        c.compressedVideoFile.value = snap.compressedVideoFile;
      }
    }
    if (c.selectedBrandUuid.value.isEmpty && snap.brandUuid != null) {
      c.selectedBrandUuid.value = snap.brandUuid!;
      c.selectedBrand.value = snap.brandName;
    }
    if (c.selectedModelUuid.value.isEmpty && snap.modelUuid != null) {
      c.selectedModelUuid.value = snap.modelUuid!;
      c.selectedModel.value = snap.modelName;
    }
    if (c.price.text.isEmpty) c.price.text = snap.price;
    if (c.description.text.isEmpty) c.description.text = snap.description;
  }

  // ---- Experimental Callback-based API (non-breaking scaffold) ----
  // Future direction: decouple controller internals by providing a structured
  // upload pipeline with callbacks. This keeps current behavior but allows
  // migration by gradually moving logic from PostController into discrete
  // steps supplied here.
  //
  // Example target usage (future):
  //   manager.enqueueUpload(
  //     buildSnapshot: () => PostUploadSnapshot(...),
  //     steps: [
  //       UploadStep('createPost', (ctx) async { /* returns postId */ }),
  //       UploadStep('uploadVideo', (ctx) async { }),
  //       UploadStep('uploadPhotos', (ctx) async { }),
  //       UploadStep('finalize', (ctx) async { }),
  //     ],
  //     onProgress: (overall, phase, status) { ... },
  //     onSuccess: (postId) { ... },
  //     onFailure: (error) { ... },
  //   );
  //
  // Below we define minimal data structures; execution engine not yet wired.

  /// Placeholder for future scheduling of a pipeline-based upload.
  Future<void> enqueueUpload({
    required PostUploadSnapshot Function() buildSnapshot,
    required List<UploadStep> steps,
    void Function(double overall, String status)? onProgress,
    void Function(String postId)? onSuccess,
    void Function(Object error, StackTrace st)? onFailure,
  }) async {
    throw UnimplementedError(
      'enqueueUpload experimental API not yet implemented',
    );
  }
}

class UploadProgressEvent {
  final String taskId;
  final UploadPhase phase;
  final double overall;
  final double video;
  final double photos;
  final String status;
  final bool isCompleted;
  final bool isFailed;
  final bool isCancelled;
  final String? error;
  final bool terminal;
  final UploadFailureType? failureType;
  final bool? isLocked;
  final String? speed; // formatted speed string or null
  final String? eta; // formatted ETA or null
  UploadProgressEvent({
    required this.taskId,
    required this.phase,
    required this.overall,
    required this.video,
    required this.photos,
    required this.status,
    required this.isCompleted,
    required this.isFailed,
    required this.isCancelled,
    this.error,
    this.terminal = false,
    this.failureType,
    this.isLocked,
    this.speed,
    this.eta,
  });
}

class _SpeedSample {
  final int timestampMs; // epoch ms
  final int bytes;
  _SpeedSample(this.timestampMs, this.bytes);
}

// ---- Speed / ETA computation ----
extension _SpeedExtensions on UploadManager {
  static const _windowMs = 3000; // 3s smoothing window

  void _recomputeSpeedEta(UploadTask t) {
    final total = t.videoBytes + t.photosBytes;
    if (total <= 0) return; // nothing to compute
    final uploaded =
        (t.videoProgress.value * t.videoBytes +
                t.photosProgress.value * t.photosBytes)
            .round();
    final now = DateTime.now().millisecondsSinceEpoch;
    _speedSamples.add(_SpeedSample(now, uploaded));
    // Drop old samples
    while (_speedSamples.isNotEmpty &&
        now - _speedSamples.first.timestampMs > _windowMs) {
      _speedSamples.removeAt(0);
    }
    if (_speedSamples.length < 2) {
      t.speedDisplay.value = '—';
      t.etaDisplay.value = '--:--';
      return;
    }
    final first = _speedSamples.first;
    final last = _speedSamples.last;
    final dtMs = (last.timestampMs - first.timestampMs).clamp(1, _windowMs);
    if (dtMs < 800) {
      // wait at least 0.8s for stability
      t.speedDisplay.value = '—';
      t.etaDisplay.value = '--:--';
      return;
    }
    final deltaBytes = (last.bytes - first.bytes).clamp(0, total);
    final speedBps = deltaBytes * 1000 / dtMs; // bytes per second
    t.speedDisplay.value = _formatSpeed(speedBps);
    final remaining = (total - uploaded).clamp(0, total);
    if (speedBps > 1) {
      final etaSec = (remaining / speedBps).round();
      t.etaDisplay.value = _formatEta(etaSec);
    } else {
      t.etaDisplay.value = '--:--';
    }
  }

  String _formatSpeed(double bps) {
    if (bps <= 0) return '—';
    const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    double v = bps;
    int i = 0;
    while (v > 900 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    final decimals = v < 10 ? 2 : (v < 100 ? 1 : 0);
    return '${v.toStringAsFixed(decimals)} ${units[i]}';
  }

  String _formatEta(int sec) {
    if (sec < 0 || sec > 24 * 3600) return '--:--';
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m > 99) {
      final h = m ~/ 60;
      final rm = m % 60;
      return '${h.toString().padLeft(1, '0')}:${rm.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// Internal pipeline step abstraction
class _PipelineStep {
  final String name;
  final double weight;
  final UploadPhase phase;
  final Future<void> Function() run;
  final int retry; // number of retries after first attempt
  _PipelineStep({
    required this.name,
    required this.weight,
    required this.phase,
    required this.run,
    this.retry = 0,
  });
}

class _Cancelled implements Exception {}

/// Represents a discrete upload phase for future pipeline refactor.
class UploadStep {
  final String name;
  final Future<void> Function(UploadContext ctx) run;
  const UploadStep(this.name, this.run);
}

/// Mutable context passed across upload steps for shared data (e.g. postId).
class UploadContext {
  String? postId;
  int completedBytes = 0;
  int totalBytes = 0;
  final Map<String, dynamic> extras = {};
}
