import 'dart:convert';
import 'dart:io';

import 'package:auto_tm/firebase_options.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void _logDebugNS(
  String location,
  String message,
  Map<String, dynamic> data, {
  String? hypothesisId,
}) {
  try {
    final logFile = File(
      '/Users/bagtyyar/Projects/auto.tm-main/.cursor/debug.log',
    );
    final logEntry = {
      'id':
          'log_${DateTime.now().millisecondsSinceEpoch}_${location.replaceAll(':', '_')}',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': location,
      'message': message,
      'data': data,
      'sessionId': 'debug-session',
      'runId': 'run1',
      if (hypothesisId != null) 'hypothesisId': hypothesisId,
    };
    logFile.writeAsStringSync(
      '${jsonEncode(logEntry)}\n',
      mode: FileMode.append,
    );
  } catch (e) {
    // Silently fail if logging fails
  }
}

class NotificationService extends GetxService {
  late final FirebaseMessaging _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GetStorage _storage = GetStorage();
  final String _globalTopicKey = 'isSubscribedToGlobalTopic';
  final bool debug = false;

  Future<void> init() async {
    // #region agent log
    _logDebugNS(
      'notification_service.dart:init:33',
      'NotificationService.init() started',
      {},
      hypothesisId: 'E',
    );
    // #endregion

    // Check if Firebase is already initialized to avoid double initialization
    try {
      Firebase.app();
      // Firebase is already initialized
      // #region agent log
      _logDebugNS(
        'notification_service.dart:init:39',
        'Firebase already initialized',
        {},
        hypothesisId: 'E',
      );
      // #endregion
    } catch (e) {
      // Firebase is not initialized, initialize it now
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        // #region agent log
        _logDebugNS(
          'notification_service.dart:init:47',
          'Firebase initialized in NotificationService',
          {},
          hypothesisId: 'E',
        );
        // #endregion
      } catch (e2) {
        // #region agent log
        _logDebugNS(
          'notification_service.dart:init:51',
          'Firebase initialization failed in NotificationService',
          {'error': e2.toString(), 'errorType': e2.runtimeType.toString()},
          hypothesisId: 'E',
        );
        // #endregion
        rethrow;
      }
    }

    try {
      _firebaseMessaging = FirebaseMessaging.instance;
      // #region agent log
      _logDebugNS(
        'notification_service.dart:init:59',
        'FirebaseMessaging.instance obtained',
        {},
        hypothesisId: 'E',
      );
      // #endregion
    } catch (e) {
      // #region agent log
      _logDebugNS(
        'notification_service.dart:init:62',
        'FirebaseMessaging.instance failed',
        {'error': e.toString()},
        hypothesisId: 'E',
      );
      // #endregion
      rethrow;
    }

    try {
      await _initializeLocalNotifications();
      // #region agent log
      _logDebugNS(
        'notification_service.dart:init:69',
        '_initializeLocalNotifications() completed',
        {},
        hypothesisId: 'E',
      );
      // #endregion
    } catch (e) {
      // #region agent log
      _logDebugNS(
        'notification_service.dart:init:72',
        '_initializeLocalNotifications() failed',
        {'error': e.toString()},
        hypothesisId: 'E',
      );
      // #endregion
      rethrow;
    }

    // #region agent log
    _logDebugNS(
      'notification_service.dart:init:76',
      'NotificationService.init() completed',
      {},
      hypothesisId: 'E',
    );
    // #endregion
  }

  Future<void> enableNotifications() async {
    await _requestPermissions();
    _setupForegroundHandler();
    _setupBackgroundHandler();
    _setupTokenRefreshListener();
    await _sendDeviceTokenToBackend();

    final isSubscribed = _storage.read<bool>(_globalTopicKey) ?? false;
    final accessToken = await TokenStore.to.accessToken;
    if (!isSubscribed && accessToken != null && accessToken.isNotEmpty) {
      await subscribeToGlobalTopic();
    }
  }

  Future<void> subscribeToGlobalTopic({String topic = 'all'}) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      await _storage.write(_globalTopicKey, true);
      _log("Subscribed to topic: $topic");
    } catch (e) {
      _log("Error subscribing to topic: $e");
    }
  }

  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _log("User granted permission: ${settings.authorizationStatus}");
  }

  Future<void> _sendDeviceTokenToBackend() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null) {
        _log("Failed to get FCM token.");
        return;
      }

      await _storage.write('FCM_TOKEN', token);
      await _uploadToken(token);
    } catch (e) {
      _log("Error fetching/sending token: $e");
    }
  }

  Future<void> _uploadToken(String token) async {
    if (!Get.isRegistered<ApiClient>()) {
      _log("ApiClient not ready. Cannot send FCM token.");
      return;
    }
    final hasToken = await TokenStore.to.hasTokens;
    if (!hasToken) {
      _log("No access token found. Cannot send FCM token.");
      return;
    }

    try {
      final response = await ApiClient.to.dio.put(
        'auth/setFirebase',
        data: {'token': token},
      );

      if (response.statusCode == 200) {
        _log("Token sent to backend successfully.");
      } else {
        _log(
          "Backend rejected token: ${response.statusCode} - ${response.data}",
        );
      }
    } catch (e) {
      _log("Error sending token to backend: $e");
    }
  }

  void _setupTokenRefreshListener() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      _log("Token refreshed: $newToken");
      await _uploadToken(newToken);
      await _storage.write('FCM_TOKEN', newToken);
    });
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(message);
      }
    });
  }

  void _setupBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final service = NotificationService();
    service._showNotification(message);
  }

  Future<void> _initializeLocalNotifications() async {
    // Use a safer default icon. The previous 'ic_launcher_foreground' caused
    // PlatformException(invalid_icon, resource ... not found) on some builds
    // when the adaptive foreground asset wasn't present in the merged manifest.
    // Fallback to 'ic_launcher' (generated by Flutter template). If you add a
    // custom monochrome notification icon later (e.g. res/drawable/ic_stat_app.png),
    // replace below with that resource name.
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _localNotificationsPlugin.initialize(initSettings);
      _log("Local notifications initialized.");
    } catch (e) {
      _log("Local notifications init failed: $e");
    }
  }

  void _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = notification?.android;
    final ios = notification?.apple;

    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'channel_description',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: android != null ? androidDetails : null,
      iOS: ios != null ? iosDetails : null,
    );

    await _localNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  Future<void> sendTokenToBackend(String token) async {
    await _uploadToken(token);
  }

  void _log(String message) {
    if (kDebugMode) {
      print("[NotificationService] $message");
    }
  }
}
