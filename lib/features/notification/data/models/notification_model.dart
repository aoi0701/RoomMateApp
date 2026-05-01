import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String fromUserId;
  final String refId;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.fromUserId,
    required this.refId,
    this.createdAt,
  });

  factory NotificationModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      isRead: data['isRead'] ?? false,
      fromUserId: data['fromUserId'] ?? '',
      refId: data['refId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'isRead': isRead,
      'fromUserId': fromUserId,
      'refId': refId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
