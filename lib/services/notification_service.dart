import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level handler for background messages (required by FCM)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message — no UI access here
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ─── Android notification channel ───
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'nabda_orders', // id
    'طلبات نبضة', // name
    description: 'إشعارات حالة الطلبات والعروض',
    importance: Importance.high,
    playSound: true,
  );

  // ─── Initialize FCM + Local Notifications ───
  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // 2. Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Initialize local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 4. Get and save FCM token (non-blocking + timeout — لا يحجب عند انقطاع الشبكة)
    _fcm.getToken().timeout(const Duration(seconds: 6), onTimeout: () => null).then((t) {
      if (t != null) saveFCMToken(t);
    }).catchError((_) {});

    // 5. Listen for token refresh
    _fcm.onTokenRefresh.listen(saveFCMToken);

    // 6. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 7. Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // 8. Check if app was opened from a notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpen(initialMessage);
    }

    _initialized = true;
    debugPrint('NotificationService initialized.');
  }

  // ─── Handle foreground message → show local notification ───
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['orderId'],
    );
  }

  // ─── Handle notification tap ───
  void _onNotificationTap(NotificationResponse response) {
    // Navigate to order details
    debugPrint('Notification tapped: ${response.payload}');
  }

  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('Notification opened app: ${message.data}');
  }

  // ─── Save FCM token to Firestore ───
  Future<void> saveFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // ─── Create order status notification (in-app + Firestore) ───
  Future<void> createOrderNotification({
    required String userId,
    required String orderId,
    required String newStatus,
    required String productName,
  }) async {
    final statusMessages = {
      'pending': 'تم استلام طلبك بنجاح',
      'processing': 'جاري تجهيز طلبك "$productName"',
      'shipped': 'تم شحن طلبك "$productName"',
      'delivered': 'تم توصيل طلبك "$productName" بنجاح',
      'cancelled': 'تم إلغاء طلبك "$productName"',
    };

    final statusTitles = {
      'pending': 'طلب جديد',
      'processing': 'قيد التجهيز',
      'shipped': 'تم الشحن',
      'delivered': 'تم التوصيل',
      'cancelled': 'طلب ملغي',
    };

    // Save to Firestore (in-app notifications)
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'orderId': orderId,
      'title': statusTitles[newStatus] ?? 'تحديث الطلب',
      'body': statusMessages[newStatus] ?? 'تم تحديث حالة طلبك',
      'type': 'order_status',
      'status': newStatus,
      'read': false,
      'sentAt': FieldValue.serverTimestamp(),
    });

    // For push notification via FCM, you would typically:
    // 1. Get the user's FCM token from Firestore
    // 2. Send via Firebase Cloud Functions or your backend
    // Example Cloud Function trigger:
    // exports.onOrderStatusChange = functions.firestore
    //   .document('orders/{orderId}')
    //   .onUpdate(async (change, context) => { ... });
  }

  // ─── Get user's notifications stream ───
  Stream<QuerySnapshot> getUserNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // ─── Get unread count ───
  Stream<int> getUnreadCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ─── Mark as read ───
  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  // ─── Mark all as read ───
  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final unread = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // ─── Show local notification manually ───
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id, _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }
}
