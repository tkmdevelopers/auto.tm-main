// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:auto_tm/global_controllers/connection_controller.dart';
import 'package:auto_tm/screens/profile_screen/model/profile_model.dart';
import 'package:auto_tm/services/auth/auth_service.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:auto_tm/ui_components/colors.dart';
import 'package:auto_tm/utils/key.dart';
import 'package:auto_tm/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileController extends GetxController {
  // Application-wide default location for newly registered users
  static const String defaultLocation = 'Aşgabat';

  /// Singleton accessor to avoid accidental duplicate Get.put() calls scattered in UI.
  static ProfileController ensure() {
    if (Get.isRegistered<ProfileController>()) {
      return Get.find<ProfileController>();
    }
    // Should normally be registered in initServices(). Log if late-bound.
    AppLogger.w(
      'ProfileController.ensure() late registration - verify global init.',
    );
    return Get.put(ProfileController(), permanent: true);
  }

  final box = GetStorage();
  var selectedImage = Rx<Uint8List?>(null);
  // final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  // final FocusNode phoneFocus = FocusNode();
  final FocusNode nameFocus = FocusNode();
  final FocusNode locationFocus = FocusNode();
  var name = ''.obs;
  var phone = ''.obs;
  var location = ''.obs;

  var isLoading = false.obs;
  var isLoadingN = false.obs;
  // New: lightweight refresh indicator for background/secondary refreshes
  final RxBool isRefreshing =
      false.obs; // use instead of full-screen spinner for non-initial pulls
  final RxBool isOffline = false.obs;

  late final ConnectionController _connectionController;

  var profile = Rxn<ProfileModel>();

  // Tracks whether we've already initialized the form field controllers with existing data
  final RxBool fieldsInitialized = false.obs;

  // Guard flags to prevent duplicate concurrent / repeated fetches
  final RxBool isFetchingProfile =
      false.obs; // true while fetchProfile in-flight
  final RxBool hasLoadedProfile =
      false.obs; // set true after first successful load
  // Completer to signal the first fetch completion (success, failure, or timeout)
  Completer<void>? _initialLoadCompleter;

  /// Debug hook: logs current state flags; safe to leave in production (low cost).
  void debugDumpFlags(String label) {
    final msg =
        '[ProfileDebug][$label] isLoading=${isLoading.value} hasLoaded=${hasLoadedProfile.value} '
        'isFetching=${isFetchingProfile.value} isRefreshing=${isRefreshing.value} selectedImage=${selectedImage.value != null}';
    AppLogger.d(msg);
    // Mirror to print for guaranteed visibility in raw logcat dumps.
    // ignore: avoid_print
    print(msg);
  }

  @override
  void onInit() {
    super.onInit();
    _connectionController = Get.isRegistered<ConnectionController>()
        ? Get.find<ConnectionController>()
        : Get.put(ConnectionController(), permanent: true);
    isOffline.value = !_connectionController.hasConnection.value;
    ever<bool>(_connectionController.hasConnection, (hasConnection) {
      isOffline.value = !hasConnection;
    });
    // Load initial values from local storage as fallback
    name.value = box.read('user_name') ?? '';
    phone.value = box.read('user_phone') ?? '993';
    location.value = box.read('user_location') ?? '';
    if (location.value.isEmpty) {
      // Apply default if nothing stored yet
      location.value = defaultLocation;
      box.write('user_location', defaultLocation);
    }
    locationController.text = location.value;

    // Attempt to restore cached profile immediately for offline UX
    _restoreCachedProfile();

    // Test API configuration
    testApiConnection();

    // Fetch fresh data from backend
    fetchProfile();

    // Late-arrival profile listener: if profile loads after screen build and fields not initialized, prefill.
    ever<ProfileModel?>(profile, (p) {
      if (p != null &&
          (!fieldsInitialized.value || nameController.text.isEmpty)) {
        ensureFormFieldPrefill(force: true);
      }
    });

    // Add listeners to update text controllers when reactive values change
    name.listen((value) {
      if (nameController.text != value) {
        nameController.text = value;
      }
    });

    location.listen((value) {
      if (locationController.text != value) {
        locationController.text = value;
      }
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    locationController.dispose();
    nameFocus.dispose();
    locationFocus.dispose();
    super.onClose();
  }

  Future<void> testApiConnection() async {
    AppLogger.i('=== API Configuration Test ===');
    AppLogger.d('API Base URL: ${ApiKey.ip}');
    AppLogger.d('API Key: ${ApiKey.apiKey}');
    AppLogger.d('Get Profile Key: ${ApiKey.getProfileKey}');

    final accessToken = await TokenStore.to.accessToken;
    AppLogger.d('Access Token exists: ${accessToken != null}');
    if (accessToken != null && accessToken.isNotEmpty) {
      AppLogger.d('Access Token preview: ${accessToken.substring(0, 20)}...');
    }

    AppLogger.i('=== End API Configuration Test ===');
  }

  Future<void> testJsonParsing(String jsonString) async {
    try {
      AppLogger.d('=== Testing JSON Parsing ===');
      AppLogger.d('JSON string: $jsonString');

      final data = json.decode(jsonString);
      AppLogger.d('Decoded JSON: $data');

      final profile = ProfileModel.fromJson(data);
      AppLogger.d('Successfully created ProfileModel: ${profile.name}');

      AppLogger.d('=== End JSON Parsing Test ===');
    } catch (e, st) {
      AppLogger.e('JSON parsing error', error: e, stackTrace: st);
      AppLogger.d('=== End JSON Parsing Test with Error ===');
    }
  }

  Future<void> fetchProfile({bool retry = false}) async {
    debugDumpFlags('fetchProfile:enter');
    // Prevent overlapping calls
    if (isFetchingProfile.value) {
      AppLogger.d(
        'fetchProfile: early exit because isFetchingProfile already true',
      );
      debugDumpFlags('fetchProfile:early-exit-overlap');
      return;
    }
    isFetchingProfile.value = true;
    // Initialize completer for the very first attempt
    _initialLoadCompleter ??= Completer<void>();
    // Show big spinner only for first load; later loads use subtle refresh flag
    if (!hasLoadedProfile.value) {
      isLoading.value = true;
      // Watchdog: ensure we don't keep big spinner forever if backend stalls
      _scheduleInitialLoadWatchdog();
    } else {
      isRefreshing.value = true;
    }

    try {
      // Check if access token exists
      final hasTokens = await TokenStore.to.hasTokens;
      if (!hasTokens) {
        AppLogger.w('fetchProfile: No access token found');
        Get.snackbar(
          'Error',
          'No access token found. Please log in again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return _earlyReturnCleanup('no_token');
      }

      // Check if API URL is properly configured
      AppLogger.d('API Base URL: ${ApiKey.ip}');
      AppLogger.d('API Key: ${ApiKey.apiKey}');
      AppLogger.d('Get Profile Key: ${ApiKey.getProfileKey}');

      if (ApiKey.ip.isEmpty || ApiKey.ip == 'null') {
        AppLogger.w(
          'fetchProfile: API base URL is not configured properly (ApiKey.ip = ${ApiKey.ip})',
        );
        Get.snackbar(
          'Error',
          'API configuration error. Please check environment variables.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return _earlyReturnCleanup('bad_api_url');
      }

      if (!_connectionController.hasConnection.value) {
        AppLogger.w('fetchProfile: no connection detected, using cache');
        isOffline.value = true;
        _restoreCachedProfile();
        return _earlyReturnCleanup('no_connection');
      }

      AppLogger.i('Fetching profile from: auth/me');

      final response = await ApiClient.to.dio
          .get('auth/me')
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () {
              throw TimeoutException('Profile request timed out');
            },
          );

      AppLogger.d('Response status code: ${response.statusCode}');
      AppLogger.d('Response body: ${response.data}');

      if (response.statusCode == 200) {
        try {
          if (response.data == null) {
            AppLogger.w('fetchProfile: Empty response body received');
            Get.snackbar(
              'Error',
              'Empty response from server',
              snackPosition: SnackPosition.BOTTOM,
            );
            return _earlyReturnCleanup('empty_body');
          }

          final dynamic raw = response.data;
          final Map<String, dynamic> data = raw is String
              ? Map<String, dynamic>.from(json.decode(raw))
              : Map<String, dynamic>.from(raw as Map);

          AppLogger.d('Parsed JSON data: $data');

          profile.value = ProfileModel.fromJson(data);
          box.write('USER_ID', data['uuid']);
          phone.value = data['phone']?.toString() ?? '';
          box.write('cached_profile_json', json.encode(data));
          isOffline.value = false;

          AppLogger.i('Profile fetched successfully: ${profile.value?.name}');
          hasLoadedProfile.value = true;
          // If we flipped hasLoadedProfile within this fetch, ensure loading spinner will be cleared.
          if (isLoading.value) {
            AppLogger.d(
              'fetchProfile: marking initial load complete, will clear spinner in finally',
            );
          }
        } catch (parseError, st) {
          AppLogger.e(
            'Error parsing JSON response',
            error: parseError,
            stackTrace: st,
          );
          AppLogger.d('Response body that failed to parse: ${response.data}');
          Get.snackbar(
            'Error',
            'Failed to parse profile data: $parseError',
            snackPosition: SnackPosition.BOTTOM,
          );
          // parsing error should still resolve initial load so UI can present fallback
        }
      } else {
        AppLogger.w('Unexpected status code: ${response.statusCode}');
        Get.snackbar(
          'Error',
          'Failed to fetch profile. Status: ${response.statusCode}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on TimeoutException catch (e) {
      AppLogger.w('Profile fetch timeout: $e');
      Get.snackbar(
        'Timeout',
        'Profile request took too long. Pull to retry.',
        snackPosition: SnackPosition.BOTTOM,
      );
      isOffline.value = true;
      _restoreCachedProfile();
    } on DioException catch (e) {
      AppLogger.e('Error fetching profile (Dio)', error: e);
      isOffline.value = true;
      _restoreCachedProfile();
    } catch (e) {
      AppLogger.e('Error fetching profile', error: e);
      Get.snackbar(
        'Error',
        'Failed to fetch profile: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      isOffline.value = true;
      _restoreCachedProfile();
    } finally {
      AppLogger.d(
        'fetchProfile: finalizing. hasLoaded=${hasLoadedProfile.value} isLoading=${isLoading.value} isRefreshing=${isRefreshing.value} isFetching=${isFetchingProfile.value}',
      );
      debugDumpFlags('fetchProfile:finally-before-reset');
      // Always clear big spinner at end of any fetch cycle (initial or otherwise) if it is still true.
      if (isLoading.value) {
        isLoading.value = false;
      }
      isRefreshing.value = false;
      isFetchingProfile.value = false;
      if (_initialLoadCompleter != null &&
          !_initialLoadCompleter!.isCompleted) {
        _initialLoadCompleter!.complete();
      }
      debugDumpFlags('fetchProfile:finally-after-reset');
    }
  }

  /// Centralized early-return cleanup to ensure flags and completer are resolved
  void _earlyReturnCleanup(String reason) {
    AppLogger.d(
      'fetchProfile: early return cleanup (reason=$reason) hasLoaded=${hasLoadedProfile.value}',
    );
    debugDumpFlags('fetchProfile:earlyReturn-$reason:before-reset');
    // Clear spinner regardless; we are aborting this cycle.
    if (isLoading.value) isLoading.value = false;
    isRefreshing.value = false;
    isFetchingProfile.value = false;
    if (_initialLoadCompleter != null && !_initialLoadCompleter!.isCompleted) {
      _initialLoadCompleter!.complete();
    }
    debugDumpFlags('fetchProfile:earlyReturn-$reason:after-reset');
  }

  /// Schedule a one-time watchdog to release the initial loading spinner
  /// if the first profile fetch does not complete within [timeout]. This
  /// prevents the edit profile screen from being stuck indefinitely.
  void _scheduleInitialLoadWatchdog({
    Duration timeout = const Duration(seconds: 8),
  }) {
    if (hasLoadedProfile.value) return; // already loaded
    // Only schedule if this is the first creation of the completer (initial load scenario)
    Future.delayed(timeout, () {
      if (!hasLoadedProfile.value && isLoading.value) {
        AppLogger.w(
          'Initial profile load exceeded ${timeout.inSeconds}s; releasing spinner for manual entry',
        );
        isLoading.value = false;
        if (_initialLoadCompleter != null &&
            !_initialLoadCompleter!.isCompleted) {
          _initialLoadCompleter!.complete();
        }
      }
    });
  }

  /// Wait until the first profile load attempt finishes (success or failure),
  /// or until [timeout] elapses. This prevents racing navigation logic that
  /// queries profile fields before the initial network call completes.
  Future<void> waitForInitialLoad({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (hasLoadedProfile.value) return; // already loaded
    // If no fetch in flight yet, nothing to wait on
    if (_initialLoadCompleter == null) return;
    try {
      await _initialLoadCompleter!.future.timeout(timeout, onTimeout: () {});
    } catch (_) {}
  }

  Future<void> fetchProfileAndPopulateFields() async {
    await fetchProfile();

    // Populate form fields with fetched data
    if (profile.value != null) {
      final profileData = profile.value!;

      // Set name if it exists
      if (profileData.name.isNotEmpty) {
        name.value = profileData.name;
        nameController.text = profileData.name;
      }

      // Set location if it exists
      if (profileData.location != null && profileData.location!.isNotEmpty) {
        location.value = profileData.location!;
        locationController.text = profileData.location!;
      } else {
        // Backend returned empty / null location, enforce default
        if (location.value.isEmpty) {
          location.value = defaultLocation;
          locationController.text = defaultLocation;
          box.write('user_location', defaultLocation);
        }
      }

      // Set phone if it exists
      if (profileData.phone.isNotEmpty) {
        phone.value = profileData.phone;
      }

      // Save to local storage
      box.write('user_name', profileData.name);
      if (profileData.location != null) {
        box.write('user_location', profileData.location);
      }
      box.write('user_phone', profileData.phone);
    }
  }

  /// Restore profile from cached JSON stored in GetStorage.
  /// Returns true if a valid cached profile was loaded.
  bool _restoreCachedProfile() {
    final cached = box.read('cached_profile_json');
    if (cached == null || cached is! String || cached.isEmpty) {
      return false;
    }
    try {
      final data = json.decode(cached);
      if (data is! Map) return false;

      profile.value = ProfileModel.fromJson(Map<String, dynamic>.from(data));
      hasLoadedProfile.value = true;
      name.value = profile.value?.name ?? name.value;
      phone.value = profile.value?.phone ?? phone.value;
      final restoredLocation = profile.value?.location ?? location.value;
      location.value = restoredLocation.isNotEmpty
          ? restoredLocation
          : defaultLocation;
      locationController.text = location.value;

      if (name.value.isNotEmpty) {
        box.write('user_name', name.value);
      }
      if (phone.value.isNotEmpty) {
        box.write('user_phone', phone.value);
      }
      if (location.value.isNotEmpty) {
        box.write('user_location', location.value);
      }
      return true;
    } catch (e, st) {
      AppLogger.w('Failed to restore cached profile', error: e, stackTrace: st);
      return false;
    }
  }

  /// Ensure form text controllers are prefilled with the latest known values.
  /// This is idempotent and will only run once per screen lifecycle unless
  /// [force] is true. It prefers freshly fetched profile data, then reactive
  /// fallback values, then persistent storage.
  void ensureFormFieldPrefill({bool force = false}) {
    if (fieldsInitialized.value && !force) return;

    // Resolve best-known name
    String existingName = '';
    if (profile.value?.name.isNotEmpty == true) {
      existingName = profile.value!.name;
    } else if (name.value.isNotEmpty) {
      existingName = name.value;
    } else {
      existingName = box.read('user_name') ?? '';
    }

    // Resolve best-known location
    String existingLocation = '';
    if (profile.value?.location != null &&
        profile.value!.location!.isNotEmpty) {
      existingLocation = profile.value!.location!;
    } else if (location.value.isNotEmpty) {
      existingLocation = location.value;
    } else {
      existingLocation = box.read('user_location') ?? '';
      if (existingLocation.isEmpty) {
        existingLocation = defaultLocation;
        box.write('user_location', defaultLocation);
      }
    }

    bool applied = false;
    if (existingName.isNotEmpty && nameController.text.isEmpty) {
      nameController.text = existingName;
      applied = true;
    }
    if (existingLocation.isNotEmpty && locationController.text.isEmpty) {
      locationController.text = existingLocation;
      applied = true;
    }

    // Only mark initialized if we actually set something, unless forced
    if (applied || force) {
      fieldsInitialized.value = true;
    }
  }

  Future<bool> requestGalleryPermission() async {
    var status = await Permission.photos.request(); // For iOS
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      ("Permission Denied", "Allow access to select images");
      return false;
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    return false;
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      selectedImage.value = await image.readAsBytes();
      // Preserve existing name/location; no mutation besides image preview.
    }
  }

  Future<void> uploadImage(Uint8List imageBytes) async {
    final accessToken = await TokenStore.to.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      AppLogger.w('uploadImage: No access token found');
      return;
    }
    final uri = Uri.parse(ApiKey.putUserPhotoKey); // Replace with your API URL

    final request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..fields['uuid'] = profile
          .value!
          .uuid // Attach UUID
      ..files.add(
        http.MultipartFile.fromBytes(
          'file', // field name expected by backend
          imageBytes,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

    final response = await request.send();
    String? bodyString;
    Map<String, dynamic>? jsonBody;
    try {
      bodyString = await response.stream.bytesToString();
      if (bodyString.isNotEmpty) {
        jsonBody = json.decode(bodyString);
      }
    } catch (_) {}

    if (response.statusCode == 200 && jsonBody != null) {
      final paths = jsonBody['paths'];
      String? chosen;
      if (paths is Map) {
        chosen =
            paths['medium']?.toString() ??
            paths['large']?.toString() ??
            paths['small']?.toString();
      }
      if (chosen != null && chosen.isNotEmpty) {
        final current = profile.value;
        if (current != null) {
          profile.value = ProfileModel(
            uuid: current.uuid,
            name: current.name,
            email: current.email,
            phone: current.phone,
            location: current.location,
            avatar: chosen,
            createdAt: current.createdAt,
            brandUuid: current.brandUuid,
          );
        }
      }
    }
    // Auth errors (401/406) are now handled by ApiClient interceptor for Dio calls.
  }

  Future<void> uploadProfile() async {
    final success = await postUserDataSave();

    if (!success) return; // If not successful, stop here

    if (selectedImage.value != null) {
      await uploadImage(selectedImage.value!);
      // Clear local picked image so a new session/account won't inherit it
      selectedImage.value = null;
    }

    // No full refetch: merge locally then optionally fire a silent refresh (non-blocking)
    _mergeLocalProfileAfterEdit();
    // Fire a silent background refresh without blocking navigation
    Future.microtask(() => fetchProfile());

    // Navigate back to the profile screen (stay in profile context)
    if (Get.currentRoute != '/profile') {
      Get.back();
    }
    Get.rawSnackbar(
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.whiteColor,
      borderRadius: 12,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      duration: const Duration(milliseconds: 1800),
      animationDuration: const Duration(milliseconds: 250),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
      messageText: Row(
        children: const [
          Icon(Icons.check_circle_outline, color: AppColors.notificationColor),
          SizedBox(width: 8),
          Text(
            'Profile edited successfully!',
            style: TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // void postUserData(String key, String value) async {
  //   try {
  //     final Map<String, dynamic> body = {
  //     key: value,
  //   };
  //     final response = await http.put(
  //       Uri.parse(ApiKey.setPasswordKey),
  //       headers: {
  //         // "Accept": "application/json",
  //         "Content-Type": "application/json",
  //         'Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}'
  //       },
  //       body: json.encode(body),
  //     );
  //     if (response.statusCode == 200) {
  //       fetchProfile();
  //     }
  //   } catch (e) {
  //     print("Error fetching data: $e");
  //   } finally {
  //     isLoadingN.value = false;
  //   }
  // }

  Future<bool> postUserDataSave() async {
    try {
      final accessToken = await TokenStore.to.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        AppLogger.w('postUserDataSave: No access token found');
        return false;
      }
      final trimmedName = nameController.text.trim();
      final Map<String, dynamic> body = {
        if (trimmedName.isNotEmpty) 'name': trimmedName,
        'location': locationController.text,
      };

      final response = await http.put(
        Uri.parse(ApiKey.setPasswordKey),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(body),
      );

      // final resBody = json.decode(response.body);

      if (response.statusCode == 200) {
        if ((body['name'] ?? '').toString().isNotEmpty) {
          box.write('user_name', body['name']);
        }
        box.write('user_location', locationController.text);
        return true; // local merge will happen in uploadProfile
      }

      if (response.statusCode == 401) {
        // Session expired — redirect to login
        return false;
      }

      return false;
    } catch (e) {
      return false;
    } finally {
      isLoadingN.value = false;
    }
  }

  // Token refresh is now handled by the Dio ApiClient interceptor.
  // The duplicated refreshAccessToken() method has been removed.
  // See: lib/services/network/api_client.dart

  /// Merge current edited fields into existing profile model without waiting for network.
  void _mergeLocalProfileAfterEdit() {
    final current = profile.value;
    final enteredName = nameController.text.trim();
    final preservedName = enteredName.isNotEmpty
        ? enteredName
        : (current?.name.isNotEmpty == true
              ? current!.name
              : (name.value.isNotEmpty
                    ? name.value
                    : (box.read('user_name') ?? '')));
    if (current == null) {
      profile.value = ProfileModel(
        uuid: box.read('USER_ID') ?? '',
        name: preservedName,
        email: '',
        phone: phone.value,
        location: locationController.text.isEmpty
            ? null
            : locationController.text,
        avatar: null,
        createdAt: DateTime.now(),
        brandUuid: const [],
      );
    } else {
      profile.value = ProfileModel(
        uuid: current.uuid,
        name: preservedName,
        email: current.email,
        phone: current.phone,
        location: locationController.text.isEmpty
            ? null
            : locationController.text,
        avatar: current.avatar,
        createdAt: current.createdAt,
        brandUuid: current.brandUuid,
      );
    }
    name.value = preservedName;
    if (preservedName.isNotEmpty) {
      box.write('user_name', preservedName);
    }
    location.value = locationController.text;
    // Mark as loaded since we now have locally merged profile data
    hasLoadedProfile.value = true;
  }

  void logout() {
    // Use central auth service logout to ensure consistent cleanup
    if (Get.isRegistered<AuthService>()) {
      AuthService.to.logout();
    } else {
      // Fallback selective removal if auth service not yet initialized
      box.remove('ACCESS_TOKEN');
      box.remove('REFRESH_TOKEN');
      box.remove('USER_PHONE');
      box.remove('user_name');
      box.remove('user_phone');
      box.remove('user_location');
      box.remove('USER_ID');
      box.remove('cached_profile_json');
    }
    // Clear local reactive state
    profile.value = null;
    name.value = '';
    phone.value = '';
    location.value = defaultLocation;
    nameController.clear();
    locationController.text = defaultLocation;
    selectedImage.value =
        null; // ensure previous avatar bytes aren't shown for next user
    fieldsInitialized.value = false;
    hasLoadedProfile.value = false;
    isOffline.value = false;
    // Navigate to login (or splash) route; adjust if different
    Get.offAllNamed('/login');
  }

  // void showBottomSheet(
  //     String title, List<Map<String, dynamic>> options, RxString selectedValue, void Function() onTap) {
  //   Get.bottomSheet(
  //     Container(
  //       padding: EdgeInsets.all(16),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //       ),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text(title,
  //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //           Divider(),
  //           ...options.map((language) {

  //           return ListTile(
  //                 title: Text(language['name']),
  //                 onTap: onTap,
  //               );
  //           }).toList(),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
