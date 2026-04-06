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
  final String role;
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
    required this.role,
    this.createdAt,
  });

  /// 🔹 from Firestore Document
  factory UserModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      preferredLocation: data['preferredLocation'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      budgetRange: data['budgetRange'] ?? '',
      bio: data['bio'] ?? '',
      gender: data['gender'] ?? '',
      age: data['age'] is num ? (data['age'] as num).toInt() : null,
      occupation: data['occupation'] ?? '',
      habits: List<String>.from(data['habits'] ?? const []),
      roommateCriteria:
          List<String>.from(data['roommateCriteria'] ?? const []),
      role: data['role'] ?? 'user',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// 🔹 from Map
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      preferredLocation: map['preferredLocation'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      budgetRange: map['budgetRange'] ?? '',
      bio: map['bio'] ?? '',
      gender: map['gender'] ?? '',
      age: map['age'] is num ? (map['age'] as num).toInt() : null,
      occupation: map['occupation'] ?? '',
      habits: List<String>.from(map['habits'] ?? const []),
      roommateCriteria:
          List<String>.from(map['roommateCriteria'] ?? const []),
      role: map['role'] ?? 'user',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// 🔹 to Map (ghi lên Firestore)
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
      'role': role,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// 🔹 copyWith
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
    String? role,
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
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
