import 'package:cloud_firestore/cloud_firestore.dart';

enum RoommateRequestStatus { pending, accepted, rejected }

enum RoommateInviteType { postRequest, profileInvite }

class RoommateRequestModel {
  final String id;
  final String postId;
  final String postOwnerId;
  final String requesterId;
  final String requesterName;
  final String requesterAvatar;
  final String message;
  final RoommateRequestStatus status;
  final RoommateInviteType inviteType;
  final String targetName;
  final String targetAvatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? respondedAt;

  const RoommateRequestModel({
    required this.id,
    required this.postId,
    required this.postOwnerId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterAvatar,
    required this.message,
    required this.status,
    this.inviteType = RoommateInviteType.postRequest,
    this.targetName = '',
    this.targetAvatar = '',
    this.createdAt,
    this.updatedAt,
    this.respondedAt,
  });

  factory RoommateRequestModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return RoommateRequestModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      postOwnerId: data['postOwnerId'] ?? '',
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      requesterAvatar: data['requesterAvatar'] ?? '',
      message: data['message'] ?? '',
      status: _parseStatus(data['status']),
      inviteType: _parseInviteType(data['inviteType']),
      targetName: data['targetName'] ?? '',
      targetAvatar: data['targetAvatar'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'postOwnerId': postOwnerId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterAvatar': requesterAvatar,
      'message': message,
      'status': status.name,
      'inviteType':
          inviteType == RoommateInviteType.profileInvite ? 'profile_invite' : 'post_request',
      'targetName': targetName,
      'targetAvatar': targetAvatar,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  RoommateRequestModel copyWith({
    String? id,
    String? postId,
    String? postOwnerId,
    String? requesterId,
    String? requesterName,
    String? requesterAvatar,
    String? message,
    RoommateRequestStatus? status,
    RoommateInviteType? inviteType,
    String? targetName,
    String? targetAvatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? respondedAt,
  }) {
    return RoommateRequestModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      postOwnerId: postOwnerId ?? this.postOwnerId,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterAvatar: requesterAvatar ?? this.requesterAvatar,
      message: message ?? this.message,
      status: status ?? this.status,
      inviteType: inviteType ?? this.inviteType,
      targetName: targetName ?? this.targetName,
      targetAvatar: targetAvatar ?? this.targetAvatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  static RoommateRequestStatus _parseStatus(dynamic value) {
    switch (value) {
      case 'accepted':
        return RoommateRequestStatus.accepted;
      case 'rejected':
        return RoommateRequestStatus.rejected;
      default:
        return RoommateRequestStatus.pending;
    }
  }

  static RoommateInviteType _parseInviteType(dynamic value) {
    if (value == 'profile_invite') return RoommateInviteType.profileInvite;
    return RoommateInviteType.postRequest;
  }
}
