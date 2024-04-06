import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'notification_service.dart';

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static String userToken =
      'cnhmqn14Rz2-MVBVai0keu:APA91bFdGJfbE_9TRFSo1lRAZnmnrZ4YUH2PBbHK8LN7uusTvDT1FCSM6wErP9Oqs9PF27zCiDELm1Ahv9gaOYMxs4lBSl9SiIhMo1q9-eEJ-tykp3bDmAZK7V1re5J6-hG3eQtl3SYL';
  static String scopes = 'https://www.googleapis.com/auth/firebase.messaging';
  static String baseUrl = 'https://fcm.googleapis.com/v1/projects/child-tracking-27739/messages:send';

  static void initializeFirebaseMessaging() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen for incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');

      // Display notification when app is in foreground
      if (message.notification != null) {
        print(
            'Message also contained a notification: ${message.notification?.title}');
        NotificationService.createNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published! ${message.data}');
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<void> sendNotificationToUser(
      {required String title, required String body}) async {
    String? accessToken = await getAccessToken();

    try {
      // Construct the notification message
      Map<String, dynamic> payload = {
        'message': {
          'token': userToken,
          'notification': {
            'title': title,
            'body': body,
          }
        }
      };

      // Convert the message to JSON
      String jsonMessage = json.encode(payload);

      // Send the notification request to FCM
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonMessage,
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        print('Notification sent successfully to $userToken');
      } else {
        print('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      // Load the service account credentials from a JSON file
      final String jsonString =
          await rootBundle.loadString('assets/services/google-services.json');
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final ServiceAccountCredentials credentials =
          ServiceAccountCredentials.fromJson(json);

      // Create an authenticated HTTP client using the service account credentials
      final client = await clientViaServiceAccount(credentials, [scopes]);

      // Obtain an access token
      final AccessCredentials accessCredentials =
          await obtainAccessCredentialsViaServiceAccount(
        credentials,
        [scopes],
        client,
      );

      final String accessToken = accessCredentials.accessToken.data;

      return accessToken;
    } catch (e) {
      print('Failed to get access token: $e');
      return null;
    }
  }
}
