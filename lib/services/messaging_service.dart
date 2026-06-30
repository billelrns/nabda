import 'package:cloud_firestore/cloud_firestore.dart';

class MessagingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// جلب أو إنشاء معرف الدردشة الثنائية المرتب بين مستخدمين
  Future<String> getOrCreateChat(String currentUid, String recipientUid) async {
    final participants = [currentUid, recipientUid]..sort();
    final chatId = '${participants[0]}_${participants[1]}';

    final chatRef = _db.collection('direct_chats').doc(chatId);
    final snap = await chatRef.get();

    if (!snap.exists) {
      await chatRef.set({
        'id': chatId,
        'participants': participants,
        'lastMessage': '',
        'lastMessageSenderId': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {
          currentUid: 0,
          recipientUid: 0,
        },
        'blockedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  /// إرسال رسالة ثنائية مع حارس الحظر وتحديث حقول الإشعار
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    if (text.trim().isEmpty) return;

    final chatRef = _db.collection('direct_chats').doc(chatId);
    final snap = await chatRef.get();
    if (!snap.exists) throw Exception('المحادثة غير موجودة');

    final data = snap.data();
    final blockedBy = List<String>.from(data?['blockedBy'] ?? []);
    if (blockedBy.isNotEmpty) {
      throw Exception('لا يمكن إرسال الرسالة. تم حظر المحادثة.');
    }

    final participants = List<String>.from(data?['participants'] ?? []);
    final recipientId = participants.firstWhere((p) => p != senderId);

    final messageRef = chatRef.collection('messages').doc();

    await _db.runTransaction((transaction) async {
      // 1. إضافة الرسالة في المجموعة الفرعية
      transaction.set(messageRef, {
        'id': messageRef.id,
        'senderId': senderId,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 2. تحديث الحقول الرئيسية للدردشة وزيادة الرسائل غير المقروءة للمستلم
      transaction.update(chatRef, {
        'lastMessage': text.trim(),
        'lastMessageSenderId': senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$recipientId': FieldValue.increment(1),
      });
    });
  }

  /// تصفير عداد الرسائل غير المقروءة للمستخدم الحالي
  Future<void> markChatAsRead(String chatId, String currentUid) async {
    final chatRef = _db.collection('direct_chats').doc(chatId);
    await chatRef.update({
      'unreadCount.$currentUid': 0,
    });
  }

  /// حظر أو إلغاء حظر الطرف الآخر
  Future<void> toggleBlockUser(String chatId, String currentUid) async {
    final chatRef = _db.collection('direct_chats').doc(chatId);
    final snap = await chatRef.get();
    if (!snap.exists) return;

    final blockedBy = List<String>.from(snap.data()?['blockedBy'] ?? []);

    if (blockedBy.contains(currentUid)) {
      await chatRef.update({
        'blockedBy': FieldValue.arrayRemove([currentUid]),
      });
    } else {
      await chatRef.update({
        'blockedBy': FieldValue.arrayUnion([currentUid]),
      });
    }
  }

  /// الإبلاغ عن مستخدم أو رسالة مسيئة للإشراف العام
  Future<void> reportUser({
    required String reportedUid,
    required String reporterUid,
    required String reason,
    String? messageText,
  }) async {
    await _db.collection('reports').add({
      'reportedUid': reportedUid,
      'reporterUid': reporterUid,
      'reason': reason,
      'messageText': messageText,
      'type': 'direct_message',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  /// بث حي لقائمة الدردشات الخاصة بالمستخدم الحالي
  Stream<List<Map<String, dynamic>>> getChatsStream(String currentUid) {
    return _db
        .collection('direct_chats')
        .where('participants', arrayContains: currentUid)
        .snapshots()
        .asyncMap((snapshot) async {
      final chatsList = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final recipientId = participants.firstWhere((p) => p != currentUid);

        // جلب تفاصيل الطرف الآخر من مجموعة المستخدمين (صامد ضدّ رفض القراءة)
        String recipientName = 'مستخدمة نبضة';
        String recipientImage = '';
        try {
          final recipientSnap = await _db.collection('users_directory').doc(recipientId).get();
          final rd = recipientSnap.data();
          recipientName = (rd?['name'] as String?)?.isNotEmpty == true ? rd!['name'] : 'مستخدمة نبضة';
          recipientImage = (rd?['photoUrl'] ?? rd?['profileImage'] ?? '') as String;
        } catch (_) {/* رفض الصلاحية أو غياب المستند — نُبقي القيم الافتراضية */}

        chatsList.add({
          ...data,
          'recipientId': recipientId,
          'recipientName': recipientName,
          'recipientImage': recipientImage,
        });
      }

      // فرز تنازلي حسب وقت آخر رسالة
      chatsList.sort((a, b) {
        final aTime = a['lastMessageTime'] as Timestamp?;
        final bTime = b['lastMessageTime'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return chatsList;
    });
  }

  /// بث حي للرسائل داخل غرفة الدردشة المحددة
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _db
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
