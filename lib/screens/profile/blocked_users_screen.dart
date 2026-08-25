import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        appBar: AppBar(
          title: const Text('المحظورات', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: uid == null
            ? const Center(child: Text('سجّلي الدخول أولاً لعرض المحظورات'))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('blocked')
                    .orderBy('blockedAt', descending: true)
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
                            Icon(Icons.block, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد مستخدمات محظورات',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'عند حظر أي عضوة لن تظهر لكِ منشوراتها أو تعليقاتها، ويمكنكِ إلغاء الحظر من هنا في أي وقت.',
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
                      final blockedUid = docs[i].id;
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users_directory')
                            .doc(blockedUid)
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
                                backgroundColor: Colors.red.shade100,
                                backgroundImage: (avatar != null && avatar.isNotEmpty)
                                    ? NetworkImage(avatar)
                                    : null,
                                child: (avatar == null || avatar.isEmpty)
                                    ? Text(
                                        name.isNotEmpty ? name[0] : 'م',
                                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 18),
                                      )
                                    : null,
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: const Text('محظورة من التفاعل معكِ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              trailing: OutlinedButton.icon(
                                icon: const Icon(Icons.lock_open, size: 18, color: Color(0xFF00897B)),
                                label: const Text(
                                  'إلغاء الحظر',
                                  style: TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF00897B)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                onPressed: () async {
                                  await docs[i].reference.delete();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('تم إلغاء حظر $name بنجاح')),
                                    );
                                  }
                                },
                              ),
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
