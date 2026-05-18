import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/roommate_request_model.dart';

class RoommateRequestRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  RoommateRequestRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

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
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final postDoc = await _postRef.doc(postId).get();
    if (!postDoc.exists) throw Exception('Bài đăng không tồn tại');

    final postData = postDoc.data()!;
    final postOwnerId = postData['ownerId'] ?? '';

    if (postOwnerId.isEmpty) throw Exception('Không tìm thấy chủ bài đăng');
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
      'inviteType': 'post_request',
      'targetName': '',
      'targetAvatar': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
    });
  }

  Stream<List<RoommateRequestModel>> getReceivedRequests() {
    final user = currentUser;
    if (user == null) return const Stream.empty();

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
    if (user == null) return const Stream.empty();

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

  Stream<List<RoommateRequestModel>> getSentProfileInvitesStream() {
    final user = currentUser;
    if (user == null) return const Stream.empty();

    return _requestRef
        .where('requesterId', isEqualTo: user.uid)
        .where('inviteType', isEqualTo: 'profile_invite')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RoommateRequestModel.fromDocument(doc))
              .toList(),
        );
  }

  Future<RoommateRequestModel> acceptRequest(String requestId) async {
    final user = currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final requestDoc = await _requestRef.doc(requestId).get();
    if (!requestDoc.exists) throw Exception('Yêu cầu không tồn tại');

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

    return RoommateRequestModel(
      id: requestId,
      postId: data['postId'] ?? '',
      postOwnerId: data['postOwnerId'] ?? '',
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      requesterAvatar: data['requesterAvatar'] ?? '',
      message: data['message'] ?? '',
      status: RoommateRequestStatus.accepted,
      inviteType: data['inviteType'] == 'profile_invite'
          ? RoommateInviteType.profileInvite
          : RoommateInviteType.postRequest,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Future<void> rejectRequest(String requestId) async {
    final user = currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final requestDoc = await _requestRef.doc(requestId).get();
    if (!requestDoc.exists) throw Exception('Yêu cầu không tồn tại');

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
  }

  Future<void> deleteRequest(String requestId) async {
    final user = currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final doc = await _requestRef.doc(requestId).get();
    if (!doc.exists) throw Exception('Yêu cầu không tồn tại');

    final data = doc.data()!;
    final requesterId = data['requesterId'] ?? '';
    final postOwnerId = data['postOwnerId'] ?? '';

    if (user.uid != requesterId && user.uid != postOwnerId) {
      throw Exception('Bạn không có quyền xóa yêu cầu này');
    }

    await _requestRef.doc(requestId).delete();
  }

  Future<bool> hasPendingRequest(String postId) async {
    final user = currentUser;
    if (user == null) return false;

    final query = await _requestRef
        .where('postId', isEqualTo: postId)
        .where('requesterId', isEqualTo: user.uid)
        .where('status', isEqualTo: RoommateRequestStatus.pending.name)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  Future<bool> hasPendingProfileInvite(String targetUserId) async {
    final user = currentUser;
    if (user == null) return false;

    final query = await _requestRef
        .where('requesterId', isEqualTo: user.uid)
        .where('postOwnerId', isEqualTo: targetUserId)
        .where('inviteType', isEqualTo: 'profile_invite')
        .where('status', isEqualTo: RoommateRequestStatus.pending.name)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }
}
