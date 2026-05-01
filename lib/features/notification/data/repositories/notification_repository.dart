import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('notifications');

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _ref
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromDocument(doc))
            .toList());
  }

  Stream<int> getUnreadCountStream(String userId) {
    return _ref
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _ref.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _ref
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    required String fromUserId,
    required String refId,
  }) async {
    await _ref.add({
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'isRead': false,
      'fromUserId': fromUserId,
      'refId': refId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
