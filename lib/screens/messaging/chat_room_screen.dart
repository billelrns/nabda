import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/messaging_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  const ChatRoomScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  String _recipientName = 'مستخدمة نبضة';
  String _recipientImage = '';
  String _recipientId = '';
  bool _isBlockedByMe = false;
  bool _isBlockedByOther = false;
  bool _isLoadingRecipient = true;

  static const Color _teal = Color(0xFF00897B);
  static const Color _pink = Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _loadRecipientDetails();
    if (_currentUserId != null) {
      _messagingService.markChatAsRead(widget.chatId, _currentUserId!);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipientDetails() async {
    try {
      final chatSnap = await FirebaseFirestore.instance.collection('direct_chats').doc(widget.chatId).get();
      if (!chatSnap.exists) return;

      final data = chatSnap.data();
      final participants = List<String>.from(data?['participants'] ?? []);
      _recipientId = participants.firstWhere((p) => p != _currentUserId);

      // تحميل بيانات الطرف الآخر من الدليل العامّ الآمن (الاسم/الصورة فقط)
      final recipientSnap = await FirebaseFirestore.instance.collection('users_directory').doc(_recipientId).get();
      if (recipientSnap.exists && mounted) {
        final rd = recipientSnap.data();
        setState(() {
          _recipientName = (rd?['name'] as String?)?.isNotEmpty == true ? rd!['name'] : 'مستخدمة نبضة';
          _recipientImage = (rd?['photoUrl'] ?? rd?['profileImage'] ?? '') as String;
        });
      }

      // الاستماع لحالة الحظر
      FirebaseFirestore.instance.collection('direct_chats').doc(widget.chatId).snapshots().listen((chatDoc) {
        if (!mounted || !chatDoc.exists) return;
        final blockedBy = List<String>.from(chatDoc.data()?['blockedBy'] ?? []);
        setState(() {
          _isBlockedByMe = blockedBy.contains(_currentUserId);
          _isBlockedByOther = blockedBy.contains(_recipientId);
        });
      });
    } catch (_) {} finally {
      if (mounted) {
        setState(() => _isLoadingRecipient = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    _messageController.clear();

    try {
      await _messagingService.sendMessage(widget.chatId, _currentUserId!, text);
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _showReportDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('الإبلاغ عن إساءة'),
            content: TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'وضحي سبب الإبلاغ بالتفصيل...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (reasonController.text.trim().isEmpty) return;
                  await _messagingService.reportUser(
                    reportedUid: _recipientId,
                    reporterUid: _currentUserId!,
                    reason: reasonController.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إرسال الإبلاغ بنجاح وسيتم مراجعته من قبل الإشراف.'),
                        backgroundColor: _teal,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _pink, foregroundColor: Colors.white),
                child: const Text('إرسال الإبلاغ'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                backgroundImage: _recipientImage.isNotEmpty ? NetworkImage(_recipientImage) : null,
                child: _recipientImage.isEmpty
                    ? Text(
                        _recipientName.isNotEmpty ? _recipientName[0] : '؟',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _recipientName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'block') {
                  await _messagingService.toggleBlockUser(widget.chatId, _currentUserId!);
                } else if (value == 'report') {
                  _showReportDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'block',
                  child: Text(_isBlockedByMe ? 'إلغاء الحظر' : 'حظر المستخدمة'),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: Text('إبلاغ عن إساءة'),
                ),
              ],
            ),
          ],
        ),
        body: _isLoadingRecipient
            ? const Center(child: CircularProgressIndicator(color: _teal))
            : Column(
                children: [
                  Expanded(child: _buildMessagesList()),
                  _buildInputArea(),
                ],
              ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _messagingService.getMessagesStream(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _teal));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'تحدثي بأمان وخصوصية تامة مع أختكِ في الله',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final message = docs[index].data();
            final isMe = message['senderId'] == _currentUserId;
            return _buildMessageBubble(message, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final text = message['text'] as String? ?? '';
    final createdAt = message['createdAt'] as Timestamp?;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? _teal : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF2D2D3A),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            if (createdAt != null)
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  _formatMessageTime(createdAt),
                  style: TextStyle(
                    color: isMe ? Colors.white60 : Colors.grey.shade400,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    if (_isBlockedByMe) {
      return Container(
        color: Colors.amber.shade50,
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: Text(
          'لقد قمتِ بحظر هذه المستخدمة. قومي بإلغاء الحظر من القائمة العلوية لتتمكني من مراسلتها مجدداً.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.amber.shade800, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (_isBlockedByOther) {
      return Container(
        color: Colors.grey.shade100,
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: const Text(
          'لا يمكنكِ إرسال رسائل لهذه المحادثة حالياً.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    hintText: 'اكتبي رسالتكِ هنا...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: _pink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
