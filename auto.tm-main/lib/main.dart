import 'package:auto_tm/app.dart';
import 'package:auto_tm/firebase_options.dart';
import 'package:auto_tm/global_controllers/connection_controller.dart';
import 'package:auto_tm/global_controllers/download_controller.dart';
import 'package:auto_tm/global_controllers/theme_controller.dart';
import 'package:auto_tm/navbar/navbar.dart';
import 'package:auto_tm/screens/auth_screens/register_screen/otp_screen.dart';
import 'package:auto_tm/screens/auth_screens/register_screen/register_screen.dart';
import 'package:auto_tm/screens/filter_screen/filter_screen.dart';
import 'package:auto_tm/screens/home_screen/home_screen.dart';
import 'package:auto_tm/screens/profile_screen/profile_screen.dart';
import 'package:auto_tm/screens/profile_screen/controller/profile_controller.dart';
import 'package:auto_tm/screens/filter_screen/controller/filter_controller.dart';
import 'package:auto_tm/screens/home_screen/controller/home_controller.dart';
import 'package:auto_tm/screens/search_screen/search_screen.dart';
import 'package:auto_tm/screens/post_screen/controller/upload_manager.dart';
import 'package:auto_tm/screens/post_screen/controller/post_controller.dart';
import 'package:auto_tm/screens/splash_screen/custom_splash_screen.dart';
import 'package:auto_tm/services/notification_sevice/notification_service.dart';
import 'package:auto_tm/services/auth/auth_service.dart';
import 'package:auto_tm/services/blog_service.dart'; // Added BlogService import
import 'package:auto_tm/services/subscription_service.dart';
import 'package:auto_tm/services/brand_history_service.dart';
import 'package:auto_tm/services/post_service.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/utils/themes.dart';
import 'package:auto_tm/utils/translation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'utils/cache_cleaner.dart';
import 'utils/logger.dart';
import 'dart:io';
import 'dart:convert';

void _logDebug(String location, String message, Map<String, dynamic> data, {String? hypothesisId}) {
  try {
    final logFile = File('/Users/bagtyyar/Projects/auto.tm-main/.cursor/debug.log');
    final logEntry = {
      'id': 'log_${DateTime.now().millisecondsSinceEpoch}_${location.replaceAll(':', '_')}',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': location,
      'message': message,
      'data': data,
      'sessionId': 'debug-session',
      'runId': 'run1',
      if (hypothesisId != null) 'hypothesisId': hypothesisId,
    };
    logFile.writeAsStringSync('${jsonEncode(logEntry)}\n', mode: FileMode.append);
  } catch (e) {
    // Silently fail if logging fails
  }
}

void main() async {
  // Wrap entire main in try-catch to catch any unhandled exceptions
  try {
    // #region agent log
    _logDebug('main.dart:54', 'main() started', {}, hypothesisId: 'A');
    // #endregion
    
    // --- Ensure all bindings are initialized before running the app ---
    WidgetsFlutterBinding.ensureInitialized();
  
  // #region agent log
  _logDebug('main.dart:36', 'WidgetsFlutterBinding initialized', {}, hypothesisId: 'A');
  // #endregion

  // --- Initialize core services and packages ---
  try {
    await GetStorage.init();
    // #region agent log
    _logDebug('main.dart:40', 'GetStorage.init() completed', {}, hypothesisId: 'A');
    // #endregion
  } catch (e) {
    // #region agent log
    _logDebug('main.dart:42', 'GetStorage.init() failed', {'error': e.toString()}, hypothesisId: 'A');
    // #endregion
    rethrow;
  }
  
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // #region agent log
    _logDebug('main.dart:48', 'Firebase.initializeApp() completed', {}, hypothesisId: 'A');
    // #endregion
  } catch (e) {
    // #region agent log
    _logDebug('main.dart:50', 'Firebase.initializeApp() failed', {'error': e.toString(), 'errorType': e.runtimeType.toString()}, hypothesisId: 'A');
    // #endregion
    rethrow;
  }
  
  // #region agent log
  _logDebug('main.dart:91', 'FlutterDownloader will be lazy-initialized when needed', {}, hypothesisId: 'A');
  // #endregion
  
  // FlutterDownloader is now lazy-initialized in DownloadController only when user tries to download
  // This prevents iOS crashes during app startup. The download feature will initialize
  // automatically when the user clicks "Download car diagnostics" button.
  
  // #region agent log
  _logDebug('main.dart:107', 'About to load .env file', {}, hypothesisId: 'A');
  // #endregion
  
  try {
    await dotenv.load(fileName: ".env");
    // #region agent log
    _logDebug('main.dart:112', 'dotenv.load() completed', {'apiBase': dotenv.env['API_BASE'] ?? 'not found'}, hypothesisId: 'A');
    // #endregion
  } catch (e, stackTrace) {
    // #region agent log
    _logDebug('main.dart:116', 'dotenv.load() failed (non-fatal)', {'error': e.toString(), 'errorType': e.runtimeType.toString(), 'stackTrace': stackTrace.toString()}, hypothesisId: 'A');
    // #endregion
    AppLogger.w(
      'Warning: .env file not found. Using default configuration.',
      error: e,
    );
  }
  
  // #region agent log
  _logDebug('main.dart:125', 'About to call initServices()', {}, hypothesisId: 'B');
  // #endregion

  // --- Initialize your app's services and global controllers ---
  try {
    await initServices();
    // #region agent log
    _logDebug('main.dart:131', 'initServices() completed', {}, hypothesisId: 'B');
    // #endregion
  } catch (e, stackTrace) {
    // #region agent log
    _logDebug('main.dart:135', 'initServices() failed', {'error': e.toString(), 'errorType': e.runtimeType.toString(), 'stackTrace': stackTrace.toString()}, hypothesisId: 'B');
    // #endregion
    rethrow;
  }
  
  // --- Set preferred screen orientation for the whole app ---
  try {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // #region agent log
    _logDebug('main.dart:147', 'SystemChrome.setPreferredOrientations() completed', {}, hypothesisId: 'A');
    // #endregion
  } catch (e) {
    // #region agent log
    _logDebug('main.dart:151', 'SystemChrome.setPreferredOrientations() failed', {'error': e.toString()}, hypothesisId: 'A');
    // #endregion
  }

  // --- Request necessary permissions on startup ---
  try {
    await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
      Permission.notification,
    ].request();
    // #region agent log
    _logDebug('main.dart:161', 'Permission.request() completed', {}, hypothesisId: 'A');
    // #endregion
  } catch (e) {
    // #region agent log
    _logDebug('main.dart:165', 'Permission.request() failed', {'error': e.toString()}, hypothesisId: 'A');
    // #endregion
  }

  // Schedule non-blocking cache maintenance
  Future.microtask(() => AppCacheCleaner().autoPruneIfNeeded());

  // #region agent log
  _logDebug('main.dart:173', 'About to call runApp()', {}, hypothesisId: 'G');
  // #endregion
  
  try {
    runApp(AlphaMotorsApp());
    // #region agent log
    _logDebug('main.dart:177', 'runApp() called successfully', {}, hypothesisId: 'G');
    // #endregion
  } catch (e, stackTrace) {
    // #region agent log
    _logDebug('main.dart:181', 'runApp() failed', {'error': e.toString(), 'errorType': e.runtimeType.toString(), 'stackTrace': stackTrace.toString()}, hypothesisId: 'G');
    // #endregion
    rethrow;
  }
  } catch (e, stackTrace) {
    // Top-level error handler to catch any unhandled exceptions
    // #region agent log
    _logDebug('main.dart:187', 'main() top-level exception caught', {'error': e.toString(), 'errorType': e.runtimeType.toString(), 'stackTrace': stackTrace.toString()}, hypothesisId: 'A');
    // #endregion
    // Re-throw to let Flutter handle it, but at least we logged it
    rethrow;
  }
}

/// Centralized function to initialize all your global services and controllers.
Future<void> initServices() async {
  try {
    Get.put(
      ThemeController(),
    ); // ThemeController is global, so it's initialized here.
    // #region agent log
    _logDebug('main.dart:initServices:76', 'ThemeController registered', {}, hypothesisId: 'B');
    // #endregion
  } catch (e) {
    // #region agent log
    _logDebug('main.dart:initServices:79', 'ThemeController registration failed', {'error': e.toString()}, hypothesisId: 'B');
    // #endregion
    rethrow;
  }
  
  try {
    Get.put(ConnectionController());
    // #region agent log
    _logDebug('main.dart:initServices:85', 'ConnectionController registered', {}, hypothesisId: 'B');
    // #endregion
  } catch (e) {
    // #region agent log
    _logDebug('main.dart:initServices:88', 'ConnectionController registration failed', {'error': e.toString()}, hypothesisId: 'B');
    // #endregion
    rethrow;
  }
  
  try {
    Get.put(DownloadController());
    // #region agent log
    _logDebug('main.dart:initServices:94', 'DownloadController registered', {}, hypothesisId: 'B');
    // #endregion
  } catch (e) {
    // #region agent log
    _logDebug('main.dart:initServices:97', 'DownloadController registration failed', {'error': e.toString()}, hypothesisId: 'B');
    // #endregion
    rethrow;
  }
  
  // Register UploadManager early so background progress / locks are available app-wide.
  if (!Get.isRegistered<UploadManager>()) {
    try {
      await Get.putAsync(() async => await UploadManager().init());
      // #region agent log
      _logDebug('main.dart:initServices:105', 'UploadManager.init() completed', {}, hypothesisId: 'C');
      // #endregion
    } catch (e, stackTrace) {
      // #region agent log
      _logDebug('main.dart:initServices:108', 'UploadManager.init() failed', {'error': e.toString(), 'errorType': e.runtimeType.toString(), 'stackTrace': stackTrace.toString()}, hypothesisId: 'C');
      // #endregion
      rethrow;
    }
  }
  
  // Lazily register PostController so any route (like UploadProgressScreen) can resolve it.
  if (!Get.isRegistered<PostController>()) {
    try {
      Get.lazyPut(() => PostController(), fenix: true);
      // #region agent log
      _logDebug('main.dart:initServices:117', 'PostController lazyPut completed', {}, hypothesisId: 'B');
      // #endregion
    } catch (e) {
      // #region agent log
      _logDebug('main.dart:initServices:120', 'PostController lazyPut failed', {'error': e.toString()}, hypothesisId: 'B');
      // #endregion
      rethrow;
    }
  }
  
  // Register TokenStore (secure token persistence). Must come before ApiClient and AuthService.
  if (!Get.isRegistered<TokenStore>()) {
    Get.put(TokenStore(), permanent: true);
  }

  // Register ApiClient (Dio + auth interceptor). Must come before AuthService.
  if (!Get.isRegistered<ApiClient>()) {
    await Get.putAsync(() async => await ApiClient().init());
  }

  // Register AuthService (phone OTP + session). Must come after TokenStore and ApiClient.
  if (!Get.isRegistered<AuthService>()) {
    try {
      Get.put(AuthService()); // AuthService uses default constructor
      // #region agent log
      _logDebug('main.dart:initServices:129', 'AuthService registered', {}, hypothesisId: 'D');
      // #endregion
    } catch (e, stackTrace) {
      // #region agent log
      _logDebug('main.dart:initServices:132', 'AuthService registration failed', {'error': e.toString(), 'errorType': e.runtimeType.toString(), 'stackTrace': stackTrace.toString()}, hypothesisId: 'D');
      // #endregion
      rethrow;
    }
  }

  // Register BlogService
  if (!Get.isRegistered<BlogService>()) {
    try {
      Get.put(BlogService(Get.find<ApiClient>())); // Added BlogService registration
      // #region agent log
      _logDebug('main.dart:initServices:XXX', 'BlogService registered', {}, hypothesisId: 'X');
      // #endregion
    } catch (e, stackTrace) {
      // #region agent log
      _logDebug('main.dart:initServices:XXX', 'BlogService registration failed', {'error': e.toString(), 'errorType': e.runtimeType.toString(), 'stackTrace': stackTrace.toString()}, hypothesisId: 'X');
      // #endregion
      rethrow;
    }
  }

  // Register SubscriptionService
  if (!Get.isRegistered<SubscriptionService>()) {
    Get.put(SubscriptionService(Get.find<ApiClient>()));
  }

  // Register BrandHistoryService
  if (!Get.isRegistered<BrandHistoryService>()) {
    Get.put(BrandHistoryService(Get.find<ApiClient>()));
  }

  // Register PostService
  if (!Get.isRegistered<PostService>()) {
    Get.put(PostService(Get.find<ApiClient>()));
  }

  
  try {
    await Get.putAsync(() async => NotificationService()..init());
    // #region agent log
    _logDebug('main.dart:initServices:139', 'NotificationService.init() completed', {}, hypothesisId: 'E');
    // #endregion
  } catch (e, stackTrace) {
    // #region agent log
    _logDebug('main.dart:initServices:142', 'NotificationService.init() failed', {'error': e.toString(), 'errorType': e.runtimeType.toString(), 'stackTrace': stackTrace.toString()}, hypothesisId: 'E');
    // #endregion
    rethrow;
  }
  
  // Register ProfileController globally so UI never creates duplicates.
  if (!Get.isRegistered<ProfileController>()) {
    try {
      Get.put(ProfileController(), permanent: true);
      // #region agent log
      _logDebug('main.dart:initServices:151', 'ProfileController registered', {}, hypothesisId: 'F');
      // #endregion
    } catch (e, stackTrace) {
      // #region agent log
      _logDebug('main.dart:initServices:154', 'ProfileController registration failed', {'error': e.toString(), 'errorType': e.runtimeType.toString(), 'stackTrace': stackTrace.toString()}, hypothesisId: 'F');
      // #endregion
      rethrow;
    }
  }
  
  if (!Get.isRegistered<FilterController>()) {
    try {
      Get.put(FilterController(), permanent: true);
      // #region agent log
      _logDebug('main.dart:initServices:163', 'FilterController registered', {}, hypothesisId: 'F');
      // #endregion
    } catch (e, stackTrace) {
      // #region agent log
      _logDebug('main.dart:initServices:166', 'FilterController registration failed', {'error': e.toString(), 'errorType': e.runtimeType.toString(), 'stackTrace': stackTrace.toString()}, hypothesisId: 'F');
      // #endregion
      rethrow;
    }
  }

  // Register HomeController before nav so HomeScreen can Get.find when pages list is built.
  if (!Get.isRegistered<HomeController>()) {
    try {
      Get.put(HomeController(), permanent: true);
    } catch (e, stackTrace) {
      _logDebug('main.dart:initServices', 'HomeController registration failed', {'error': e.toString(), 'stackTrace': stackTrace.toString()}, hypothesisId: 'F');
      rethrow;
    }
  }
}

class AlphaMotorsApp extends StatelessWidget {
  AlphaMotorsApp({super.key}) {
    // #region agent log
    _logDebug('main.dart:AlphaMotorsApp:216', 'AlphaMotorsApp constructor started', {}, hypothesisId: 'G');
    // #endregion
    try {
      // Use Get.find() to locate already initialized controllers, not Get.put().
      themeController = Get.find<ThemeController>();
      // #region agent log
      _logDebug('main.dart:AlphaMotorsApp:220', 'ThemeController found', {}, hypothesisId: 'G');
      // #endregion
    } catch (e) {
      // #region agent log
      _logDebug('main.dart:AlphaMotorsApp:223', 'ThemeController Get.find() failed', {'error': e.toString()}, hypothesisId: 'G');
      // #endregion
      rethrow;
    }
    try {
      notificationService = Get.find<NotificationService>();
      // #region agent log
      _logDebug('main.dart:AlphaMotorsApp:229', 'NotificationService found', {}, hypothesisId: 'G');
      // #endregion
    } catch (e) {
      // #region agent log
      _logDebug('main.dart:AlphaMotorsApp:232', 'NotificationService Get.find() failed', {'error': e.toString()}, hypothesisId: 'G');
      // #endregion
      rethrow;
    }
    storage = GetStorage();
    // #region agent log
    _logDebug('main.dart:AlphaMotorsApp:237', 'AlphaMotorsApp constructor completed', {}, hypothesisId: 'G');
    // #endregion
  }

  // Use Get.find() to locate already initialized controllers, not Get.put().
  late final ThemeController themeController;
  late final NotificationService notificationService;
  late final GetStorage storage;

  @override
  Widget build(BuildContext context) {
    // #region agent log
    _logDebug('main.dart:AlphaMotorsApp:build:246', 'AlphaMotorsApp build() started', {}, hypothesisId: 'G');
    // #endregion
    try {
      // This logic runs once to subscribe the user to a global topic if not already subscribed.
      final isAlreadySubscribed =
          storage.read<bool>('isSubscribedToGlobalTopic') ?? false;
      // #region agent log
      _logDebug('main.dart:AlphaMotorsApp:build:252', 'Read isSubscribedToGlobalTopic', {'isAlreadySubscribed': isAlreadySubscribed}, hypothesisId: 'G');
      // #endregion
      if (!isAlreadySubscribed) {
        try {
          notificationService.subscribeToGlobalTopic();
          // #region agent log
          _logDebug('main.dart:AlphaMotorsApp:build:257', 'subscribeToGlobalTopic() called', {}, hypothesisId: 'G');
          // #endregion
        } catch (e) {
          // #region agent log
          _logDebug('main.dart:AlphaMotorsApp:build:260', 'subscribeToGlobalTopic() failed', {'error': e.toString()}, hypothesisId: 'G');
          // #endregion
        }
      }

      // Read saved language to set the initial locale
      final savedLanguage = storage.read('language') ?? 'en_US';
      final localeParts = savedLanguage.split('_');
      final locale = Locale(localeParts[0], localeParts[1]);
      // #region agent log
      _logDebug('main.dart:AlphaMotorsApp:build:269', 'Locale set', {'savedLanguage': savedLanguage, 'locale': locale.toString()}, hypothesisId: 'G');
      // #endregion

      return Obx(() {
        try {
          final isDarkMode = themeController
              .isDark
              .value; // Assumes your controller has an `isDark` boolean
          // #region agent log
          _logDebug('main.dart:AlphaMotorsApp:build:Obx:382', 'Obx() callback started', {'isDarkMode': isDarkMode}, hypothesisId: 'G');
          // #endregion

          // Dynamically set the system UI style based on the current theme
          final systemUiStyle = SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDarkMode
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarColor: isDarkMode
                ? AppThemes.dark.scaffoldBackgroundColor
                : AppThemes.light.scaffoldBackgroundColor,
            systemNavigationBarIconBrightness: isDarkMode
                ? Brightness.light
                : Brightness.dark,
          );

          // #region agent log
          _logDebug('main.dart:AlphaMotorsApp:build:Obx:402', 'About to return GetMaterialApp', {}, hypothesisId: 'G');
          // #endregion

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: systemUiStyle,
            child: GetMaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppThemes.light,
              darkTheme: AppThemes.dark,
              themeMode: themeController.themeMode.value,
              initialRoute: '/navView',
              getPages: [
                GetPage(name: '/', page: () => AuthCheckPage()),
                GetPage(name: '/splash', page: () => CustomSplashScreen()),
                GetPage(name: '/register', page: () => SRegisterPage()),
                GetPage(name: '/checkOtp', page: () => OtpScreen()),
                GetPage(name: '/navView', page: () => BottomNavView()),
                GetPage(name: '/home', page: () => HomeScreen()),
                GetPage(name: '/profile', page: () => ProfileScreen()),
                GetPage(name: '/filter', page: () => FilterScreen()),
                GetPage(name: '/search', page: () => SearchScreen()),
              ],
              translations: AppTranslations(),
              locale: locale,
              fallbackLocale: const Locale('en', 'US'),
            ),
          );
        } catch (e, stackTrace) {
          // #region agent log
          _logDebug('main.dart:AlphaMotorsApp:build:Obx:428', 'Obx() callback failed', {'error': e.toString(), 'errorType': e.runtimeType.toString(), 'stackTrace': stackTrace.toString()}, hypothesisId: 'G');
          // #endregion
          rethrow;
        }
      });
    } catch (e, stackTrace) {
      // #region agent log
      _logDebug('main.dart:AlphaMotorsApp:build:434', 'build() failed', {'error': e.toString(), 'errorType': e.runtimeType.toString(), 'stackTrace': stackTrace.toString()}, hypothesisId: 'G');
      // #endregion
      rethrow;
    }
  }
}
