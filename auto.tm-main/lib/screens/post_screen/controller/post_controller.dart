// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:auto_tm/utils/navigation_utils.dart';

import 'package:auto_tm/utils/key.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auto_tm/screens/profile_screen/controller/profile_controller.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:get_storage/get_storage.dart';
import 'package:auto_tm/services/post_service.dart';
import 'package:auto_tm/services/brand_model_service.dart';
import 'phone_verification_controller.dart';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'upload_manager.dart';
import 'package:auto_tm/models/post_dtos.dart';
export 'package:auto_tm/models/post_dtos.dart';

/// Lightweight image signature for dirty tracking
class _ImageSig {
  final int length;
  final int hash;

  _ImageSig(Uint8List data)
    : length = data.lengthInBytes,
      hash = _compute(data);

  static int _compute(Uint8List data) {
    if (data.isEmpty) return 0;
    final limit = data.length < 64 ? data.length : 64;
    int h = 0;
    for (var i = 0; i < limit; i++) {
      h = (h * 31 + data[i]) & 0xFFFFFFFF;
    }
    return h;
  }
}

/// Post form controller managing media, form state, upload coordination with UploadManager
class PostController extends GetxController {
  final box = GetStorage();

  // Form fields
  final TextEditingController price = TextEditingController();
  final TextEditingController enginePower = TextEditingController();
  final TextEditingController milleage = TextEditingController();
  final TextEditingController vinCode = TextEditingController();
  final TextEditingController description = TextEditingController();

  // Phone verification - delegated to PhoneVerificationController
  late final PhoneVerificationController _phoneCtrl;
  TextEditingController get phoneController => _phoneCtrl.phoneController;
  TextEditingController get otpController => _phoneCtrl.otpController;
  FocusNode get otpFocus => _phoneCtrl.otpFocus;
  RxBool get isOriginalPhone => _phoneCtrl.isOriginalPhone;
  RxBool get isPhoneVerified => _phoneCtrl.isPhoneVerified;
  RxBool get isLoadingOtp => _phoneCtrl.isLoadingOtp;
  RxInt get resendCountdown => _phoneCtrl.resendCountdown;
  RxBool get canResend => _phoneCtrl.canResend;
  RxBool get needsOtp => _phoneCtrl.needsOtp;
  RxBool get showOtpField => _phoneCtrl.showOtpField;
  RxBool get isSendingOtp => _phoneCtrl.isSendingOtp;
  RxInt get countdown => _phoneCtrl.countdown;

  // Form selections
  final RxString selectedBrandUuid = ''.obs;
  final RxString selectedModelUuid = ''.obs;
  final RxString selectedBrand = ''.obs;
  final RxString selectedModel = ''.obs;
  final RxString selectedCondition = ''.obs;
  final RxString selectedTransmission = ''.obs;
  final RxString selectedEngineType = ''.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxString selectedCurrency = 'TMT'.obs;
  final RxString selectedLocation = ''.obs;
  final RxBool credit = false.obs;
  final RxBool exchange = false.obs;

  // Media state
  final RxList<Uint8List> selectedImages = <Uint8List>[].obs;
  final Rxn<File> selectedVideo = Rxn<File>();
  final Rxn<File> compressedVideoFile = Rxn<File>();
  final RxInt originalVideoBytes = 0.obs;
  final RxInt compressedVideoBytes = 0.obs;
  final RxBool usedCompressedVideo = false.obs;
  final Rxn<Uint8List> videoThumbnail = Rxn<Uint8List>();
  final RxBool isVideoInitialized = false.obs;
  final RxBool isCompressingVideo = false.obs;
  final RxDouble videoCompressionProgress = 0.0.obs;
  VideoPlayerController? videoPlayerController;
  var _videoCompressSub;

  // Image signature cache for dirty tracking
  List<_ImageSig> _imageSigCache = [];

  // Upload state mirrors (legacy support for existing UI)
  final RxBool isPosting = false.obs;
  final RxBool isLoading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxString uploadStatus = 'post_upload_ready'.tr.obs;
  final RxString uploadError = ''.obs;
  final RxBool isUploadComplete = false.obs;
  final RxBool isUploadFailed = false.obs;
  final RxBool isUploadCancelled = false.obs;
  final RxBool isCancellingUpload = false.obs;
  final RxBool canRetry = false.obs;
  final RxDouble videoUploadProgress = 0.0.obs;
  final RxDouble photosUploadProgress = 0.0.obs;

  // Internal upload tracking
  final RxInt _videoSentBytes = 0.obs;
  final RxInt _photosSentBytes = 0.obs;
  final RxInt _totalBytesSent = 0.obs;
  final RxInt _videoTotalBytes = 0.obs;
  final RxInt _photosTotalBytes = 0.obs;
  dio.CancelToken? _activeCancelToken;
  String? _activePostUuid;

  // Brand/model data – delegated to BrandModelService
  late final BrandModelService _brandModelSvc;
  RxList<BrandDto> get brands => _brandModelSvc.brands;
  RxList<ModelDto> get models => _brandModelSvc.models;
  RxInt get modelNameResolutionTick => _brandModelSvc.modelNameResolutionTick;
  RxBool get isLoadingB => _brandModelSvc.isLoadingBrands;
  RxBool get isLoadingM => _brandModelSvc.isLoadingModels;
  RxBool get brandsFromCache => _brandModelSvc.brandsFromCache;
  RxBool get modelsFromCache => _brandModelSvc.modelsFromCache;
  RxString get brandSearchQuery => _brandModelSvc.brandSearchQuery;
  RxString get searchModel => _brandModelSvc.modelSearchQuery;

  // Form persistence and dirty tracking
  final RxBool isFormSaved = false.obs;
  final RxBool hydratedFromStorage = false.obs;
  final RxBool isDirty = false.obs;
  String? _lastSavedSignature;
  StreamSubscription? _uploadProgressSub; // listens for terminal upload state

  // Permission state
  final RxBool isGalleryPermissionGranted = false.obs;

  // Additional UI state properties
  final RxString selectedYear = ''.obs;
  // Posts management
  final RxList<PostDto> posts = <PostDto>[].obs;
  final RxBool isLoadingP = false.obs;
  final RxBool showShimmer = false.obs;
  Timer? _shimmerDelayTimer;

  // Computed getters for filtered lists – delegated to BrandModelService
  List<BrandDto> get filteredBrands => _brandModelSvc.filteredBrands;
  List<ModelDto> get filteredModels => _brandModelSvc.filteredModels;

  @override
  void onInit() {
    super.onInit();
    // Initialize phone verification controller
    _phoneCtrl = Get.put(PhoneVerificationController());
    _phoneCtrl.onFieldChanged = markFieldChanged;
    // Initialize brand/model service
    _brandModelSvc = BrandModelService.to;
    _loadSavedForm();
    _rebuildImageSigCache();
    recoverOrCleanupStaleUpload();
    _attachUploadLifecycleListener();
  }

  @override
  void onClose() {
    _shimmerDelayTimer?.cancel();
    try {
      _uploadProgressSub?.cancel();
    } catch (_) {}

    // Attempt to tidy compressed artifacts if not actively uploading or compressing
    bool hasActiveUpload = false;
    try {
      if (Get.isRegistered<UploadManager>()) {
        hasActiveUpload = Get.find<UploadManager>().hasActive;
      }
    } catch (_) {}

    if (!isPosting.value && !isCompressingVideo.value && !hasActiveUpload) {
      try {
        final f = compressedVideoFile.value;
        if (f != null && f.existsSync()) {
          f.deleteSync();
        }
      } catch (_) {}
      try {
        VideoCompress.deleteAllCache();
      } catch (_) {}
    }
    super.onClose();
  }

  /// Computed property for minimum data check
  bool get hasMinimumData =>
      selectedBrand.value.isNotEmpty &&
      selectedModel.value.isNotEmpty &&
      price.text.trim().isNotEmpty &&
      selectedLocation.value.isNotEmpty &&
      (selectedImages.isNotEmpty || selectedVideo.value != null);

  /// True if user entered any piece of data (even if not enough to post yet)
  bool get hasAnyInput {
    return selectedBrand.value.isNotEmpty ||
        selectedModel.value.isNotEmpty ||
        price.text.trim().isNotEmpty ||
        selectedLocation.value.isNotEmpty ||
        selectedCondition.value.isNotEmpty ||
        selectedTransmission.value.isNotEmpty ||
        selectedEngineType.value.isNotEmpty ||
        selectedYear.value.isNotEmpty ||
        enginePower.text.trim().isNotEmpty ||
        milleage.text.trim().isNotEmpty ||
        vinCode.text.trim().isNotEmpty ||
        description.text.trim().isNotEmpty ||
        _phoneCtrl.hasModifiedPhone ||
        selectedImages.isNotEmpty ||
        selectedVideo.value != null;
  }

  Future<void> startManagedUpload() async {
    if (isPosting.value) return;

    final manager = Get.find<UploadManager>();
    final active = manager.currentTask.value;

    if (manager.hasActive) {
      if (active != null &&
          active.isFailed.value &&
          !active.isCancelled.value &&
          !active.isCompleted.value) {
        _showFailedTaskDialog(manager, active);
      } else {
        if (Get.key.currentState?.canPop() ?? false) {
          NavigationUtils.closeGlobal();
        }
      }
      return;
    }

    if (active != null && active.isFailed.value && !active.isCompleted.value) {
      _showFailedTaskDialog(manager, active);
      return;
    }

    // Mark posting BEFORE closing screen so onClose() doesn't remove compressed video
    isPosting.value = true;
    if (Get.key.currentState?.canPop() ?? false) {
      NavigationUtils.closeGlobal();
    }

    try {
      await manager.startFromController(this, draftId: '');
    } catch (e) {
      Get.snackbar(
        'common_error'.tr,
        'post_upload_start_error'.trParams({'error': e.toString()}),
      );
      isPosting.value = false;
    }
  }

  void _showFailedTaskDialog(UploadManager manager, dynamic task) {
    Get.dialog(
      AlertDialog(
        title: Text('post_upload_prev_failed_title'.tr),
        content: Text('post_upload_prev_failed_body'.tr),
        actions: [
          TextButton(
            onPressed: () {
              NavigationUtils.closeGlobal();
              manager.retryActive(this);
            },
            child: Text('post_retry'.tr),
          ),
          TextButton(
            onPressed: () {
              manager.discardTerminal();
              NavigationUtils.closeGlobal();
            },
            child: Text('post_discard'.tr),
          ),
          TextButton(
            onPressed: () => NavigationUtils.closeGlobal(),
            child: Text('post_cancel'.tr),
          ),
        ],
      ),
    );
  }

  /// Create post details - called by UploadManager
  Future<String?> postDetails() async {
    if (!isPhoneVerified.value) {
      Get.snackbar('Error', 'You have to go through OTP verification.'.tr);
      return null;
    }

    // ===== CLIENT-SIDE VALIDATION =====
    // Validate price
    final priceValue = double.tryParse(price.text);
    if (priceValue == null || priceValue.isNaN || priceValue < 0) {
      Get.snackbar('Error', 'Please enter a valid price'.tr);
      return null;
    }

    // Validate brand selection
    if (selectedBrandUuid.value.isEmpty) {
      Get.snackbar('Error', 'Please select a brand'.tr);
      return null;
    }

    // Validate model selection
    if (selectedModelUuid.value.isEmpty) {
      Get.snackbar('Error', 'Please select a model'.tr);
      return null;
    }

    try {
      final fullPhone = _phoneCtrl.fullPhoneNumber;
      final response = await ApiClient.to.dio.post(
        'posts',
        data: {
          'brandsId': selectedBrandUuid.value.isNotEmpty
              ? selectedBrandUuid.value
              : null,
          'modelsId': selectedModelUuid.value.isNotEmpty
              ? selectedModelUuid.value
              : null,
          'condition': selectedCondition.value,
          'transmission': selectedTransmission.value,
          'engineType': selectedEngineType.value,
          'enginePower': double.tryParse(enginePower.text) ?? 0,
          'year':
              int.tryParse(
                selectedYear.value.isNotEmpty
                    ? selectedYear.value
                    : selectedDate.value.year.toString(),
              ) ??
              selectedDate.value.year,
          'credit': credit.value,
          'exchange': exchange.value,
          'milleage': double.tryParse(milleage.text) ?? 0,
          'vin': vinCode.text,
          'price': priceValue,
          'currency': selectedCurrency.value.isNotEmpty
              ? selectedCurrency.value
              : 'TMT',
          'location': selectedLocation.value,
          'phone': fullPhone,
          'description': description.text,
          'personalInfo': {
            'name': Get.isRegistered<ProfileController>()
                ? Get.find<ProfileController>().name.value
                : '',
            'location': selectedLocation.value,
            'phone': fullPhone,
            'region': 'Local',
          },
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) return data['uuid']?.toString();
        return null;
      } else {
        final errorData = response.data is Map
            ? response.data as Map
            : <String, dynamic>{};
        final errorMsg =
            (errorData['error'] ?? errorData['message'] ?? 'Unknown error')
                .toString();
        debugPrint('Post creation failed (${response.statusCode}): $errorMsg');
        uploadError.value = errorMsg;
        Get.snackbar(
          'error'.tr,
          errorMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Post creation error: $e');
      uploadError.value = e.toString();
      return null;
    }
  }

  /// Fetch user's posts - called by UploadManager after successful upload
  Future<void> fetchMyPosts() async {
    isLoadingP.value = true;

    // Only show shimmer if loading takes longer than 300ms
    _shimmerDelayTimer?.cancel();
    _shimmerDelayTimer = Timer(const Duration(milliseconds: 300), () {
      if (isLoadingP.value && posts.isEmpty) {
        showShimmer.value = true;
      }
    });

    try {
      final postDtos = await PostService.to.fetchMyPosts();
      posts.assignAll(postDtos);
    } on Failure catch (e) {
      debugPrint('Fetch my posts error: $e');
      Get.snackbar('Error', e.message ?? 'Failed to load posts'.tr);
    } catch (e) {
      debugPrint('Fetch my posts error: $e');
      Get.snackbar('Error', 'Failed to load posts: ${e.toString()}'.tr);
    } finally {
      _shimmerDelayTimer?.cancel();
      isLoadingP.value = false;
      showShimmer.value = false;
    }
  }

  /// Delete a specific post
  Future<void> deleteMyPost(String uuid) async {
    try {
      await PostService.to.deleteMyPost(uuid);
      posts.removeWhere((post) => post.uuid == uuid);
      Get.snackbar('Success', 'Post deleted successfully'.tr);
    } on Failure catch (e) {
      Get.snackbar('Error', e.message ?? 'Failed to delete post'.tr);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete post: $e'.tr);
    }
  }

  /// Refresh posts data
  Future<void> refreshData() async {
    try {
      await fetchMyPosts();
    } catch (e) {
      debugPrint('Refresh data error: $e');
      // Ensure refresh completes even on error
    }
  }

  /// Upload single video - called by UploadManager
  Future<bool> uploadSingleVideo(
    String postUuid,
    PostUploadSnapshot snap, {
    void Function(int deltaBytes)? onBytes,
  }) async {
    try {
      if (selectedVideo.value == null &&
          snap.videoFile == null &&
          snap.compressedVideoFile == null)
        return true;

      return await _uploadVideoPart(postUuid, snap, onBytes: onBytes);
    } catch (e) {
      uploadError.value = e.toString();
      return false;
    }
  }

  /// Upload single photo - called by UploadManager
  Future<bool> uploadSinglePhoto(
    String postUuid,
    PostUploadSnapshot snap,
    int index, {
    void Function(int deltaBytes)? onBytes,
  }) async {
    try {
      if (snap.photoBase64.isEmpty || index >= snap.photoBase64.length) {
        return true;
      }
      return await _uploadSinglePhotoPart(
        postUuid,
        snap,
        index,
        onBytes: onBytes,
      );
    } catch (e) {
      uploadError.value = e.toString();
      return false;
    }
  }

  Future<bool> _uploadVideoPart(
    String postUuid,
    PostUploadSnapshot snap, {
    void Function(int deltaBytes)? onBytes,
  }) async {
    try {
      final file =
          (snap.usedCompressedVideo
              ? snap.compressedVideoFile
              : snap.videoFile) ??
          selectedVideo.value;

      if (file == null || !file.existsSync()) {
        return true;
      }

      _activeCancelToken = dio.CancelToken();
      int lastSent = 0;

      final form = dio.FormData.fromMap({
        'postId': postUuid,
        'uuid': postUuid,
        'file': await dio.MultipartFile.fromFile(
          file.path,
          filename: 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
        ),
      });

      final resp = await ApiClient.to.dio.post(
        'video/upload',
        data: form,
        cancelToken: _activeCancelToken,
        options: dio.Options(
          sendTimeout: const Duration(seconds: 300),
          receiveTimeout: const Duration(minutes: 2),
        ),
        onSendProgress: (sent, total) {
          final delta = sent - lastSent;
          lastSent = sent;
          _videoSentBytes.value += delta;
          _totalBytesSent.value += delta;
          if (_videoTotalBytes.value > 0) {
            videoUploadProgress.value =
                (_videoSentBytes.value / _videoTotalBytes.value).clamp(0, 1);
          }
          if (delta > 0) onBytes?.call(delta);
        },
      );

      if (resp.statusCode != null && resp.statusCode! >= 300) {
        uploadError.value =
            'common_error'.tr + ' (video ${resp.statusCode}): ${resp.data}';
        return false;
      }
      return true;
    } on dio.DioException catch (e) {
      if (dio.CancelToken.isCancel(e)) {
        uploadError.value = 'post_upload_cancelled_hint'.tr;
      } else {
        final status = e.response?.statusCode;
        final body = e.response?.data;
        uploadError.value =
            'Video upload error${status != null ? ' ($status)' : ''}: ${body ?? e.message}';
      }
      return false;
    } catch (e) {
      uploadError.value = 'Video upload exception: $e';
      return false;
    }
  }

  Future<bool> _uploadSinglePhotoPart(
    String postUuid,
    PostUploadSnapshot snap,
    int index, {
    void Function(int deltaBytes)? onBytes,
  }) async {
    try {
      final b64 = snap.photoBase64[index];
      final bytes = base64Decode(b64);

      _activeCancelToken = dio.CancelToken();
      int lastSent = 0;

      await ApiClient.to.dio.post(
        'photo/posts',
        data: dio.FormData.fromMap({
          'uuid': postUuid,
          'file': dio.MultipartFile.fromBytes(
            bytes,
            filename:
                'photo_${index + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        }),
        cancelToken: _activeCancelToken,
        options: dio.Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
        onSendProgress: (sent, total) {
          final delta = sent - lastSent;
          lastSent = sent;
          _photosSentBytes.value += delta;
          _totalBytesSent.value += delta;
          if (_photosTotalBytes.value > 0) {
            photosUploadProgress.value =
                (_photosSentBytes.value / _photosTotalBytes.value).clamp(0, 1);
          }
          if (delta > 0) onBytes?.call(delta);
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cancel ongoing upload
  Future<void> cancelOngoingUpload() async {
    if (isUploadComplete.value ||
        isUploadFailed.value ||
        isUploadCancelled.value) {
      return;
    }

    isCancellingUpload.value = true;
    uploadStatus.value = 'Cancelling...';

    try {
      _activeCancelToken?.cancel('User cancelled');
      isUploadCancelled.value = true;

      if (_activePostUuid != null) {
        await _deleteCreatedPostCascade(_activePostUuid!);
      }

      await _clearMediaCaches();
      uploadStatus.value = 'post_upload_cancelled_hint'.tr;
    } catch (e) {
      uploadError.value = 'Cancel cleanup error: $e';
    } finally {
      _clearPersistedUploadState();
      isCancellingUpload.value = false;
      isPosting.value = false;
    }
  }

  Future<void> _deleteCreatedPostCascade(String postUuid) async {
    try {
      await PostService.to.deleteCreatedPostCascade(postUuid);
    } catch (e) {
      debugPrint('Cancel cleanup exception: $e');
    }
  }

  Future<void> _clearMediaCaches() async {
    try {
      selectedImages.clear();
      _cancelVideoCompression();
      _deleteCompressedFile();

      if (selectedVideo.value != null) {
        selectedVideo.value = null;
      }

      videoThumbnail.value = null;
      isVideoInitialized.value = false;
      videoPlayerController?.dispose();
      videoPlayerController = null;

      try {
        await VideoCompress.deleteAllCache();
      } catch (_) {}
    } catch (_) {}
  }

  // Persistence for crash recovery
  static const _persistKeyActiveUpload = 'ACTIVE_UPLOAD_V1';

  void _clearPersistedUploadState() {
    try {
      box.remove(_persistKeyActiveUpload);
    } catch (_) {}
  }

  Future<void> recoverOrCleanupStaleUpload() async {
    try {
      final raw = box.read(_persistKeyActiveUpload);
      if (raw is! Map) return;

      final uuid = raw['postUuid']?.toString() ?? '';
      final tsStr = raw['timestamp']?.toString();
      if (uuid.isEmpty || tsStr == null) return;

      final ts = DateTime.tryParse(tsStr);
      if (ts == null) return;

      if (DateTime.now().difference(ts) > const Duration(minutes: 10)) {
        await _deleteCreatedPostCascade(uuid);
        _clearPersistedUploadState();
      }
    } catch (_) {}
  }

  // Media picking and compression
  Future<void> pickImages() async {
    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      for (final image in images) {
        final bytes = await image.readAsBytes();
        selectedImages.add(bytes);
      }

      _rebuildImageSigCache();
      markFieldChanged();
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick images: $e');
    }
  }

  Future<void> pickVideo() async {
    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        final file = File(video.path);
        selectedVideo.value = file;
        originalVideoBytes.value = await file.length();

        await _generateVideoThumbnail(file.path);

        if (_shouldCompressVideo(originalVideoBytes.value)) {
          await _compressVideo(file);
        } else {
          await _initializeVideoPlayer(file);
        }

        markFieldChanged();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick video: $e');
    }
  }

  /// Remove an image at the specified index
  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
      _rebuildImageSigCache();
      markFieldChanged();
    }
  }

  /// Dispose video player and clear video state
  void disposeVideo() {
    try {
      videoPlayerController?.dispose();
      videoPlayerController = null;
      selectedVideo.value = null;
      videoThumbnail.value = null;
      isVideoInitialized.value = false;
      usedCompressedVideo.value = false;
      compressedVideoFile.value = null;
      originalVideoBytes.value = 0;
      compressedVideoBytes.value = 0;
      _cancelVideoCompression();
      _deleteCompressedFile();
      markFieldChanged();
    } catch (e) {
      debugPrint('Error disposing video: $e');
    }
  }

  // Brand/model fetching – delegated to BrandModelService
  void fetchBrands({bool forceRefresh = false}) =>
      _brandModelSvc.fetchBrands(forceRefresh: forceRefresh);
  void fetchModels(
    String brandUuid, {
    bool forceRefresh = false,
    bool showLoading = true,
  }) => _brandModelSvc.fetchModels(
    brandUuid,
    forceRefresh: forceRefresh,
    showLoading: showLoading,
  );
  String resolveBrandName(String idOrName) =>
      _brandModelSvc.resolveBrandName(idOrName);
  String resolveModelName(String idOrName) =>
      _brandModelSvc.resolveModelName(idOrName);
  String resolveModelWithBrand(String modelId, String brandId) =>
      _brandModelSvc.resolveModelWithBrand(modelId, brandId);
  Future<void> ensureBrandModelCachesLoaded() =>
      _brandModelSvc.ensureCachesLoaded();

  // Permission handling
  Future<void> requestGalleryPermission(BuildContext context) async {
    PermissionStatus status = await Permission.photos.request();
    if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(context);
    }
  }

  void _showPermanentlyDeniedDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text(
          'Please go to app settings to grant gallery permission.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => NavigationUtils.closeGlobal(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  // Token refresh is now handled by the Dio ApiClient interceptor.
  // The duplicated refreshAccessToken() method has been removed.

  // Phone verification methods - delegated to PhoneVerificationController
  Future<void> sendOtp() => _phoneCtrl.sendOtp();
  Future<void> verifyOtp() => _phoneCtrl.verifyOtp();

  // Date selection method
  Future<void> showDatePickerAndroid(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      selectedDate.value = picked;
      selectedYear.value = picked.year.toString();
      markFieldChanged();
    }
  }

  /// Reset controller state - called by UI and UploadManager
  void reset() {
    // Reset form fields
    price.clear();
    enginePower.clear();
    milleage.clear();
    vinCode.clear();
    description.clear();

    // Reset phone verification state (restores original profile phone)
    _phoneCtrl.resetVerification();

    // Reset selections
    selectedBrandUuid.value = '';
    selectedModelUuid.value = '';
    selectedBrand.value = '';
    selectedModel.value = '';
    selectedCondition.value = '';
    selectedTransmission.value = '';
    selectedEngineType.value = '';
    selectedDate.value = DateTime.now();
    selectedCurrency.value = 'TMT';
    selectedLocation.value = '';
    selectedYear.value = '';
    credit.value = false;
    exchange.value = false;

    // Reset media
    selectedImages.clear();
    disposeVideo();

    // Reset search queries
    brandSearchQuery.value = '';
    searchModel.value = '';

    // Reset upload state
    isLoading.value = false;
    uploadProgress.value = 0.0;
    uploadStatus.value = 'post_upload_ready'.tr;
    uploadError.value = '';
    isUploadComplete.value = false;
    isUploadFailed.value = false;
    isUploadCancelled.value = false;
    isCancellingUpload.value = false;
    canRetry.value = false;
    videoUploadProgress.value = 0.0;
    photosUploadProgress.value = 0.0;

    // Reset form persistence
    clearSavedForm();
    isDirty.value = false;
    _lastSavedSignature = null;
    _rebuildImageSigCache();
    // Ensure posting flag cleared after a form reset triggered by upload success
    if (isPosting.value) isPosting.value = false;
  }

  // Form persistence and dirty tracking
  static const _savedFormKey = 'SAVED_POST_FORM_V1';

  void saveForm() {
    try {
      final map = {
        'brandUuid': selectedBrandUuid.value,
        'modelUuid': selectedModelUuid.value,
        'brand': selectedBrand.value,
        'model': selectedModel.value,
        'condition': selectedCondition.value,
        'transmission': selectedTransmission.value,
        'engineType': selectedEngineType.value,
        'year': selectedYear.value.isNotEmpty
            ? selectedYear.value
            : selectedDate.value.year.toString(),
        'price': price.text,
        'currency': selectedCurrency.value,
        'location': selectedLocation.value,
        'credit': credit.value,
        'exchange': exchange.value,
        'enginePower': enginePower.text,
        'milleage': milleage.text,
        'vin': vinCode.text,
        'description': description.text,
        'phone': phoneController.text,
        'images': List.generate(selectedImages.length, (i) {
          final bytes = selectedImages[i];
          final sig = i < _imageSigCache.length
              ? _imageSigCache[i]
              : _ImageSig(bytes);
          return {'b64': base64Encode(bytes), 'l': sig.length, 'h': sig.hash};
        }),
        'videoPath': selectedVideo.value?.path,
        'usedCompressed': usedCompressedVideo.value,
        'compressedVideoPath': compressedVideoFile.value?.path,
        'videoThumb': videoThumbnail.value != null
            ? base64Encode(videoThumbnail.value!)
            : null,
        '_signature': null,
      };

      final sig = _computeSignature(map);
      map['_signature'] = sig;
      box.write(_savedFormKey, map);
      // Mark saved even if the form is still incomplete (partial save)
      isFormSaved.value = true;
      _lastSavedSignature = sig;
      isDirty.value = false;
    } catch (_) {}
  }

  void _loadSavedForm() {
    try {
      final raw = box.read(_savedFormKey);
      if (raw is! Map) return;

      selectedBrandUuid.value = (raw['brandUuid'] ?? '') as String;
      selectedModelUuid.value = (raw['modelUuid'] ?? '') as String;
      selectedBrand.value = (raw['brand'] ?? '') as String;
      selectedModel.value = (raw['model'] ?? '') as String;
      selectedCondition.value = (raw['condition'] ?? '') as String;
      selectedTransmission.value = (raw['transmission'] ?? '') as String;
      selectedEngineType.value = (raw['engineType'] ?? '') as String;

      final dateStr = raw['date'] as String?;
      final yearStr = raw['year'] as String?;
      if (dateStr != null) {
        final dt = DateTime.tryParse(dateStr);
        if (dt != null) selectedDate.value = dt;
      }
      if (yearStr != null && yearStr.isNotEmpty) {
        final yr = int.tryParse(yearStr);
        if (yr != null) {
          selectedDate.value = DateTime(
            yr,
            selectedDate.value.month,
            selectedDate.value.day,
          );
          selectedYear.value = yr.toString();
        }
      }

      price.text = (raw['price'] ?? '') as String;
      selectedCurrency.value = (raw['currency'] ?? 'TMT') as String;
      selectedLocation.value = (raw['location'] ?? '') as String;
      credit.value = raw['credit'] == true;
      exchange.value = raw['exchange'] == true;
      enginePower.text = (raw['enginePower'] ?? '') as String;
      milleage.text = (raw['milleage'] ?? '') as String;
      vinCode.text = (raw['vin'] ?? '') as String;
      description.text = (raw['description'] ?? '') as String;

      // Always prefer originalFullPhone subscriber; ignore saved phone to avoid conflicts
      _phoneCtrl.restoreOriginalPhone();

      // Load images
      selectedImages.clear();
      final imgList = (raw['images'] as List?)?.toList() ?? [];
      for (final entry in imgList) {
        if (entry is String) {
          try {
            selectedImages.add(base64Decode(entry));
          } catch (_) {}
        } else if (entry is Map && entry['b64'] is String) {
          try {
            selectedImages.add(base64Decode(entry['b64'] as String));
          } catch (_) {}
        }
      }

      // Load video if exists
      final videoPath = raw['videoPath'] as String?;
      if (videoPath != null && videoPath.isNotEmpty) {
        final f = File(videoPath);
        if (f.existsSync()) {
          selectedVideo.value = f;
          final usedComp = raw['usedCompressed'] == true;
          usedCompressedVideo.value = usedComp;

          final compPath = raw['compressedVideoPath'] as String?;
          if (compPath != null && compPath.isNotEmpty) {
            final cf = File(compPath);
            if (cf.existsSync()) compressedVideoFile.value = cf;
          }

          final thumbB64 = raw['videoThumb'] as String?;
          if (thumbB64 != null) {
            try {
              videoThumbnail.value = base64Decode(thumbB64);
            } catch (_) {}
          }

          _initializeVideoPlayer(
            usedCompressedVideo.value && compressedVideoFile.value != null
                ? compressedVideoFile.value!
                : f,
          );
        }
      }

      // Treat any loaded snapshot as a saved (possibly partial) form
      isFormSaved.value = true;
      hydratedFromStorage.value = true;

      if (raw.containsKey('_signature') && raw['_signature'] is String) {
        _lastSavedSignature = raw['_signature'] as String;
      } else {
        final sig = _computeSignature(
          raw.map((k, v) => MapEntry(k.toString(), v)),
        );
        _lastSavedSignature = sig;
      }
      // Because we may have modified fields (e.g., phone replaced with subscriber digits) AFTER
      // reading the raw map, recompute signature from the CURRENT snapshot to align baseline.
      final currentSig = _computeSignature(_currentSnapshotMap());
      _lastSavedSignature = currentSig;
      isDirty.value = false;
    } catch (_) {}
  }

  void clearSavedForm() {
    try {
      box.remove(_savedFormKey);
    } catch (_) {}
    isFormSaved.value = false;
    hydratedFromStorage.value = false;
    _lastSavedSignature = null;
    _recomputeDirty();
  }

  void dismissHydratedIndicator() => hydratedFromStorage.value = false;

  String _computeSignature(Map<String, dynamic> map) {
    try {
      final jsonStr = jsonEncode(map);
      int hash = 0xcbf29ce484222325;
      const int prime = 0x100000001b3;
      for (final codeUnit in jsonStr.codeUnits) {
        hash ^= codeUnit;
        hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
      }
      return hash.toRadixString(16);
    } catch (_) {
      return DateTime.now().microsecondsSinceEpoch.toString();
    }
  }

  Map<String, dynamic> _currentSnapshotMap() => {
    'brandUuid': selectedBrandUuid.value,
    'modelUuid': selectedModelUuid.value,
    'brand': selectedBrand.value,
    'model': selectedModel.value,
    'condition': selectedCondition.value,
    'transmission': selectedTransmission.value,
    'engineType': selectedEngineType.value,
    'year': selectedYear.value.isNotEmpty
        ? selectedYear.value
        : selectedDate.value.year.toString(),
    'price': price.text,
    'currency': selectedCurrency.value,
    'location': selectedLocation.value,
    'credit': credit.value,
    'exchange': exchange.value,
    'enginePower': enginePower.text,
    'milleage': milleage.text,
    'vin': vinCode.text,
    'description': description.text,
    'phone': phoneController.text,
    'images': _imageSigCache.map((s) => {'l': s.length, 'h': s.hash}).toList(),
    'videoPath': selectedVideo.value?.path ?? '',
    'videoBytes':
        selectedVideo.value != null && selectedVideo.value!.existsSync()
        ? selectedVideo.value!.lengthSync()
        : 0,
    'videoMtime':
        selectedVideo.value != null && selectedVideo.value!.existsSync()
        ? selectedVideo.value!.lastModifiedSync().millisecondsSinceEpoch
        : 0,
    'usedCompressed': usedCompressedVideo.value,
    'compressedVideoPath': compressedVideoFile.value?.path ?? '',
  };

  void _recomputeDirty() {
    if (_lastSavedSignature == null) {
      isDirty.value = false;
      return;
    }
    final sig = _computeSignature(_currentSnapshotMap());
    isDirty.value = sig != _lastSavedSignature;
  }

  void markFieldChanged() {
    // If form never saved yet: treat any change as making it dirty (so exit prompts appear)
    if (!isFormSaved.value) {
      if (!isDirty.value && hasAnyInput) {
        isDirty.value = true;
      }
      return;
    }
    _recomputeDirty();
  }

  void revertToSavedSnapshot() {
    try {
      final raw = box.read(_savedFormKey);
      if (raw is! Map) return;

      selectedBrandUuid.value = (raw['brandUuid'] ?? '') as String;
      selectedModelUuid.value = (raw['modelUuid'] ?? '') as String;
      selectedBrand.value = (raw['brand'] ?? '') as String;
      selectedModel.value = (raw['model'] ?? '') as String;
      selectedCondition.value = (raw['condition'] ?? '') as String;
      selectedTransmission.value = (raw['transmission'] ?? '') as String;
      selectedEngineType.value = (raw['engineType'] ?? '') as String;

      final dateStr = raw['date'] as String?;
      final yearStr2 = raw['year'] as String?;
      if (dateStr != null) {
        final dt = DateTime.tryParse(dateStr);
        if (dt != null) selectedDate.value = dt;
      }
      if (yearStr2 != null && yearStr2.isNotEmpty) {
        final y2 = int.tryParse(yearStr2);
        if (y2 != null) {
          selectedDate.value = DateTime(
            y2,
            selectedDate.value.month,
            selectedDate.value.day,
          );
          selectedYear.value = y2.toString();
        }
      }

      price.text = (raw['price'] ?? '') as String;
      selectedCurrency.value = (raw['currency'] ?? 'TMT') as String;
      selectedLocation.value = (raw['location'] ?? '') as String;
      credit.value = raw['credit'] == true;
      exchange.value = raw['exchange'] == true;
      enginePower.text = (raw['enginePower'] ?? '') as String;
      milleage.text = (raw['milleage'] ?? '') as String;
      vinCode.text = (raw['vin'] ?? '') as String;
      description.text = (raw['description'] ?? '') as String;

      // Restore only subscriber digits (no +993 prefix) to avoid showing full international format
      _phoneCtrl.restoreOriginalPhone();

      // Load images
      final imgList = (raw['images'] as List?)?.toList() ?? [];
      selectedImages.clear();
      for (final entry in imgList) {
        if (entry is String) {
          try {
            selectedImages.add(base64Decode(entry));
          } catch (_) {}
        } else if (entry is Map && entry['b64'] is String) {
          try {
            selectedImages.add(base64Decode(entry['b64'] as String));
          } catch (_) {}
        }
      }
      _rebuildImageSigCache();

      final videoPath = raw['videoPath'] as String?;
      if (videoPath != null && videoPath.isNotEmpty) {
        final f = File(videoPath);
        if (f.existsSync()) {
          selectedVideo.value = f;
          final usedComp = raw['usedCompressed'] == true;
          usedCompressedVideo.value = usedComp;

          final compPath = raw['compressedVideoPath'] as String?;
          if (compPath != null && compPath.isNotEmpty) {
            final cf = File(compPath);
            if (cf.existsSync()) compressedVideoFile.value = cf;
          }
        }
      }
      // Align baseline signature with the snapshot we just restored (with normalized phone value)
      _lastSavedSignature = _computeSignature(_currentSnapshotMap());
      isDirty.value = false;
    } catch (_) {}
  }

  void _rebuildImageSigCache() {
    _imageSigCache = selectedImages.map((e) => _ImageSig(e)).toList();
  }

  void _attachUploadLifecycleListener() {
    // If UploadManager not yet registered (edge case), skip.
    if (!Get.isRegistered<UploadManager>()) return;
    final mgr = Get.find<UploadManager>();
    // Listen to progress stream for terminal events so we can clear isPosting reliably
    _uploadProgressSub = mgr.progressStream.listen((event) {
      if (event.terminal == true ||
          event.isCompleted ||
          event.isFailed ||
          event.isCancelled) {
        if (isPosting.value) {
          isPosting.value = false;
        }
      }
    });
    // Also reactive fallback: when currentTask becomes null and we were posting, clear flag
    ever<UploadTask?>(mgr.currentTask, (task) {
      if (task == null && isPosting.value) {
        isPosting.value = false;
      }
    });
  }
}

// Video compression helpers
extension _VideoCompressionHelpers on PostController {
  static const int _minVideoCompressBytes = 25 * 1024 * 1024; // 25 MB

  bool _shouldCompressVideo(int sizeBytes) =>
      sizeBytes >= _minVideoCompressBytes;

  Future<void> _generateVideoThumbnail(String path) async {
    try {
      final thumb = await VideoThumbnail.thumbnailData(
        video: path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 320,
        quality: 75,
      );
      if (thumb != null && thumb.isNotEmpty) {
        videoThumbnail.value = thumb;
      }
    } catch (_) {}
  }

  Future<void> _compressVideo(
    File original, {
    bool forceTranscode = false,
  }) async {
    isCompressingVideo.value = true;
    videoCompressionProgress.value = 0;
    usedCompressedVideo.value = false;

    try {
      _videoCompressSub?.unsubscribe?.call();
    } catch (_) {
      try {
        _videoCompressSub?.cancel();
      } catch (_) {}
    }

    _videoCompressSub = VideoCompress.compressProgress$.subscribe((progress) {
      videoCompressionProgress.value = (progress / 100).clamp(0, 1);
    });

    try {
      final result = await VideoCompress.compressVideo(
        original.path,
        quality: forceTranscode
            ? VideoQuality.MediumQuality
            : VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (result != null && result.file != null) {
        compressedVideoFile.value = result.file;
        try {
          compressedVideoBytes.value = await result.file!.length();
        } catch (_) {}
        usedCompressedVideo.value = true;
        await _initializeVideoPlayer(result.file!);
      } else {
        await _initializeVideoPlayer(original);
      }
    } catch (_) {
      await _initializeVideoPlayer(original);
    } finally {
      try {
        _videoCompressSub?.unsubscribe?.call();
      } catch (_) {
        try {
          _videoCompressSub?.cancel();
        } catch (_) {}
      }
      _videoCompressSub = null;
      isCompressingVideo.value = false;
    }
  }

  Future<void> _initializeVideoPlayer(File file) async {
    try {
      videoPlayerController?.dispose();
      videoPlayerController = VideoPlayerController.file(file);
      await videoPlayerController!.initialize();
      videoPlayerController!.setLooping(false);
      videoPlayerController!.pause();
      videoPlayerController!.setVolume(0);
      isVideoInitialized.value = true;
    } catch (_) {
      isVideoInitialized.value = false;
    }
  }

  void _cancelVideoCompression() {
    if (isCompressingVideo.value) {
      VideoCompress.cancelCompression();
    }
    try {
      _videoCompressSub?.unsubscribe?.call();
    } catch (_) {
      try {
        _videoCompressSub?.cancel();
      } catch (_) {}
    }
    _videoCompressSub = null;
    isCompressingVideo.value = false;
  }

  void _deleteCompressedFile() {
    try {
      final f = compressedVideoFile.value;
      if (f != null && f.existsSync()) {
        f.deleteSync();
      }
    } catch (_) {}
    compressedVideoFile.value = null;
    compressedVideoBytes.value = 0;
    usedCompressedVideo.value = false;
  }
}

extension PostControllerImageHelpers on PostController {
  String buildPostImageUrl(String raw) {
    if (raw.isEmpty) return '';
    final trimmedBase = ApiKey.ip.endsWith('/') ? ApiKey.ip : '${ApiKey.ip}';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    var path = raw.trim();
    // Common patterns: "/uploads/..", "uploads/...", may include leading domain accidentally
    if (path.startsWith('/')) path = path.substring(1);
    // Prevent double host repetition
    if (path.startsWith(trimmedBase.replaceFirst(RegExp(r'https?://'), ''))) {
      // Already contains host-like segment, return with schema
      return path.startsWith('http') ? path : 'http://$path';
    }
    return '$trimmedBase$path';
  }
}
