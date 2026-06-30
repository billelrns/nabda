import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/messaging_service.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final MessagingService _messagingService = MessagingService();
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  static const Color _teal = Color(0xFF00897B);
  static const Color _pink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('يرجى تسجيل الدخول لعرض الرسائل المباشرة')),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        appBar: AppBar(
          title: const Text(
            'رسائلي الخاصة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _messagingService.getChatsStream(_currentUserId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _teal),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('حدث خطأ أثناء تحميل المحادثات'),
              );
            }

            final chats = snapshot.data ?? [];

            if (chats.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _buildChatItem(chat);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE8EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: _pink,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'محادثاتكِ الخاصة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D3A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'يمكنكِ بدء دردشة ثنائية خاصة وآمنة مع الأمهات في مجتمع نبضة بالدخول لصفحاتهن الشخصية والضغط على زر "رسالة".',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final chatId = chat['id'] as String;
    final recipientName = chat['recipientName'] as String;
    final lastMessage = chat['lastMessage'] as String;
    final unreadMap = chat['unreadCount'] as Map<dynamic, dynamic>? ?? {};
    final unreadCount = unreadMap[_currentUserId] ?? 0;
    final recipientImage = chat['recipientImage'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.pink.shade50.withOpacity(0.5), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // تصفير غير المقروء
          _messagingService.markChatAsRead(chatId, _currentUserId!);
          // التوجيه لغرفة المحادثة
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChatRoomScreen(chatId: chatId)));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // الصورة الشخصية للمستلم
              CircleAvatar(
                radius: 26,
                backgroundColor: _teal.withOpacity(0.1),
                backgroundImage: recipientImage.isNotEmpty
                    ? NetworkImage(recipientImage)
                    : null,
                child: recipientImage.isEmpty
                    ? Text(
                        recipientName.isNotEmpty ? recipientName[0] : '؟',
                        style: const TextStyle(
                          color: _teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              // تفاصيل المحادثة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipientName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D3A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lastMessage.isNotEmpty ? lastMessage : 'بدء محادثة جديدة...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: unreadCount > 0 ? _teal : Colors.grey.shade500,
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              // عداد الإشعارات والوقت
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (chat['lastMessageTime'] != null)
                    Text(
                      _formatLastMessageTime(chat['lastMessageTime'] as Timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _pink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastMessageTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      const days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return days[date.weekday % 7];
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
