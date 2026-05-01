import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/roommate_request_model.dart';
import '../../../notification/data/repositories/notification_repository.dart';

class RoommateRequestRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final NotificationRepository _notificationRepository;

  RoommateRequestRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    NotificationRepository? notificationRepository,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationRepository = notificationRepository ?? NotificationRepository();

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _requestRef =>
      _firestore.collection('roommate_requests');

  CollectionReference<Map<String, dynamic>> get _postRef =>
      _firestore.collection('posts');

  Future<void> sendRequest({
    required String postId,
    required String message,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    final postDoc = await _postRef.doc(postId).get();

    if (!postDoc.exists) {
      throw Exception('Bài đăng không tồn tại');
    }

    final postData = postDoc.data()!;
    final postOwnerId = postData['ownerId'] ?? '';

    if (postOwnerId.isEmpty) {
      throw Exception('Không tìm thấy chủ bài đăng');
    }

    if (postOwnerId == user.uid) {
      throw Exception('Bạn không thể gửi yêu cầu cho bài đăng của chính mình');
    }

    final duplicateQuery = await _requestRef
        .where('postId', isEqualTo: postId)
        .where('requesterId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (duplicateQuery.docs.isNotEmpty) {
      throw Exception('Bạn đã gửi yêu cầu cho bài đăng này rồi');
    }

    await _requestRef.add({
      'postId': postId,
      'postOwnerId': postOwnerId,
      'requesterId': user.uid,
      'requesterName': user.displayName ?? '',
      'requesterAvatar': user.photoURL ?? '',
      'message': message.trim(),
      'status': RoommateRequestStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
    });

    await _notificationRepository.createNotification(
      userId: postOwnerId,
      type: 'roommate_request',
      title: 'Yêu cầu ghép phòng mới',
      body: '${user.displayName ?? 'Ai đó'} đã gửi yêu cầu ghép phòng cho bạn.',
      fromUserId: user.uid,
      refId: postId,
    );
  }

  Stream<List<RoommateRequestModel>> getReceivedRequests() {
    final user = currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _requestRef
        .where('postOwnerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RoommateRequestModel.fromDocument(doc))
              .toList(),
        );
  }

  Stream<List<RoommateRequestModel>> getSentRequests() {
    final user = currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _requestRef
        .where('requesterId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RoommateRequestModel.fromDocument(doc))
              .toList(),
        );
  }

  Future<void> acceptRequest(String requestId) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final requestDoc = await _requestRef.doc(requestId).get();

    if (!requestDoc.exists) {
      throw Exception('Yêu cầu không tồn tại');
    }

    final data = requestDoc.data()!;
    if (data['postOwnerId'] != user.uid) {
      throw Exception('Bạn không có quyền chấp nhận yêu cầu này');
    }

    if (data['status'] != RoommateRequestStatus.pending.name) {
      throw Exception('Yêu cầu này đã được xử lý rồi');
    }

    await _requestRef.doc(requestId).update({
      'status': RoommateRequestStatus.accepted.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'respondedAt': FieldValue.serverTimestamp(),
    });

    await _notificationRepository.createNotification(
      userId: data['requesterId'],
      type: 'request_accepted',
      title: 'Yêu cầu được chấp nhận',
      body: 'Yêu cầu ghép phòng của bạn đã được chấp nhận.',
      fromUserId: user.uid,
      refId: requestId,
    );
  }

  Future<void> rejectRequest(String requestId) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final requestDoc = await _requestRef.doc(requestId).get();

    if (!requestDoc.exists) {
      throw Exception('Yêu cầu không tồn tại');
    }

    final data = requestDoc.data()!;
    if (data['postOwnerId'] != user.uid) {
      throw Exception('Bạn không có quyền từ chối yêu cầu này');
    }

    if (data['status'] != RoommateRequestStatus.pending.name) {
      throw Exception('Yêu cầu này đã được xử lý rồi');
    }

    await _requestRef.doc(requestId).update({
      'status': RoommateRequestStatus.rejected.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'respondedAt': FieldValue.serverTimestamp(),
    });

    await _notificationRepository.createNotification(
      userId: data['requesterId'],
      type: 'request_rejected',
      title: 'Yêu cầu bị từ chối',
      body: 'Yêu cầu ghép phòng của bạn đã bị từ chối.',
      fromUserId: user.uid,
      refId: requestId,
    );
  }

  Future<bool> hasPendingRequest(String postId) async {
    final user = currentUser;

    if (user == null) {
      return false;
    }

    final query = await _requestRef
        .where('postId', isEqualTo: postId)
        .where('requesterId', isEqualTo: user.uid)
        .where('status', isEqualTo: RoommateRequestStatus.pending.name)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }
}