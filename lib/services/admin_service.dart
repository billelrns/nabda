import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ─── Role Enum ───
enum AdminRole { owner, supervisor, employee, user }

// ─── Permission Types ───
enum Permission {
  viewDashboard,
  viewFinancials,
  manageOrders,
  manageProducts,
  addProducts,
  editProducts,
  deleteProducts,
  manageArticles,
  addArticles,
  editArticles,
  deleteArticles,
  manageUsers,
  viewUsers,
  banUsers,
  manageStaff,
  manageCoupons,
  sendNotifications,
  manageSettings,
}

// ─── Role Permissions Map ───
const Map<AdminRole, Set<Permission>> rolePermissions = {
  AdminRole.owner: {
    Permission.viewDashboard,
    Permission.viewFinancials,
    Permission.manageOrders,
    Permission.manageProducts,
    Permission.addProducts,
    Permission.editProducts,
    Permission.deleteProducts,
    Permission.manageArticles,
    Permission.addArticles,
    Permission.editArticles,
    Permission.deleteArticles,
    Permission.manageUsers,
    Permission.viewUsers,
    Permission.banUsers,
    Permission.manageStaff,
    Permission.manageCoupons,
    Permission.sendNotifications,
    Permission.manageSettings,
  },
  AdminRole.supervisor: {
    Permission.viewDashboard,
    Permission.manageOrders,
    Permission.manageProducts,
    Permission.addProducts,
    Permission.editProducts,
    Permission.deleteProducts,
    Permission.manageArticles,
    Permission.addArticles,
    Permission.editArticles,
    Permission.deleteArticles,
    Permission.viewUsers,
    Permission.manageCoupons,
    Permission.sendNotifications,
  },
  AdminRole.employee: {
    Permission.addProducts,
    Permission.editProducts,
    Permission.addArticles,
    Permission.editArticles,
  },
  AdminRole.user: {},
};

// ─── Staff Member Model ───
class StaffMember {
  final String uid;
  final String email;
  final String name;
  final AdminRole role;
  final DateTime createdAt;
  final String? createdBy;
  final bool isActive;

  const StaffMember({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.createdBy,
    this.isActive = true,
  });

  factory StaffMember.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StaffMember(
      uid: doc.id,
      email: d['email'] ?? '',
      name: d['name'] ?? '',
      role: AdminRole.values.firstWhere(
        (r) => r.name == d['role'],
        orElse: () => AdminRole.user,
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: d['createdBy'],
      isActive: d['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'role': role.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'createdBy': createdBy,
    'isActive': isActive,
  };
}

// ─── Admin Service (Singleton) ───
class AdminService extends ChangeNotifier {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  AdminRole _currentRole = AdminRole.user;
  StaffMember? _currentStaff;
  bool _isLoaded = false;

  AdminRole get currentRole => _currentRole;
  StaffMember? get currentStaff => _currentStaff;
  bool get isAdmin => _currentRole != AdminRole.user;
  bool get isOwner => _currentRole == AdminRole.owner;
  bool get isSupervisor => _currentRole == AdminRole.supervisor;
  bool get isEmployee => _currentRole == AdminRole.employee;

  // ─── Check if current user has a specific permission ───
  bool hasPermission(Permission p) {
    return rolePermissions[_currentRole]?.contains(p) ?? false;
  }

  // ─── Initialize: check current user's role ───
  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _currentRole = AdminRole.user;
      _isLoaded = true;
      notifyListeners();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('staff')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _currentStaff = StaffMember.fromFirestore(doc);
        if (_currentStaff!.isActive) {
          _currentRole = _currentStaff!.role;
        } else {
          _currentRole = AdminRole.user;
        }
      } else {
        _currentRole = AdminRole.user;
      }
    } catch (_) {
      _currentRole = AdminRole.user;
    }

    _isLoaded = true;
    notifyListeners();
  }

  // ─── Add new staff member (Owner only) ───
  Future<bool> addStaffMember({
    required String email,
    required String name,
    required AdminRole role,
  }) async {
    if (!hasPermission(Permission.manageStaff)) return false;

    try {
      // Find user by email in users collection
      final users = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      String uid;
      if (users.docs.isNotEmpty) {
        uid = users.docs.first.id;
      } else {
        // Create a placeholder with email as ID
        uid = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      }

      final staff = StaffMember(
        uid: uid,
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
        createdBy: FirebaseAuth.instance.currentUser?.uid,
      );

      await FirebaseFirestore.instance
          .collection('staff')
          .doc(uid)
          .set(staff.toMap());

      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Update staff role ───
  Future<bool> updateStaffRole(String uid, AdminRole newRole) async {
    if (!hasPermission(Permission.manageStaff)) return false;
    try {
      await FirebaseFirestore.instance.collection('staff').doc(uid).update({
        'role': newRole.name,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Deactivate staff member ───
  Future<bool> deactivateStaff(String uid) async {
    if (!hasPermission(Permission.manageStaff)) return false;
    try {
      await FirebaseFirestore.instance.collection('staff').doc(uid).update({
        'isActive': false,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Get all staff members stream ───
  Stream<List<StaffMember>> get staffStream {
    return FirebaseFirestore.instance
        .collection('staff')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StaffMember.fromFirestore(d)).toList());
  }

  // ─── Role display helpers ───
  static String roleNameAr(AdminRole role) {
    switch (role) {
      case AdminRole.owner: return 'المالك';
      case AdminRole.supervisor: return 'مشرف';
      case AdminRole.employee: return 'موظف';
      case AdminRole.user: return 'مستخدم';
    }
  }

  static Color roleColor(AdminRole role) {
    switch (role) {
      case AdminRole.owner: return const Color(0xFF7E57C2);
      case AdminRole.supervisor: return const Color(0xFF42A5F5);
      case AdminRole.employee: return const Color(0xFF66BB6A);
      case AdminRole.user: return const Color(0xFF9E9E9E);
    }
  }

  static IconData roleIcon(AdminRole role) {
    switch (role) {
      case AdminRole.owner: return Icons.admin_panel_settings;
      case AdminRole.supervisor: return Icons.supervisor_account;
      case AdminRole.employee: return Icons.person_outline;
      case AdminRole.user: return Icons.person;
    }
  }
}
