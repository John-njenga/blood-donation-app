import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FirebaseNotificationHelper {
  // Method to send notification using FCM HTTP v1 API
  static Future<void> sendNotification(List<String> tokens, String title, String body) async {
    const String fcmUrl = "https://fcm.googleapis.com/v1/projects/bloodconnect-b0e96/messages:send";

    // Load the service account credentials from the assets
    final serviceAccountJson = json.decode(await rootBundle.loadString('assets/service_account.json')) as Map<String, dynamic>;

    // Authenticate using OAuth 2.0 with the service account credentials
    final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
    final client = await clientViaServiceAccount(accountCredentials, ['https://www.googleapis.com/auth/firebase.messaging']);

    // Loop through each token and send notification
    for (String token in tokens) {
      final payload = {
        "message": {
          "token": token,
          "notification": {
            "title": title,
            "body": body,
          },
          "android": {
            "notification": {
              "click_action": "FLUTTER_NOTIFICATION_CLICK"
            }
          }
        }
      };

      // Send the HTTP POST request to FCM
      final response = await client.post(
        Uri.parse(fcmUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print("Notification sent successfully to $token");
      } else {
        print("Error sending notification: ${response.body}");
      }
    }
  }
}
