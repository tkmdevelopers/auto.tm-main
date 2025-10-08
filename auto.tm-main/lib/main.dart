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
import 'package:auto_tm/screens/search_screen/search_screen.dart';
import 'package:auto_tm/screens/post_screen/controller/upload_manager.dart';
import 'package:auto_tm/screens/post_screen/controller/post_controller.dart';
import 'package:auto_tm/screens/splash_screen/custom_splash_screen.dart';
import 'package:auto_tm/services/notification_sevice/notification_service.dart';
import 'package:auto_tm/services/auth/auth_service.dart';
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

void main() async {
  // --- Ensure all bindings are initialized before running the app ---
  WidgetsFlutterBinding.ensureInitialized();

  // --- Initialize core services and packages ---
  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  await dotenv.load(fileName: ".env").catchError((e) {
    AppLogger.w(
      'Warning: .env file not found. Using default configuration.',
      error: e,
    );
  });

  // --- Initialize your app's services and global controllers ---
  await initServices();

  // --- Set preferred screen orientation for the whole app ---
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // --- Request necessary permissions on startup ---
  await [
    Permission.camera,
    Permission.photos,
    Permission.storage,
    Permission.notification,
  ].request();

  // Schedule non-blocking cache maintenance
  Future.microtask(() => AppCacheCleaner().autoPruneIfNeeded());

  runApp(AlphaMotorsApp());
}

/// Centralized function to initialize all your global services and controllers.
Future<void> initServices() async {
  Get.put(
    ThemeController(),
  ); // ThemeController is global, so it's initialized here.
  Get.put(ConnectionController());
  Get.put(DownloadController());
  // Register UploadManager early so background progress / locks are available app-wide.
  if (!Get.isRegistered<UploadManager>()) {
    await Get.putAsync(() async => await UploadManager().init());
  }
  // Lazily register PostController so any route (like UploadProgressScreen) can resolve it.
  if (!Get.isRegistered<PostController>()) {
    Get.lazyPut(() => PostController(), fenix: true);
  }
  // Register AuthService (phone OTP + session). Must come after GetStorage.init().
  if (!Get.isRegistered<AuthService>()) {
    await Get.putAsync(() async => await AuthService().init());
  }
  await Get.putAsync(() async => NotificationService()..init());
  // Register ProfileController globally so UI never creates duplicates.
  if (!Get.isRegistered<ProfileController>()) {
    Get.put(ProfileController(), permanent: true);
  }
  if (!Get.isRegistered<FilterController>()) {
    Get.put(FilterController(), permanent: true);
  }
}

class AlphaMotorsApp extends StatelessWidget {
  AlphaMotorsApp({super.key});

  // Use Get.find() to locate already initialized controllers, not Get.put().
  final ThemeController themeController = Get.find();
  final NotificationService notificationService = Get.find();
  final GetStorage storage = GetStorage();

  @override
  Widget build(BuildContext context) {
    // This logic runs once to subscribe the user to a global topic if not already subscribed.
    final isAlreadySubscribed =
        storage.read<bool>('isSubscribedToGlobalTopic') ?? false;
    if (!isAlreadySubscribed) {
      notificationService.subscribeToGlobalTopic();
    }

    // Read saved language to set the initial locale
    final savedLanguage = storage.read('language') ?? 'en_US';
    final localeParts = savedLanguage.split('_');
    final locale = Locale(localeParts[0], localeParts[1]);

    return Obx(() {
      final isDarkMode = themeController
          .isDark
          .value; // Assumes your controller has an `isDark` boolean

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
    });
  }
}
