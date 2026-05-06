import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model — mirrors the Firestore `users` collection
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String role; // admin, executive, safety_manager, contractor, employee
  final String? siteId;
  final String? department;
  final String? jobTitle;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final Map<String, dynamic>? preferences;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.role = 'employee',
    this.siteId,
    this.department,
    this.jobTitle,
    this.phone,
    this.createdAt,
    this.lastLogin,
    this.preferences,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? data['name'] ?? '',
      photoURL: data['photoURL'],
      role: data['role'] ?? 'employee',
      siteId: data['siteId'],
      department: data['department'],
      jobTitle: data['jobTitle'],
      phone: data['phone'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      preferences: data['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'displayName': displayName,
    'photoURL': photoURL,
    'role': role,
    'siteId': siteId,
    'department': department,
    'jobTitle': jobTitle,
    'phone': phone,
    'createdAt':
        createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
    'lastLogin': FieldValue.serverTimestamp(),
    'preferences': preferences,
  };

  UserProfile copyWith({
    String? displayName,
    String? photoURL,
    String? role,
    String? siteId,
    String? department,
    String? jobTitle,
    String? phone,
    Map<String, dynamic>? preferences,
  }) => UserProfile(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
    photoURL: photoURL ?? this.photoURL,
    role: role ?? this.role,
    siteId: siteId ?? this.siteId,
    department: department ?? this.department,
    jobTitle: jobTitle ?? this.jobTitle,
    phone: phone ?? this.phone,
    createdAt: createdAt,
    lastLogin: lastLogin,
    preferences: preferences ?? this.preferences,
  );

  bool get isAdmin => role == 'admin';
  bool get isExecutive => role == 'executive' || role == 'admin';
  bool get isSafetyManager => role == 'safety_manager' || isExecutive;
}
