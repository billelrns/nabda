import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/functions_config.dart' show kBroadcastTopic;
import 'notification_images.dart';
import 'notification_router.dart';
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
  /// القنوات التي قد يحدّدها الخادم — وكلّها تُنشأ عند الإقلاع
  /// (AppNotifs._ensureChannels وهذه الخدمة).
  static const Map<String, String> _knownChannels = {
    'nabda_orders': 'طلبات نبضة',
    'partner_channel': 'تنبيهات الزوجين',
    'products_channel': 'عروض ومنتجات نبضة',
  };

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

    // 0. الإشعارات المحلية أوّلاً — حتى يعمل الضغط على الإشعار (فتح المنتج)
    //    حتى لو تعطّل طلب الإذن أو FCM. لا يوجد تنفيذ لها على الويب.
    if (!kIsWeb) {
      try {
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
        // التطبيق فُتح من الضغط على إشعار محلي وهو مُغلق تماماً
        final launch = await _localNotifications.getNotificationAppLaunchDetails();
        if (launch?.didNotificationLaunchApp == true) {
          NotificationRouter.handlePayload(launch!.notificationResponse?.payload);
        }
      } catch (e) {
        debugPrint('Local notifications init failed: $e');
      }
    }

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

    // 3. الإشعارات المحلية هُيّئت في الخطوة 0

    // 4. Get and save FCM token (non-blocking + timeout — لا يحجب عند انقطاع الشبكة)
    _fcm.getToken().timeout(const Duration(seconds: 6), onTimeout: () => null).then((t) {
      if (t != null) saveFCMToken(t);
    }).catchError((_) {});

    // 5. Listen for token refresh
    _fcm.onTokenRefresh.listen(saveFCMToken);

    // 5b. ⚠️ احفظ الرمز أيضاً عند كل تسجيل دخول.
    //     initialize() يُستدعى في main() قبل تسجيل الدخول، فكان saveFCMToken
    //     يخرج بصمت (لا مستخدم بعد) — أي أن **كل حساب جديد لم يُحفظ رمزه
    //     أبداً** ولم تكن تصله أي إشعارات، ومنه حساب الأب في وضع الزوجين.
    FirebaseAuth.instance.authStateChanges().listen((u) {
      if (u == null) return;
      _fcm
          .getToken()
          .timeout(const Duration(seconds: 6), onTimeout: () => null)
          .then((t) {
        if (t != null) saveFCMToken(t);
      }).catchError((_) {});
    });

    // 5c. الاشتراك في قناة الإشعارات الجماعية (لوحة الأدمن → sendBroadcast).
    //     لم يكن أيّ هاتف مشتركاً في أيّ topic من قبل، فلم تصل أيّ رسالة جماعية.
    //     ⚠️ الاسم يجب أن يطابق BROADCAST_TOPIC في functions/index.js
    if (!kIsWeb) {
      _fcm.subscribeToTopic(kBroadcastTopic).catchError((_) {});
    }

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
  /// أندرويد يعرض صورة FCM تلقائياً **فقط حين يكون التطبيق في الخلفية**.
  /// حين يكون مفتوحاً نعرض الإشعار بأنفسنا، فنُنزّل الصورة ونرفقها هنا.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final image = notification.android?.imageUrl ?? message.data['image'];
    final style = await NotificationImages.bigPicture(
      image,
      title: notification.title,
      body: notification.body,
    );

    // نحترم القناة التي حدّدها الخادم (تنبيهات الزوجين / العروض)
    final ch = notification.android?.channelId;
    final channelId = (ch != null && _knownChannels.containsKey(ch)) ? ch : _channel.id;
    final channelName = _knownChannels[channelId] ?? _channel.name;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
          largeIcon: style?.largeIcon,
          styleInformation: style,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // منتج مرتبط → يفتح صفحته عند الضغط؛ وإلا رقم الطلب كما كان
      payload: _payloadFor(message.data),
    );
  }

  // ─── Handle notification tap ───
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    NotificationRouter.handlePayload(response.payload);
  }

  /// إشعار FCM ضُغط عليه والتطبيق في الخلفية أو مُغلق
  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('Notification opened app: ${message.data}');
    NotificationRouter.handleData(message.data);
  }

  static String? _payloadFor(Map<String, dynamic> data) {
    final type = (data['linkType'] ?? '').toString();
    final id = (data['linkId'] ?? data['productId'] ?? '').toString().trim();
    if (id.isNotEmpty && type == 'article') {
      return NotificationRouter.articlePayload(id);
    }
    if (id.isNotEmpty && (type.isEmpty || type == 'product')) {
      return NotificationRouter.productPayload(id);
    }
    return data['orderId']?.toString();
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
