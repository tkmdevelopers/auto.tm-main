import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_tm/data/datasources/local/local_storage.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'upload_manager.dart';

/// Dedicated service for persisting and recovering upload tasks across app restarts.
class UploadPersistenceService extends GetxService {
  final LocalStorage _storage;
  final Uuid _uuid = const Uuid();

  static const String _persistKey = 'ACTIVE_UPLOAD_TASK_V1';

  UploadPersistenceService({LocalStorage? storage})
    : _storage = storage ?? GetStorageImpl();

  // ═══════════════════════════════════════════════════════════════════════════
  // Persistence Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Persist task state to local storage for crash recovery
  void persistTask(UploadTask task) {
    try {
      final map = {
        'id': task.id,
        'snapshot': task.snapshot.toMap(),
        'createdAt': task.createdAt.toIso8601String(),
        'phase': task.phase.value.index,
        'overallProgress': task.overallProgress.value,
        'status': task.status.value,
        'isCompleted': task.isCompleted.value,
        'isFailed': task.isFailed.value,
        'isCancelled': task.isCancelled.value,
        'error': task.error.value,
        'failureType': task.failureType.value.index,
      };
      _storage.write(_persistKey, map);
    } catch (e) {
      // Persist failure should not crash the app
      Get.log('[UploadPersistence] Failed to persist task: $e');
    }
  }

  /// Clear persisted task from storage
  void clearTask() {
    try {
      _storage.remove(_persistKey);
    } catch (e) {
      Get.log('[UploadPersistence] Failed to clear task: $e');
    }
  }

  /// Recover task from storage after app restart, returns null if no task persisted
  UploadTask? recoverTask() {
    try {
      final raw = _storage.read(_persistKey);
      if (raw is Map) {
        final snapRaw = raw['snapshot'];
        if (snapRaw is Map) {
          final snap = PostUploadSnapshot.fromMap(
            Map<String, dynamic>.from(snapRaw),
          );
          final task = UploadTask(id: raw['id'] ?? _uuid.v4(), snapshot: snap);

          // Mark as failed needing retry (cannot resume mid-flight upload)
          task.isFailed.value = true;
          task.error.value = 'App restarted. Tap to retry.';
          task.status.value = 'Needs retry';
          task.phase.value = UploadPhase.failed;

          // Restore failure type if valid
          final ftIndex = raw['failureType'];
          if (ftIndex is int &&
              ftIndex >= 0 &&
              ftIndex < UploadFailureType.values.length) {
            task.failureType.value = UploadFailureType.values[ftIndex];
          }

          Get.log(
            '[UploadPersistence] Recovered task ${task.id} from previous session',
          );
          return task;
        }
      }
    } catch (e) {
      Get.log('[UploadPersistence] Failed to recover task: $e');
    }
    return null;
  }

  /// Check if there's a persisted task in storage
  bool hasPersistedTask() {
    try {
      final raw = _storage.read(_persistKey);
      return raw != null && raw is Map && raw.containsKey('snapshot');
    } catch (_) {
      return false;
    }
  }

  /// Get persisted snapshot data (for debugging/inspection)
  PostUploadSnapshot? getPersistedSnapshot() {
    try {
      final raw = _storage.read(_persistKey);
      if (raw is Map) {
        final snapRaw = raw['snapshot'];
        if (snapRaw is Map) {
          return PostUploadSnapshot.fromMap(Map<String, dynamic>.from(snapRaw));
        }
      }
    } catch (_) {}
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Controller Hydration Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Hydrate images from snapshot base64 data
  List<Uint8List> hydrateImages(PostUploadSnapshot snap) {
    final images = <Uint8List>[];
    for (final b64 in snap.photoBase64) {
      try {
        images.add(base64Decode(b64));
      } catch (_) {
        // Skip corrupted base64 data
      }
    }
    return images;
  }

  /// Check if snapshot has valid video file on disk
  bool hasValidVideoFile(PostUploadSnapshot snap) {
    if (snap.hasVideo) {
      final file = snap.usedCompressedVideo && snap.compressedVideoFile != null
          ? snap.compressedVideoFile
          : snap.videoFile;
      return file != null && file.existsSync();
    }
    return false;
  }
}
