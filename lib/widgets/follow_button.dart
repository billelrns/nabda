import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/community_engagement_service.dart';
import '../services/messaging_service.dart';
import '../screens/messaging/chat_room_screen.dart';

// ══════════════════════════════════════════════════════════════
// Follow Button Widget — زر المتابعة الذكي والتفاؤلي لتطبيق نبضة
// يدعم الاستعلام التجميعي بلا خادم ويتراجع بوضوح عند الأخطاء
// ══════════════════════════════════════════════════════════════

class FollowButton extends StatefulWidget {
  final String targetUserId;
  final bool compact;
  final VoidCallback? onFollowChanged;

  const FollowButton({
    Key? key,
    required this.targetUserId,
    this.compact = false,
    this.onFollowChanged,
  }) : super(key: key);

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isActionInProgress = false;

  static const Color _pink = Color(0xFFE91E63);
  static const Color _teal = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // إخفاء الزر إذا كانت المستخدمة تنظر لحسابها أو لحساب فريق نبضة أو غير مسجلة
    if (currentUid == null ||
        widget.targetUserId.isEmpty ||
        widget.targetUserId == currentUid ||
        widget.targetUserId == CommunityEngagementService.teamUserId) {
      return const SizedBox.shrink();
    }

    final followingDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('following')
        .doc(widget.targetUserId);

    final targetFollowersDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.targetUserId)
        .collection('followers')
        .doc(currentUid);

    return StreamBuilder<DocumentSnapshot>(
      stream: followingDocRef.snapshots(),
      builder: (context, snapshot) {
        final isFollowing = snapshot.hasData && snapshot.data!.exists;

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _isActionInProgress
              ? null
              : () async {
                  setState(() => _isActionInProgress = true);
                  try {
                    if (isFollowing) {
                      // إلغاء المتابعة
                      await followingDocRef.delete();
                      await targetFollowersDocRef.delete();
                    } else {
                      // بدء المتابعة
                      final now = FieldValue.serverTimestamp();
                      await followingDocRef.set({'followedAt': now});
                      await targetFollowersDocRef.set({'followedAt': now});
                    }
                    widget.onFollowChanged?.call();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تعذر تحديث المتابعة، تأكدي من اتصالكِ بالإنترنت'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isActionInProgress = false);
                    }
                  }
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 16,
              vertical: widget.compact ? 4 : 8,
            ),
            decoration: BoxDecoration(
              color: isFollowing
                  ? const Color(0xFFF0EFF2)
                  : (widget.compact ? _teal.withOpacity(0.1) : _teal),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isFollowing
                    ? Colors.grey.shade300
                    : (widget.compact ? _teal : Colors.transparent),
                width: 1,
              ),
            ),
            child: _isActionInProgress
                ? SizedBox(
                    width: widget.compact ? 12 : 14,
                    height: widget.compact ? 12 : 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isFollowing ? Colors.grey : (widget.compact ? _teal : Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFollowing ? Icons.check : Icons.add,
                        size: widget.compact ? 12 : 14,
                        color: isFollowing ? const Color(0xFF6A6070) : (widget.compact ? _teal : Colors.white),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFollowing ? 'تتابعينها' : 'متابعة',
                        style: TextStyle(
                          color: isFollowing ? const Color(0xFF6A6070) : (widget.compact ? _teal : Colors.white),
                          fontSize: widget.compact ? 11 : 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Direct Message Button Widget — زر المراسلة السريع والمباشر
// ══════════════════════════════════════════════════════════════

class DirectMessageButton extends StatefulWidget {
  final String targetUserId;
  final String? targetUserName;
  final bool compact;

  const DirectMessageButton({
    Key? key,
    required this.targetUserId,
    this.targetUserName,
    this.compact = false,
  }) : super(key: key);

  @override
  State<DirectMessageButton> createState() => _DirectMessageButtonState();
}

class _DirectMessageButtonState extends State<DirectMessageButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null ||
        widget.targetUserId.isEmpty ||
        widget.targetUserId == currentUid ||
        widget.targetUserId == CommunityEngagementService.teamUserId) {
      return const SizedBox.shrink();
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _isLoading
          ? null
          : () async {
              setState(() => _isLoading = true);
              try {
                final chatId = await MessagingService().getOrCreateChat(
                  currentUid,
                  widget.targetUserId,
                );
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(chatId: chatId),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تعذر فتح المحادثة، يرجى المحاولة لاحقاً'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 8 : 14,
          vertical: widget.compact ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE91E63).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.3), width: 1),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.8, color: Color(0xFFE91E63)),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFFE91E63)),
                  if (!widget.compact) ...[
                    const SizedBox(width: 4),
                    const Text(
                      'مراسلة',
                      style: TextStyle(
                        color: Color(0xFFE91E63),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
