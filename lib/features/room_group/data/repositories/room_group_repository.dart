import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/room_group_model.dart';

class RoomGroupRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  RoomGroupRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('room_groups');

  Future<RoomGroupModel> createGroupAfterAcceptRequest({
    required String ownerId,
    required String requesterId,
    required String postId,
    required String groupName,
  }) async {
    try {
      final docRef = _collection.doc();
      final model = RoomGroupModel(
        id: docRef.id,
        name: groupName,
        ownerId: ownerId,
        memberIds: [ownerId, requesterId],
        postId: postId,
        createdAt: DateTime.now(),
        status: 'active',
      );
      await docRef.set(model.toMap());
      return model;
    } catch (e) {
      throw Exception('Không thể tạo nhóm phòng: $e');
    }
  }

  Future<List<RoomGroupModel>> getUserRoomGroups(String userId) async {
    try {
      final snapshot = await _collection
          .where('memberIds', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => RoomGroupModel.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách nhóm: $e');
    }
  }

  Future<RoomGroupModel?> getRoomGroupById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return null;
      return RoomGroupModel.fromDocument(doc);
    } catch (e) {
      throw Exception('Không thể tải nhóm phòng: $e');
    }
  }

  Future<void> disbandGroup(String groupId) async {
    final user = currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final doc = await _collection.doc(groupId).get();
    if (!doc.exists) throw Exception('Nhóm không tồn tại');

    final data = doc.data()!;
    if (data['ownerId'] != user.uid) {
      throw Exception('Chỉ trưởng nhóm mới có thể giải tán nhóm');
    }
    if (data['status'] == 'disbanded') {
      throw Exception('Nhóm đã được giải tán rồi');
    }

    await _collection.doc(groupId).update({'status': 'disbanded'});
  }
}
