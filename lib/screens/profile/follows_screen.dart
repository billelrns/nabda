import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../community/user_profile_screen.dart';

class FollowsScreen extends StatelessWidget {
  final String type; // 'followers' or 'following'
  final String title;

  const FollowsScreen({
    Key? key,
    required this.type,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isFollowers = type == 'followers';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: uid == null
            ? const Center(child: Text('سجّلي الدخول أولاً'))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection(type)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF00897B)));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isFollowers ? Icons.favorite_border : Icons.people_outline,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isFollowers ? 'لا توجد متابعات بعد' : 'لم تتابعي أحداً بعد',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isFollowers
                                  ? 'شاركي بتجاربك في المجتمع لتتابِعكِ الأمهات الأخريات.'
                                  : 'تابعي الأمهات والكاتبات المفضلات لديكِ لتصلي لمنشوراتهن أولاً بأول.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final targetUid = docs[i].id;
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users_directory')
                            .doc(targetUid)
                            .get(),
                        builder: (context, snap) {
                          final data = snap.data?.data() as Map<String, dynamic>?;
                          final name = data?['displayName'] ?? data?['name'] ?? 'مستخدمة';
                          final avatar = data?['avatar'] as String? ?? data?['photoUrl'] as String?;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 1,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFE0F2F1),
                                backgroundImage: (avatar != null && avatar.isNotEmpty)
                                    ? NetworkImage(avatar)
                                    : null,
                                child: (avatar == null || avatar.isEmpty)
                                    ? Text(
                                        name.isNotEmpty ? name[0] : 'م',
                                        style: const TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 18),
                                      )
                                    : null,
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Text(
                                isFollowers ? 'تتابع حسابكِ' : 'أنتِ تتابعينها',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              trailing: !isFollowers
                                  ? OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.red.shade300),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      onPressed: () async {
                                        await docs[i].reference.delete();
                                        // Also remove from target's followers
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(targetUid)
                                              .collection('followers')
                                              .doc(uid)
                                              .delete();
                                        } catch (_) {}
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('تم إلغاء متابعة $name')),
                                          );
                                        }
                                      },
                                      child: Text(
                                        'إلغاء المتابعة',
                                        style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                                      ),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00897B),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => UserProfileScreen(userId: targetUid),
                                          ),
                                        );
                                      },
                                      child: const Text('الملف الشخصي', style: TextStyle(fontSize: 12)),
                                    ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserProfileScreen(userId: targetUid),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
