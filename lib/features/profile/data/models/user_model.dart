import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String preferredLocation;
  final String avatarUrl;
  final String budgetRange;
  final String bio;
  final String gender;
  final int? age;
  final String occupation;
  final List<String> habits;
  final List<String> roommateCriteria;
  final bool profileCompleted;
  final String role;
  final bool deleted;
  final bool isBlocked;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.preferredLocation,
    required this.avatarUrl,
    required this.budgetRange,
    required this.bio,
    required this.gender,
    required this.age,
    required this.occupation,
    required this.habits,
    required this.roommateCriteria,
    required this.profileCompleted,
    required this.role,
    this.deleted = false,
    this.isBlocked = false,
    this.createdAt,
  });

  static bool _computeProfileCompleted({
    required String address,
    required String gender,
    required List<String> habits,
    required List<String> roommateCriteria,
  }) {
    return address.trim().isNotEmpty &&
        gender.trim().isNotEmpty &&
        habits.isNotEmpty &&
        roommateCriteria.isNotEmpty;
  }

  // Tạo UserModel từ Firestore Document snapshot
  factory UserModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final address = data['address'] ?? '';
    final gender = data['gender'] ?? '';
    final habits = List<String>.from(data['habits'] ?? const []);
    final roommateCriteria =
        List<String>.from(data['roommateCriteria'] ?? const []);

    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: address,
      preferredLocation: data['preferredLocation'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      budgetRange: data['budgetRange'] ?? '',
      bio: data['bio'] ?? '',
      gender: gender,
      age: data['age'] is num ? (data['age'] as num).toInt() : null,
      occupation: data['occupation'] ?? '',
      habits: habits,
      roommateCriteria: roommateCriteria,
      profileCompleted: data['profileCompleted'] is bool
          ? data['profileCompleted'] as bool
          : _computeProfileCompleted(
              address: address,
              gender: gender,
              habits: habits,
              roommateCriteria: roommateCriteria,
            ),
      role: data['role'] ?? 'user',
      deleted: data['deleted'] == true || data['isDeleted'] == true,
      isBlocked: data['isBlocked'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Tạo UserModel từ Map thông thường (dùng cho các luồng không qua Firestore DocumentSnapshot)
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    final address = map['address'] ?? '';
    final gender = map['gender'] ?? '';
    final habits = List<String>.from(map['habits'] ?? const []);
    final roommateCriteria =
        List<String>.from(map['roommateCriteria'] ?? const []);

    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: address,
      preferredLocation: map['preferredLocation'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      budgetRange: map['budgetRange'] ?? '',
      bio: map['bio'] ?? '',
      gender: gender,
      age: map['age'] is num ? (map['age'] as num).toInt() : null,
      occupation: map['occupation'] ?? '',
      habits: habits,
      roommateCriteria: roommateCriteria,
      profileCompleted: map['profileCompleted'] is bool
          ? map['profileCompleted'] as bool
          : _computeProfileCompleted(
              address: address,
              gender: gender,
              habits: habits,
              roommateCriteria: roommateCriteria,
            ),
      role: map['role'] ?? 'user',
      deleted: map['deleted'] == true || map['isDeleted'] == true,
      isBlocked: map['isBlocked'] == true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Chuyển UserModel thành Map để ghi lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'preferredLocation': preferredLocation,
      'avatarUrl': avatarUrl,
      'budgetRange': budgetRange,
      'bio': bio,
      'gender': gender,
      'age': age,
      'occupation': occupation,
      'habits': habits,
      'roommateCriteria': roommateCriteria,
      'profileCompleted': profileCompleted,
      'role': role,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // Tạo bản sao UserModel với một số trường được thay thế
  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? preferredLocation,
    String? avatarUrl,
    String? budgetRange,
    String? bio,
    String? gender,
    int? age,
    String? occupation,
    List<String>? habits,
    List<String>? roommateCriteria,
    bool? profileCompleted,
    String? role,
    bool? deleted,
    bool? isBlocked,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      budgetRange: budgetRange ?? this.budgetRange,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      occupation: occupation ?? this.occupation,
      habits: habits ?? this.habits,
      roommateCriteria: roommateCriteria ?? this.roommateCriteria,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      role: role ?? this.role,
      deleted: deleted ?? this.deleted,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
