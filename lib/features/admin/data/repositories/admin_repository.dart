import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../post/data/models/post_model.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../roommate/data/models/roommate_request_model.dart';

class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<int> getUsersCountStream() =>
      _firestore.collection('users').snapshots().map((snapshot) => snapshot.size);

  Stream<int> getPostsCountStream() =>
      _firestore.collection('posts').snapshots().map((snapshot) => snapshot.size);

  Stream<int> getRequestsCountStream() => _firestore
      .collection('roommate_requests')
      .snapshots()
      .map((snapshot) => snapshot.size);

  Stream<List<UserModel>> getUsersStream({int limit = 10}) {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(UserModel.fromDocument).toList();
    });
  }

  Stream<List<PostModel>> getPostsStream({int limit = 10}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(PostModel.fromDocument).toList();
    });
  }

  Stream<List<RoommateRequestModel>> getRequestsStream({int limit = 10}) {
    return _firestore
        .collection('roommate_requests')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(RoommateRequestModel.fromDocument).toList();
    });
  }

  Future<void> deletePost(String postId) {
    return _firestore.collection('posts').doc(postId).delete();
  }

  Future<void> createPost(Map<String, dynamic> data) {
    return _firestore.collection('posts').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> getBannedUsersCountStream() => _firestore
      .collection('users')
      .where('role', isEqualTo: 'banned')
      .snapshots()
      .map((s) => s.size);

  Future<void> banUser(String uid) =>
      _firestore.collection('users').doc(uid).update({'role': 'banned'});

  Future<void> unbanUser(String uid) =>
      _firestore.collection('users').doc(uid).update({'role': 'user'});
}
