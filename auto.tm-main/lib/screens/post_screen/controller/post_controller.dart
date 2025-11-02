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
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:auto_tm/services/auth/auth_service.dart';

import 'package:auto_tm/models/image_metadata.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import 'upload_manager.dart';
import 'package:auto_tm/utils/hashing.dart';
import 'package:auto_tm/utils/phone_utils.dart';
import 'package:auto_tm/screens/post_screen/services/draft_service.dart';
import 'package:auto_tm/screens/post_screen/model/post_form_state.dart';
import 'package:auto_tm/screens/post_screen/model/brand_dto.dart';
import 'package:auto_tm/screens/post_screen/model/model_dto.dart';
import 'package:auto_tm/screens/post_screen/utils/json_parsers.dart';
import '../services/media_service.dart';
import '../services/upload_service.dart';
import '../services/cache_service.dart';
import '../services/error_handler_service.dart';
import '../repository/brand_repository.dart';
import '../repository/model_repository.dart';
import '../repository/post_repository.dart';
import '../repository/repository_exceptions.dart';

// BrandDto & ModelDto extracted to model/brand_dto.dart and model/model_dto.dart

/// Post data transfer object
class PostDto {
  final String uuid;
  final String brand;
  final String model;
  final String brandId; // raw brandsId from backend (may be empty)
  final String modelId; // raw modelsId from backend (may be empty)
  final double price;
  final String photoPath;
  final double year;
  final double milleage;
  final String currency;
  final String createdAt;
  final bool?
  status; // nullable: null -> pending moderation, true -> active, false -> declined/inactive
  final int? commentCount; // Number of comments on this post

  PostDto({
    required this.uuid,
    required this.brand,
    required this.model,
    required this.brandId,
    required this.modelId,
    required this.price,
    required this.photoPath,
    required this.year,
    required this.milleage,
    required this.currency,
    required this.createdAt,
    required this.status,
    this.commentCount,
  });

  factory PostDto.fromJson(Map<String, dynamic> json) => PostDto(
    uuid: json['uuid']?.toString() ?? json['id']?.toString() ?? '',
    brand: JsonParsers.extractBrand(json),
    model: JsonParsers.extractModel(json),
    brandId: json['brandsId']?.toString() ?? '',
    modelId: json['modelsId']?.toString() ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    photoPath: JsonParsers.extractPhotoPath(json),
    year: (json['year'] as num?)?.toDouble() ?? 0.0,
    milleage: (json['milleage'] as num?)?.toDouble() ?? 0.0,
    currency: json['currency']?.toString() ?? '',
    createdAt: json['createdAt']?.toString() ?? '',
    status: json.containsKey('status') ? json['status'] as bool? : null,
    commentCount:
        json['commentCount'] as int? ?? json['_count']?['comments'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'brand': brand,
    'model': model,
    'brandsId': brandId,
    'modelsId': modelId,
    'price': price,
    'photoPath': photoPath,
    'year': year,
    'milleage': milleage,
    'currency': currency,
    'createdAt': createdAt,
    'status': status,
    if (commentCount != null) 'commentCount': commentCount,
  };
}

/// Tri-state status mapping for nullable boolean status.
enum PostStatusTri { pending, active, inactive }

extension PostDtoStatusExt on PostDto {
  PostStatusTri get triStatus {
    if (status == null) return PostStatusTri.pending;
    return status! ? PostStatusTri.active : PostStatusTri.inactive;
  }

  String statusLabel({String? pending, String? active, String? inactive}) {
    switch (triStatus) {
      case PostStatusTri.pending:
        return pending ?? 'post_status_pending'.tr;
      case PostStatusTri.active:
        return active ?? 'post_status_active'.tr;
      case PostStatusTri.inactive:
        return inactive ?? 'post_status_declined'.tr;
    }
  }
}

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

  // Phone verification
  final TextEditingController phoneController = TextEditingController();
  // We now keep a single canonical full phone number string in +993XXXXXXXX format.
  // Backend/user storage supplies phone like '+99361678767'. We compare exact string (after normalization).
  String _originalFullPhone = ''; // e.g. +99361678767
  final RxBool isOriginalPhone = true.obs;
  final TextEditingController otpController = TextEditingController();
  final FocusNode otpFocus = FocusNode();
  Timer? _timer;

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
  final RxList<ImageMetadata> selectedImages = <ImageMetadata>[].obs;
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

  // Brand/model data
  final RxList<BrandDto> brands = <BrandDto>[].obs;
  final RxList<ModelDto> models = <ModelDto>[].obs;
  // Fast lookup maps (id -> name)
  final Map<String, String> _brandNameById = {};
  final Map<String, String> _modelNameById = {};
  final Set<String> _fetchedBrandModels = <String>{};
  // Trigger rebuilds when late model names are populated
  final RxInt modelNameResolutionTick = 0.obs;
  final RxBool isLoadingB = false.obs;
  final RxBool isLoadingM = false.obs;
  final RxBool brandsFromCache = false.obs;
  final RxBool modelsFromCache = false.obs;
  // Services
  late final CacheService _cacheService;

  // Video size and duration constraints
  static const int _minVideoCompressBytes = 25 * 1024 * 1024; // 25 MB
  static const int _maxVideoDurationSeconds = 60; // 60 seconds limit

  // Phone verification state
  final RxBool isPhoneVerified = false.obs;
  final RxBool isLoadingOtp = false.obs;
  final RxInt resendCountdown = 0.obs;
  final RxBool canResend = true.obs;

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
  final RxString brandSearchQuery = ''.obs;
  final RxString searchModel = ''.obs;
  final RxBool needsOtp = false.obs;
  final RxBool showOtpField = false.obs;
  final RxBool isSendingOtp = false.obs;
  final RxInt countdown = 0.obs;

  // Posts management
  final RxList<PostDto> posts = <PostDto>[].obs;
  final RxBool isLoadingP = false.obs;
  final RxBool showShimmer = false.obs;
  Timer? _shimmerDelayTimer;

  // Computed getters for filtered lists
  List<BrandDto> get filteredBrands {
    if (brandSearchQuery.value.isEmpty) return brands;
    return brands
        .where(
          (brand) => brand.name.toLowerCase().contains(
            brandSearchQuery.value.toLowerCase(),
          ),
        )
        .toList();
  }

  List<ModelDto> get filteredModels {
    if (searchModel.value.isEmpty) return models;
    return models
        .where(
          (model) => model.name.toLowerCase().contains(
            searchModel.value.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    // Ensure MediaService is available (idempotent Put if not registered)
    if (!Get.isRegistered<MediaService>()) {
      Get.put(MediaService());
    }
    // Ensure CacheService is available
    if (!Get.isRegistered<CacheService>()) {
      Get.put(CacheService());
    }
    _cacheService = Get.find<CacheService>();
    // Ensure repositories are available
    if (!Get.isRegistered<IBrandRepository>()) {
      Get.put<IBrandRepository>(BrandRepository());
    }
    if (!Get.isRegistered<IModelRepository>()) {
      Get.put<IModelRepository>(ModelRepository());
    }
    if (!Get.isRegistered<IPostRepository>()) {
      Get.put<IPostRepository>(PostRepository());
    }
    _initializeOriginalPhone();
    _attachProfilePhoneListener();
    _hydrateBrandCache();
    _loadSavedForm();
    _rebuildImageSigCache();
    phoneController.addListener(_onPhoneInputChanged);
    recoverOrCleanupStaleUpload();
    _attachUploadLifecycleListener();
    // Build name maps if cached brands/models already loaded
    _rebuildNameLookups();
  }

  @override
  void onClose() {
    phoneController.removeListener(_onPhoneInputChanged);
    phoneController.dispose();
    otpController.dispose();
    otpFocus.dispose();
    _timer?.cancel();
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
      if (Get.isRegistered<MediaService>()) {
        try {
          Get.find<MediaService>().disposeCompressionCache();
        } catch (_) {}
      }
    }
    super.onClose();
  }

  void _onPhoneInputChanged() {
    markFieldChanged();
    final sub = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final current = sub.isEmpty ? '' : '993$sub';
    if (sub.isEmpty) {
      isPhoneVerified.value = false;
      needsOtp.value = false; // wait until user types something meaningful
      showOtpField.value = false;
      if (kDebugMode) {
        // ignore: avoid_print
        print('[phone] cleared -> reset verification flags');
      }
      return;
    }
    if (_originalFullPhone.isNotEmpty &&
        PhoneUtils.stripPlus(_originalFullPhone) == current) {
      if (!isPhoneVerified.value) isPhoneVerified.value = true;
      needsOtp.value = false;
      showOtpField.value = false;
      _timer?.cancel();
      countdown.value = 0;
      otpController.clear();
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          '[phone] auto-verified using original full phone=$_originalFullPhone sub=$sub',
        );
      }
      return;
    }
    // Any non-default phone always requires OTP (even if previously verified in a prior session)
    isPhoneVerified.value = false;
    needsOtp.value = true;
    if (kDebugMode) {
      // ignore: avoid_print
      print('[phone] changed to new subscriber=$sub -> requires OTP');
    }
    // Don't auto-show OTP input until the user presses send
    // Keep existing showOtpField state if user is mid-verification
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
        phoneController.text.trim().isNotEmpty &&
            phoneController.text.trim() != _originalFullPhone ||
        selectedImages.isNotEmpty ||
        selectedVideo.value != null;
  }

  Future<void> startManagedUpload() async {
    if (isPosting.value) return;

    // Guard: Don't start upload while video is compressing
    if (isCompressingVideo.value) {
      ErrorHandlerService.showInfo(
        'Please wait for video compression to complete',
      );
      return;
    }

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
      ErrorHandlerService.handleApiError(e, context: 'Failed to start upload');
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
      ErrorHandlerService.showOtpRequired();
      return null;
    }

    try {
      final token = box.read('ACCESS_TOKEN');
      final fullPhone =
          '+' + PhoneUtils.buildFullPhoneDigits(phoneController.text);
      final postRepo = Get.find<IPostRepository>();

      final postData = {
        // Backend expects brand/model UUID fields named brandsId / modelsId
        'brandsId': selectedBrandUuid.value,
        'modelsId': selectedModelUuid.value,
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
        'price': double.tryParse(price.text) ?? 0,
        'currency': selectedCurrency.value,
        'location': selectedLocation.value,
        'phone': fullPhone,
        'description': description.text,
        // Inject a personalInfo block carrying region semantics. For now region is forced 'Local'.
        'personalInfo': {
          'name': Get.isRegistered<ProfileController>()
              ? Get.find<ProfileController>().name.value
              : '',
          'location': selectedLocation.value, // city
          'phone': fullPhone,
          'region': 'Local',
        },
        // 'subscriptionId': selectedSubscriptionId, // add when implemented
      };

      return await postRepo.createPost(postData, token: token);
    } on AuthExpiredException {
      debugPrint('Post creation: Auth expired');
      ErrorHandlerService.handleAuthExpired();
      return null;
    } on HttpException catch (e) {
      debugPrint('Post creation HTTP error: ${e.message}');
      ErrorHandlerService.handleRepositoryError(
        e,
        context: 'Failed to create post',
      );
      return null;
    } catch (e) {
      debugPrint('Post creation error: $e');
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
      final token = box.read('ACCESS_TOKEN');
      final postRepo = Get.find<IPostRepository>();
      final rawPosts = await postRepo.fetchMyPosts(token: token);

      // Debug: Print first post to see structure
      if (Get.isLogEnable && rawPosts.isNotEmpty) {
        debugPrint('[fetchMyPosts] First post sample: ${rawPosts.first}');
      }

      final postDtos = rawPosts.map((json) => PostDto.fromJson(json)).toList();

      // Debug: Check how many posts have photos
      if (Get.isLogEnable) {
        final withPhotos = postDtos.where((p) => p.photoPath.isNotEmpty).length;
        debugPrint(
          '[fetchMyPosts] Loaded ${postDtos.length} posts, $withPhotos with photos',
        );
      }

      // Filter out posts that are currently being uploaded
      // (prevents showing incomplete posts with no photos during upload)
      final filteredPosts = postDtos.where((post) {
        if (Get.isRegistered<UploadManager>()) {
          final uploadMgr = Get.find<UploadManager>();
          final currentlyUploading = uploadMgr.currentTask.value;
          if (currentlyUploading != null &&
              currentlyUploading.publishedPostId.value == post.uuid &&
              !currentlyUploading.isCompleted.value) {
            if (Get.isLogEnable) {
              debugPrint(
                '[fetchMyPosts] Filtering out uploading post: ${post.uuid}',
              );
            }
            return false; // Hide until upload completes
          }
        }
        return true;
      }).toList();

      posts.assignAll(filteredPosts);
    } on AuthExpiredException {
      final session = await AuthService.to.refreshTokens();
      if (session != null) {
        return fetchMyPosts(); // Retry with new token
      } else {
        ErrorHandlerService.handleAuthExpired();
      }
    } on HttpException catch (e) {
      debugPrint('Fetch my posts HTTP error: ${e.message}');
      ErrorHandlerService.handleRepositoryError(
        e,
        context: 'Failed to load posts',
      );
    } on TimeoutException {
      debugPrint('Fetch my posts timeout');
      ErrorHandlerService.handleTimeout();
    } catch (e) {
      debugPrint('Fetch my posts error: $e');
      ErrorHandlerService.handleApiError(e, context: 'Failed to load posts');
    } finally {
      _shimmerDelayTimer?.cancel();
      isLoadingP.value = false;
      showShimmer.value = false;
    }
  }

  /// Delete a specific post
  Future<void> deleteMyPost(String uuid) async {
    try {
      final token = box.read('ACCESS_TOKEN');
      final response = await http.delete(
        Uri.parse('${ApiKey.getPostsKey}/$uuid'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Remove from local list immediately for instant feedback
        posts.removeWhere((post) => post.uuid == uuid);

        ErrorHandlerService.showSuccess('Post deleted successfully');

        // Refresh list from server to ensure consistency
        // (catches any other changes that might have happened)
        await Future.delayed(const Duration(milliseconds: 500));
        await fetchMyPosts();
      } else {
        ErrorHandlerService.showError('Failed to delete post');
      }
    } catch (e) {
      ErrorHandlerService.handleApiError(e, context: 'Failed to delete post');
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
      final uploadService = Get.find<UploadService>();
      final file =
          (snap.usedCompressedVideo
              ? snap.compressedVideoFile
              : snap.videoFile) ??
          selectedVideo.value;
      if (file == null || !file.existsSync()) return true; // nothing to upload
      final result = await uploadService.uploadVideo(
        postUuid: postUuid,
        file: file,
        onProgress: (sent, total, delta) {
          // maintain legacy progress accounting
          _videoSentBytes.value += delta;
          _videoTotalBytes.value = total; // total stable
          // ratio update
          final ratio = total > 0 ? _videoSentBytes.value / total : 0.0;
          videoUploadProgress.value = ratio.clamp(0, 1).toDouble();
          _totalBytesSent.value += delta;
          onBytes?.call(delta);
        },
      );
      if (!result.success) {
        uploadError.value = ErrorHandlerService.formatUploadError(
          result.error,
          defaultMessage: 'Video upload failed',
        );
      }
      return result.success;
    } catch (e) {
      uploadError.value = ErrorHandlerService.formatUploadError(e.toString());
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
      final b64 = snap.photoBase64[index];
      final bytes = base64Decode(b64);
      final aspectRatio = index < snap.photoAspectRatios.length
          ? snap.photoAspectRatios[index]
          : null;
      final width = index < snap.photoWidths.length
          ? snap.photoWidths[index]
          : null;
      final height = index < snap.photoHeights.length
          ? snap.photoHeights[index]
          : null;
      final uploadService = Get.find<UploadService>();
      final result = await uploadService.uploadPhoto(
        postUuid: postUuid,
        bytes: bytes,
        index: index,
        aspectRatio: aspectRatio is String
            ? double.tryParse(aspectRatio)
            : aspectRatio,
        width: width,
        height: height,
        onProgress: (sent, total, delta) {
          _photosSentBytes.value += delta;
          _photosTotalBytes.value = total;
          final ratio = total > 0 ? _photosSentBytes.value / total : 0.0;
          photosUploadProgress.value = ratio.clamp(0, 1).toDouble();
          _totalBytesSent.value += delta;
          onBytes?.call(delta);
        },
      );
      if (!result.success) {
        uploadError.value = ErrorHandlerService.formatUploadError(
          result.error,
          defaultMessage: 'Photo upload failed',
        );
      }
      return result.success;
    } catch (e) {
      uploadError.value = ErrorHandlerService.formatUploadError(e.toString());
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
      uploadError.value = ErrorHandlerService.formatCancelError(e);
    } finally {
      _clearPersistedUploadState();
      isCancellingUpload.value = false;
      isPosting.value = false;
    }
  }

  Future<void> _deleteCreatedPostCascade(String postUuid) async {
    final token = box.read('ACCESS_TOKEN');
    if (token == null) return;

    try {
      final uri = Uri.parse('${ApiKey.getPostsKey}/$postUuid');
      final resp = await http
          .delete(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode >= 300) {
        debugPrint(
          'Cancel cleanup delete failed: ${resp.statusCode} ${resp.body}',
        );
      }
    } catch (e) {
      debugPrint('Cancel cleanup exception: $e');
    }
  }

  Future<void> _clearMediaCaches() async {
    try {
      // Clear images
      selectedImages.clear();

      // Cancel any active video compression
      _cancelVideoCompression();

      // Dispose video player
      videoPlayerController?.dispose();
      videoPlayerController = null;

      // Clear video state
      if (selectedVideo.value != null) {
        selectedVideo.value = null;
      }
      videoThumbnail.value = null;
      isVideoInitialized.value = false;

      // Delete compressed files
      _deleteCompressedFile();

      // Clean up VideoCompress cache
      if (Get.isRegistered<MediaService>()) {
        await Get.find<MediaService>().disposeCompressionCache();
      }
    } catch (e) {
      debugPrint('Error clearing media caches: $e');
    }
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

  // Media picking delegated to MediaService
  Future<void> pickImages() async {
    try {
      final mediaService = Get.find<MediaService>();
      final images = await mediaService.pickAndAnalyzeImages();
      selectedImages.addAll(images);
      _rebuildImageSigCache();
      markFieldChanged();
    } catch (e) {
      ErrorHandlerService.handleImagePickerError(e);
    }
  }

  Future<void> pickVideo() async {
    try {
      final mediaService = Get.find<MediaService>();
      final file = await mediaService.pickVideoFile();
      if (file == null) return;

      // Validate video duration before processing
      final validation = await mediaService.validateVideoDuration(
        file,
        maxDurationSeconds: _maxVideoDurationSeconds,
      );

      if (!validation.isValid) {
        final message =
            validation.errorMessage ??
            'Maximum video length is $_maxVideoDurationSeconds seconds.';
        Get.snackbar(
          'Video too long'.tr,
          message.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Set initial state
      selectedVideo.value = file;
      originalVideoBytes.value = await file.length();

      final shouldCompress = mediaService.shouldCompressVideo(
        originalVideoBytes.value,
        thresholdBytes: _minVideoCompressBytes,
      );

      // Initialize compression state
      isCompressingVideo.value = shouldCompress;
      videoCompressionProgress.value = 0;

      // Process video (thumbnail + optional compression)
      final result = await mediaService.processVideo(
        video: file,
        shouldCompress: shouldCompress,
        onProgress: (progress) {
          videoCompressionProgress.value = progress;
        },
      );

      // Update state with results
      if (result.thumbnailBytes != null && result.thumbnailBytes!.isNotEmpty) {
        videoThumbnail.value = result.thumbnailBytes;
      }

      compressedVideoFile.value = result.compressedFile;
      usedCompressedVideo.value = result.usedCompressed;
      compressedVideoBytes.value = result.compressedBytes ?? 0;

      // Initialize video player
      await _initializeVideoPlayer(result.playbackFile);

      // Complete - reset compression state
      isCompressingVideo.value = false;
      videoCompressionProgress.value = 1;

      markFieldChanged();
    } catch (e) {
      // Clean up on error
      isCompressingVideo.value = false;
      videoCompressionProgress.value = 0;
      selectedVideo.value = null;
      ErrorHandlerService.handleVideoPickerError(e);
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
      // Cancel any active compression first
      _cancelVideoCompression();

      // Dispose video player
      videoPlayerController?.dispose();
      videoPlayerController = null;

      // Clear video state
      selectedVideo.value = null;
      videoThumbnail.value = null;
      isVideoInitialized.value = false;
      usedCompressedVideo.value = false;
      originalVideoBytes.value = 0;
      compressedVideoBytes.value = 0;

      // Delete compressed file
      _deleteCompressedFile();

      markFieldChanged();
    } catch (e) {
      debugPrint('Error disposing video: $e');
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
    if (Get.isRegistered<MediaService>()) {
      Get.find<MediaService>().cancelCompression();
    }
    isCompressingVideo.value = false;
    videoCompressionProgress.value = 0;
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

  // Brand and model fetching
  void fetchBrands({bool forceRefresh = false}) async {
    if (!forceRefresh && brands.isNotEmpty) return;

    isLoadingB.value = true;
    try {
      if (!forceRefresh &&
          brands.isNotEmpty &&
          brandsFromCache.value &&
          _cacheService.isBrandCacheFresh()) {
        isLoadingB.value = false;
        return;
      }
      final token = box.read('ACCESS_TOKEN');
      final brandRepo = Get.find<IBrandRepository>();
      final parsed = await brandRepo.fetchBrands(token: token);
      brands.assignAll(parsed);
      brandsFromCache.value = false;
      _cacheService.saveBrandCache(parsed);
    } on AuthExpiredException {
      final session = await AuthService.to.refreshTokens();
      if (session != null) {
        return fetchBrands(forceRefresh: forceRefresh);
      } else {
        ErrorHandlerService.showError(
          'Session expired',
          title: 'Failed to load brands',
        );
        _fallbackBrandCache();
      }
    } on TimeoutException {
      ErrorHandlerService.showError(
        'Request timed out',
        title: 'Failed to load brands',
      );
      _fallbackBrandCache();
    } catch (e) {
      ErrorHandlerService.showError(
        e.toString(),
        title: 'Failed to load brands',
      );
      _fallbackBrandCache();
    } finally {
      isLoadingB.value = false;
    }
  }

  void fetchModels(
    String brandUuid, {
    bool forceRefresh = false,
    bool showLoading = true,
  }) async {
    if (brandUuid.isEmpty) return;

    if (!forceRefresh &&
        selectedBrandUuid.value == brandUuid &&
        models.isNotEmpty) {
      return;
    }

    if (showLoading) isLoadingM.value = true;

    try {
      if (!forceRefresh) {
        final cached = _cacheService.loadModelCache(brandUuid);
        if (cached != null && cached.isNotEmpty) {
          models.assignAll(cached);
          modelsFromCache.value = true;
          if (_cacheService.isModelCacheFresh(brandUuid)) {
            isLoadingM.value = false;
            selectedBrandUuid.value = brandUuid;
            return;
          }
        }
      }

      final token = box.read('ACCESS_TOKEN');
      final modelRepo = Get.find<IModelRepository>();
      final parsed = await modelRepo.fetchModels(brandUuid, token: token);
      models.assignAll(parsed);
      selectedBrandUuid.value = brandUuid;
      modelsFromCache.value = false;
      _cacheService.saveModelCache(brandUuid, parsed);
    } on AuthExpiredException {
      final session = await AuthService.to.refreshTokens();
      if (session != null) {
        return fetchModels(
          brandUuid,
          forceRefresh: forceRefresh,
          showLoading: showLoading,
        );
      } else {
        ErrorHandlerService.showError(
          'Session expired',
          title: 'Failed to load models',
        );
        _fallbackModelCache(brandUuid);
      }
    } on HttpException catch (e) {
      ErrorHandlerService.showError(e.message, title: 'Failed to load models');
      _fallbackModelCache(brandUuid);
    } on TimeoutException {
      ErrorHandlerService.showError(
        'Request timed out',
        title: 'Failed to load models',
      );
      _fallbackModelCache(brandUuid);
    } catch (e) {
      ErrorHandlerService.showError(
        e.toString(),
        title: 'Failed to load models',
      );
      _fallbackModelCache(brandUuid);
    } finally {
      if (showLoading) isLoadingM.value = false;
    }
  }

  // Cache management
  void _hydrateBrandCache() {
    final cached = _cacheService.loadBrandCache();
    if (cached != null && cached.isNotEmpty) {
      brands.assignAll(cached);
      brandsFromCache.value = true;
      if (!_cacheService.isBrandCacheFresh()) {
        Future.microtask(() => fetchBrands(forceRefresh: true));
      }
    }
  }

  void _fallbackBrandCache() {
    if (brands.isEmpty) _hydrateBrandCache();
  }

  void _fallbackModelCache(String brandUuid) {
    if (models.isEmpty) {
      final cached = _cacheService.loadModelCache(brandUuid);
      if (cached != null && cached.isNotEmpty) {
        models.assignAll(cached);
      }
    }
  }

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

  // Phone verification methods
  Future<void> sendOtp() async {
    isSendingOtp.value = true;
    try {
      final validationError = PhoneUtils.validatePhoneInput(
        phoneController.text,
      );
      if (validationError != null) {
        ErrorHandlerService.handlePhoneValidationError(validationError);
        return;
      }
      final otpPhone = PhoneUtils.buildFullPhoneDigits(
        phoneController.text,
      ); // digits-only including 993 prefix
      if (_originalFullPhone.isNotEmpty &&
          PhoneUtils.stripPlus(_originalFullPhone) == otpPhone) {
        // Original trusted phone: no OTP required
        isPhoneVerified.value = true;
        needsOtp.value = false;
        showOtpField.value = false;
        return;
      }
      final subscriber = otpPhone.substring(3); // assumes validated
      final result = await AuthService.to.sendOtp(subscriber);
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          '[otp][post] send via AuthService success=${result.success} raw=${result.raw}',
        );
      }
      if (result.success) {
        showOtpField.value = true;
        needsOtp.value = true;
        _startCountdown();
        ErrorHandlerService.showOtpSent(otpPhone);
      } else {
        ErrorHandlerService.handleOtpError(result.message);
      }
    } catch (e) {
      ErrorHandlerService.handleOtpError('Failed to send OTP: $e');
    } finally {
      isSendingOtp.value = false;
    }
  }

  Future<void> verifyOtp() async {
    final phoneError = PhoneUtils.validatePhoneInput(phoneController.text);
    if (phoneError != null) {
      ErrorHandlerService.handlePhoneValidationError(phoneError);
      return;
    }
    final otp = otpController.text.trim();
    if (!RegExp(r'^\d{5}$').hasMatch(otp)) {
      ErrorHandlerService.showInvalidOtpFormat();
      return;
    }
    final otpPhone = PhoneUtils.buildFullPhoneDigits(phoneController.text);
    try {
      final subscriber = otpPhone.substring(3);
      final result = await AuthService.to.verifyOtp(subscriber, otp);
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          '[otp][post] verify via AuthService success=${result.success} raw=${result.raw}',
        );
      }
      if (result.success) {
        isPhoneVerified.value = true;
        needsOtp.value = false;
        showOtpField.value = false;
        _timer?.cancel();
        ErrorHandlerService.showPhoneVerified();
      } else {
        ErrorHandlerService.handleOtpVerificationError(
          result.message ?? 'Please check the code and try again',
        );
      }
    } catch (e) {
      ErrorHandlerService.handleOtpVerificationError('Error verifying OTP: $e');
    }
  }

  void _startCountdown() {
    countdown.value = 60;
    canResend.value = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  // --- Phone helper utilities (subscriber-only input) ---
  // User enters only 8 digit subscriber beginning with 6 or 7. Full phone = 993 + subscriber

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
    // Re-apply original subscriber digits (not full +993 form) if known
    if (_originalFullPhone.isNotEmpty) {
      final sub = PhoneUtils.extractSubscriber(_originalFullPhone);
      phoneController.text = sub.length == 8 ? sub : '';
    } else {
      phoneController.clear();
    }
    otpController.clear();

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

    // Reset phone verification
    // Default phone is implicitly verified
    // Original phone trusted
    isPhoneVerified.value = true;
    needsOtp.value = false;
    showOtpField.value = false;
    isSendingOtp.value = false;
    countdown.value = 0;
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

  // --- Original phone initialization & normalization ---
  void _initializeOriginalPhone() {
    try {
      // Single source: ProfileController phone. If absent now, listener will adopt later.
      String? candidate;
      if (Get.isRegistered<ProfileController>()) {
        final pc = Get.find<ProfileController>();
        if (pc.phone.value.isNotEmpty) candidate = pc.phone.value;
      }
      if (candidate == null || candidate.isEmpty) return; // wait for listener
      final normalized = _normalizeToFullPhone(candidate);
      if (normalized == null) return;
      _originalFullPhone = normalized;
      final sub = PhoneUtils.extractSubscriber(_originalFullPhone);
      if (sub.length == 8 && phoneController.text.trim().isEmpty) {
        phoneController.text = sub; // subscriber only in field
      }
      isOriginalPhone.value = true;
      isPhoneVerified.value = true;
      needsOtp.value = false;
      showOtpField.value = false;
    } catch (_) {}
  }

  void _attachProfilePhoneListener() {
    if (!Get.isRegistered<ProfileController>()) return;
    final pc = Get.find<ProfileController>();
    if (_originalFullPhone.isEmpty && pc.phone.value.isNotEmpty) {
      final n = _normalizeToFullPhone(pc.phone.value);
      if (n != null) _adoptOriginalPhone(n);
    }
    ever<String>(pc.phone, (p) {
      if (_originalFullPhone.isNotEmpty) return; // already locked
      if (p.isEmpty) return;
      final n = _normalizeToFullPhone(p);
      if (n != null) _adoptOriginalPhone(n);
    });
  }

  void _adoptOriginalPhone(String fullPhone) {
    _originalFullPhone = fullPhone;
    final sub = PhoneUtils.extractSubscriber(fullPhone);
    if (phoneController.text.trim().isEmpty && sub.length == 8) {
      phoneController.text = sub;
    }
    isOriginalPhone.value = true;
    isPhoneVerified.value = true;
    needsOtp.value = false;
    showOtpField.value = false;
  }

  String? _normalizeToFullPhone(String raw) {
    try {
      var cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');
      if (cleaned.startsWith('+')) cleaned = cleaned.substring(1);
      // If exactly 8-digit subscriber starting with 6 or 7
      if (RegExp(r'^[67]\d{7}$').hasMatch(cleaned)) {
        cleaned = '993$cleaned';
      }
      // Some sources might give 12 digits (e.g., 9936 + 7 digits) - still accept if prefix 993
      if (!cleaned.startsWith('993')) return null;
      if (cleaned.length < 11)
        return null; // need at least country(3)+subscriber(8)
      return '+$cleaned';
    } catch (_) {
      return null;
    }
  }

  // Form persistence now delegated to DraftService while keeping backward-compatible method names.
  void saveForm() {
    try {
      final formState = PostFormState(
        brandUuid: selectedBrandUuid.value,
        modelUuid: selectedModelUuid.value,
        brandName: selectedBrand.value,
        modelName: selectedModel.value,
        condition: selectedCondition.value,
        transmission: selectedTransmission.value,
        engineType: selectedEngineType.value,
        year: selectedYear.value.isNotEmpty
            ? int.tryParse(selectedYear.value)
            : selectedDate.value.year,
        priceRaw: price.text,
        currency: selectedCurrency.value,
        location: selectedLocation.value,
        credit: credit.value,
        exchange: exchange.value,
        enginePowerRaw: enginePower.text,
        milleageRaw: milleage.text,
        vin: vinCode.text,
        description: description.text,
        phoneRaw: phoneController.text,
        title: '',
        phoneVerified: isPhoneVerified.value,
      );
      final imagesB64 = selectedImages
          .map((m) => base64Encode(m.bytes))
          .toList(growable: false);
      final draftService = Get.find<DraftService>();
      draftService.saveFromFormState(
        id: 'active',
        formState: formState,
        imageBase64: imagesB64,
        originalVideoPath: selectedVideo.value?.path,
        compressedVideoPath: compressedVideoFile.value?.path,
        originalVideoBytes: selectedVideo.value?.existsSync() == true
            ? selectedVideo.value!.lengthSync()
            : null,
        compressedVideoBytes: compressedVideoFile.value?.existsSync() == true
            ? compressedVideoFile.value!.lengthSync()
            : null,
        usedCompressed: usedCompressedVideo.value,
        videoThumbBase64: videoThumbnail.value != null
            ? base64Encode(videoThumbnail.value!)
            : null,
      );
      isFormSaved.value = true;
      _lastSavedSignature = draftService.computeSignature(formState.toMap());
      isDirty.value = false;
    } catch (e) {
      Get.log('[PostController] saveForm error: $e');
    }
  }

  Future<void> _loadSavedForm() async {
    try {
      final draftService = Get.find<DraftService>();
      final draft =
          draftService.find('active') ?? draftService.loadLatestDraft();
      if (draft == null) return;

      selectedBrandUuid.value = draft.brandUuid;
      selectedModelUuid.value = draft.modelUuid;
      selectedBrand.value = draft.brandName;
      selectedModel.value = draft.modelName;
      selectedCondition.value = draft.condition;
      selectedTransmission.value = draft.transmission;
      selectedEngineType.value = draft.engineType;

      // Year/date handling
      if (draft.year != null) {
        selectedDate.value = DateTime(
          draft.year!,
          selectedDate.value.month,
          selectedDate.value.day,
        );
        selectedYear.value = draft.year!.toString();
      }

      price.text = draft.price?.toString() ?? '';
      selectedCurrency.value = draft.currency;
      selectedLocation.value = draft.location;
      credit.value = draft.credit;
      exchange.value = draft.exchange;
      enginePower.text = draft.enginePower?.toString() ?? '';
      milleage.text = draft.milleage?.toString() ?? '';
      vinCode.text = draft.vin;
      description.text = draft.description;

      // Phone: adopt subscriber if original present
      if (_originalFullPhone.isNotEmpty) {
        final sub = PhoneUtils.extractSubscriber(_originalFullPhone);
        if (sub.length == 8) phoneController.text = sub;
        isPhoneVerified.value = true;
        isOriginalPhone.value = true;
        needsOtp.value = false;
        showOtpField.value = false;
      } else if (draft.phone.isNotEmpty) {
        phoneController.text = draft.phone; // fallback
      }

      // Images
      selectedImages.clear();
      for (final b64 in draft.imageBase64) {
        try {
          final bytes = base64Decode(b64);
          final metadata = await ImageMetadata.fromBytes(bytes);
          selectedImages.add(metadata);
        } catch (_) {}
      }
      _rebuildImageSigCache();

      // Video
      final vidPath = draft.usedCompressed
          ? draft.compressedVideoPath
          : draft.originalVideoPath;
      if (vidPath != null && vidPath.isNotEmpty) {
        final f = File(vidPath);
        if (f.existsSync()) {
          selectedVideo.value = File(draft.originalVideoPath ?? vidPath);
          if (draft.compressedVideoPath != null) {
            final cf = File(draft.compressedVideoPath!);
            if (cf.existsSync()) compressedVideoFile.value = cf;
            usedCompressedVideo.value = draft.usedCompressed;
          }
          if (draft.videoThumbnailBase64 != null) {
            try {
              videoThumbnail.value = base64Decode(draft.videoThumbnailBase64!);
            } catch (_) {}
          }
          _initializeVideoPlayer(
            usedCompressedVideo.value && compressedVideoFile.value != null
                ? compressedVideoFile.value!
                : File(draft.originalVideoPath ?? vidPath),
          );
        }
      }

      isFormSaved.value = true;
      hydratedFromStorage.value = true;
      final draftSig = draftService.computeSignature(_currentSnapshotMap());
      _lastSavedSignature = draftSig;
      isDirty.value = false;
    } catch (e) {
      Get.log('[PostController] _loadSavedForm error: $e');
    }
  }

  void clearSavedForm() {
    try {
      final draftService = Get.find<DraftService>();
      draftService.delete('active');
      isFormSaved.value = false;
      hydratedFromStorage.value = false;
      _lastSavedSignature = null;
      _recomputeDirty();
    } catch (e) {
      Get.log('[PostController] clearSavedForm error: $e');
    }
  }

  void dismissHydratedIndicator() => hydratedFromStorage.value = false;

  // Removed legacy _setUploadError after moving upload logic to UploadService.

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
    final sig = HashingUtils.computeSignature(_currentSnapshotMap());
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

  Future<void> revertToSavedSnapshot() async {
    // Simply reload the saved draft and overwrite current fields.
    await _loadSavedForm();
  }

  void _rebuildImageSigCache() {
    _imageSigCache = selectedImages.map((e) => _ImageSig(e.bytes)).toList();
  }

  // --- Brand / Model Name Resolution ---

  /// Clear all cached data - called during logout to prevent stale data
  void clearAllCachedData() {
    // Clear brand/model lookup caches
    _brandNameById.clear();
    _modelNameById.clear();
    _fetchedBrandModels.clear();

    // Clear brands and models lists
    brands.clear();
    models.clear();

    // Clear posts
    posts.clear();

    // Reset loading states
    isLoading.value = false;

    // Trigger rebuild for any observers
    modelNameResolutionTick.value++;
  }

  void _rebuildNameLookups() {
    for (final b in brands) {
      if (b.uuid.isNotEmpty && b.name.isNotEmpty) {
        _brandNameById[b.uuid] = b.name;
      }
    }
    for (final m in models) {
      if (m.uuid.isNotEmpty && m.name.isNotEmpty) {
        _modelNameById[m.uuid] = m.name;
      }
    }
  }

  String resolveBrandName(String idOrName) {
    if (idOrName.isEmpty) return '';
    // If it's already a non-UUID-ish human string, return as-is
    if (!_looksLikeUuid(idOrName)) return idOrName;
    return _brandNameById[idOrName] ??
        idOrName; // fallback to id if name unknown
  }

  String resolveModelName(String idOrName) {
    if (idOrName.isEmpty) return '';
    if (!_looksLikeUuid(idOrName)) return idOrName;
    final existing = _modelNameById[idOrName];
    if (existing != null) return existing;
    // Lazy retrieval: if models list not yet fetched fully, attempt fetch once
    _maybeFetchModels().then((_) {
      if (_modelNameById.containsKey(idOrName)) {
        modelNameResolutionTick.value++;
      }
    });
    return idOrName; // temporary fallback (UUID) until resolved
  }

  /// Resolve model when we also know its brandId: fetch that brand's model list once
  String resolveModelWithBrand(String modelId, String brandId) {
    if (modelId.isEmpty) return '';
    if (!_looksLikeUuid(modelId)) return modelId;
    final existing = _modelNameById[modelId];
    if (existing != null) return existing;
    if (brandId.isNotEmpty &&
        _looksLikeUuid(brandId) &&
        !_fetchedBrandModels.contains(brandId)) {
      _fetchedBrandModels.add(brandId);
      Future.microtask(() async {
        await _fetchBrandModelsForResolution(brandId);
        if (_modelNameById.containsKey(modelId)) {
          modelNameResolutionTick.value++;
        }
      });
    }
    return modelId;
  }

  /// Fetch models for a specific brand and add to lookup map without replacing models list
  Future<void> _fetchBrandModelsForResolution(String brandUuid) async {
    if (brandUuid.isEmpty) return;

    try {
      final token = box.read('ACCESS_TOKEN');
      final modelRepo = Get.find<IModelRepository>();
      final parsed = await modelRepo.fetchModels(brandUuid, token: token);

      // Add to lookup map WITHOUT replacing the models observable list
      for (final model in parsed) {
        if (model.uuid.isNotEmpty && model.name.isNotEmpty) {
          _modelNameById[model.uuid] = model.name;
        }
      }
    } catch (e) {
      // Silent failure for background resolution
      debugPrint('Failed to fetch models for brand $brandUuid: $e');
    }
  }

  bool _looksLikeUuid(String s) => RegExp(r'^[0-9a-fA-F-]{16,}$').hasMatch(s);

  Future<void> ensureBrandModelCachesLoaded() async {
    // If maps already populated with at least one entry, skip
    if (_brandNameById.isNotEmpty && _modelNameById.isNotEmpty) return;
    try {
      await Future.wait([_maybeFetchBrands(), _maybeFetchModels()]);
      _rebuildNameLookups();
    } catch (_) {}
  }

  Future<void> _maybeFetchBrands() async {
    if (brands.isNotEmpty) return;
    final token = box.read('ACCESS_TOKEN');
    try {
      final resp = await http.get(
        Uri.parse(ApiKey.getBrandsKey),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          final list = data
              .map(
                (e) => e is Map<String, dynamic> ? BrandDto.fromJson(e) : null,
              )
              .whereType<BrandDto>()
              .toList();
          brands.assignAll(list);
        }
      }
    } catch (_) {}
  }

  Future<void> _maybeFetchModels() async {
    if (models.isNotEmpty) return;
    final token = box.read('ACCESS_TOKEN');
    try {
      final resp = await http.get(
        Uri.parse(ApiKey.getModelsKey),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          final list = data
              .map(
                (e) => e is Map<String, dynamic> ? ModelDto.fromJson(e) : null,
              )
              .whereType<ModelDto>()
              .toList();
          models.assignAll(list);
        }
      }
    } catch (_) {}
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
