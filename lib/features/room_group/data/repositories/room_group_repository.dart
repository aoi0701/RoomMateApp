import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/room_group_model.dart';

class RoomGroupRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  RoomGroupRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('room_groups');

  // Tạo nhóm phòng mới khi chủ bài chấp nhận yêu cầu — gồm cả 2 người: chủ và người xin
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

  // Lấy danh sách nhóm phòng của user, đồng thời batch-fetch tên thành viên từ collection users
  Future<List<RoomGroupModel>> getUserRoomGroups(String userId) async {
    try {
      final snapshot = await _collection
          .where('memberIds', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();
      final groups = snapshot.docs
          .map((doc) => RoomGroupModel.fromDocument(doc))
          .toList();

      // Gom tất cả memberIds duy nhất từ các nhóm để fetch tên 1 lần
      final allMemberIds = groups
          .expand((g) => g.memberIds)
          .toSet()
          .toList();

      if (allMemberIds.isEmpty) return groups;

      // Batch fetch tên user song song
      final userDocs = await Future.wait(
        allMemberIds.map((uid) => _firestore.collection('users').doc(uid).get()),
      );
      final nameById = <String, String>{};
      for (final doc in userDocs) {
        if (doc.exists) {
          nameById[doc.id] = (doc.data()?['fullName'] as String?) ?? '';
        }
      }

      return groups.map((group) {
        final names = group.memberIds
            .map((id) => nameById[id] ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
        return group.copyWith(memberNames: names);
      }).toList();
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

  // Giải tán nhóm: chỉ trưởng nhóm mới có quyền, đặt status = 'disbanded'
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
