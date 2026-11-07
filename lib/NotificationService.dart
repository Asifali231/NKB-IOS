import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here
  print('Handling background message: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final String tokenKey = 'fcm_token';
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _messageListenersRegistered = false;
  static bool _tokenRefreshListenerRegistered = false;

  // Notification channel details
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _initializeLocalNotifications();
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
    _setupForegroundHandlers();
    _initialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _setupForegroundHandlers() {
    if (_messageListenersRegistered) return;
    _messageListenersRegistered = true;
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      unawaited(_handleForegroundMessage(message).catchError((Object error) {
        debugPrint('Unable to display foreground notification: $error');
      }));
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTapped);
    unawaited(_firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) _handleNotificationTapped(message);
    }).catchError((Object error) {
      debugPrint('Unable to read the initial notification: $error');
    }));
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      final android = notification.android;
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: android == null
              ? null
              : AndroidNotificationDetails(
                  _channel.id,
                  _channel.name,
                  channelDescription: _channel.description,
                  icon: android.smallIcon,
                ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  void _handleNotificationTapped(RemoteMessage message) {
    // Handle notification tap
    print('Notification tapped: ${message.messageId}');
    // Add your navigation logic here
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle local notification tap
    print('Local notification tapped: ${response.payload}');
    // Add your navigation logic here
  }

  Future<String?> getToken() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!isAuthorized) {
        debugPrint(
          'Push notifications are not authorized: ${settings.authorizationStatus}.',
        );
        return null;
      }

      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken;
        for (var attempt = 0; attempt < 5 && apnsToken == null; attempt++) {
          apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken == null) {
            await Future<void>.delayed(const Duration(seconds: 1));
          }
        }
        if (apnsToken == null) {
          debugPrint(
            'APNs token is unavailable. Check Push Notifications capability, provisioning profile, and the APNs key uploaded to Firebase.',
          );
          return null;
        }
      }

      final token = await _firebaseMessaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('Firebase Messaging returned an empty device token.');
        return null;
      }

      await _persistToken(token);
      if (!_tokenRefreshListenerRegistered) {
        _tokenRefreshListenerRegistered = true;
        _firebaseMessaging.onTokenRefresh.listen(_updateToken);
      }
      return token;
    } catch (error, stackTrace) {
      debugPrint('Error getting FCM token: $error\n$stackTrace');
      return null;
    }
  }

  Future<void> _updateToken(String newToken) async {
    try {
      await _persistToken(newToken);
    } catch (e) {
      print('Error updating token: $e');
    }
  }

  Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set(
      {
        'fcmToken': token,
        'userDeviceToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
