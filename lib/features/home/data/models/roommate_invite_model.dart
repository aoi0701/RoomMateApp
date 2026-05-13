import 'package:cloud_firestore/cloud_firestore.dart';

enum RoommateInviteStatus { pending, accepted, rejected }

class RoommateInviteModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String targetUserId;
  final String targetName;
  final String targetAvatar;
  final String message;
  final RoommateInviteStatus status;
  final DateTime? createdAt;

  const RoommateInviteModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.targetUserId,
    required this.targetName,
    required this.targetAvatar,
    required this.message,
    required this.status,
    this.createdAt,
  });

  factory RoommateInviteModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return RoommateInviteModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderAvatar: data['senderAvatar'] ?? '',
      targetUserId: data['targetUserId'] ?? '',
      targetName: data['targetName'] ?? '',
      targetAvatar: data['targetAvatar'] ?? '',
      message: data['message'] ?? '',
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'targetUserId': targetUserId,
        'targetName': targetName,
        'targetAvatar': targetAvatar,
        'message': message,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

  RoommateInviteModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? targetUserId,
    String? targetName,
    String? targetAvatar,
    String? message,
    RoommateInviteStatus? status,
    DateTime? createdAt,
  }) {
    return RoommateInviteModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      targetUserId: targetUserId ?? this.targetUserId,
      targetName: targetName ?? this.targetName,
      targetAvatar: targetAvatar ?? this.targetAvatar,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static RoommateInviteStatus _parseStatus(dynamic value) {
    switch (value) {
      case 'accepted':
        return RoommateInviteStatus.accepted;
      case 'rejected':
        return RoommateInviteStatus.rejected;
      default:
        return RoommateInviteStatus.pending;
    }
  }
}
