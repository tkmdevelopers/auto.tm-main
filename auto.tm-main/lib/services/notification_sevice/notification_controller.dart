// import 'dart:convert';

// import 'package:auto_tm/firebase_options.dart';
// import 'package:auto_tm/utils/key.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:get/get.dart'; // If you're using GetX for state management
// import 'package:get_storage/get_storage.dart'; // If you're using GetStorage
// import 'package:http/http.dart' as http;

// class NotificationController extends GetxController {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final box = GetStorage();

//   @override
//   void onInit() {
//     super.onInit();
//     requestNotificationPermissions();
//     getDeviceToken();
//     setupBackgroundMessageHandler();
//     setupForegroundMessageHandler();
//     // ... other initialization
//   }

//   Future<void> requestNotificationPermissions() async {
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );

//     print('User granted notification permissions: ${settings.authorizationStatus}');
//   }

//   Future<void> getDeviceToken() async {
//     try {
//       String? token = await _firebaseMessaging.getToken();
//       if (token != null) {
//         print('FCM Device Token: $token');
//         // Send this token to your backend API for the current user
//         sendTokenToBackend(token);
//         await box.write('fcm_token', token); // Store locally if needed
//       }
//     } catch (e) {
//       print('Error getting device token: $e');
//     }
//   }

//   Future<void> sendTokenToBackend(String token) async {
//     // Implement your API call here to send the token to your backend
//     // Example using http package:
//     final response = await http.post(
//       Uri.parse(ApiKey.setFirebaseKey),
//       headers: {'Content-Type': 'application/json','Authorization': 'Bearer ${box.read('ACCESS_TOKEN')}',},
//       body: jsonEncode({'token': token}),
//     );
//     if (response.statusCode == 200) {
//       print('FCM token sent to backend successfully');
//     } else {
//       print('Failed to send FCM token to backend: ${response.statusCode}');
//     }
//   }

//   // Background message handler (must be a top-level function)
//   @pragma('vm:entry-point')
//   Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//     print("Handling a background message: ${message.messageId}");
//     // Handle the notification data here
//     if (message.data.isNotEmpty) {
//       print('Background message data: ${message.data}');
//       // You can show a local notification here if needed
//       // using packages like flutter_local_notifications
//     }
//   }

//   void setupBackgroundMessageHandler() {
//     // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   }

//   void setupForegroundMessageHandler() {
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print('Got a message whilst in the foreground!');
//       print('Message data: ${message.data}');

//       if (message.notification != null) {
//         print('Message also contained a notification: ${message.notification}');
//         // You can show a local notification here using flutter_local_notifications
//         // to display the notification to the user.
//       }
//     });
//   }
// }