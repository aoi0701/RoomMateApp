import 'package:cloud_firestore/cloud_firestore.dart';

class RoomGroupModel {
  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final String postId;
  final DateTime? createdAt;
  final String status;

  const RoomGroupModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.postId,
    this.createdAt,
    required this.status,
  });

  factory RoomGroupModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return RoomGroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      postId: data['postId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'postId': postId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'status': status,
    };
  }

  RoomGroupModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    List<String>? memberIds,
    String? postId,
    DateTime? createdAt,
    String? status,
  }) {
    return RoomGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      postId: postId ?? this.postId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
