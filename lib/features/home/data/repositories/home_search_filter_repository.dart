import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/room_search_filter_model.dart';

// Lưu và lấy bộ lọc tìm phòng của user từ Firestore (lưu trong document user)
class HomeSearchFilterRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HomeSearchFilterRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<RoomSearchFilterModel> getSavedFilter() async {
    final uid = currentUserId;
    if (uid == null) return const RoomSearchFilterModel();

    final doc = await _firestore.collection('users').doc(uid).get();
    return RoomSearchFilterModel.fromMap(doc.data()?['roomSearchFilter']);
  }

  Future<void> saveFilter(RoomSearchFilterModel filter) async {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    await _firestore.collection('users').doc(uid).set({
      'roomSearchFilter': filter.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  Future<void> clearSavedFilter() async {
    final uid = currentUserId;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).set({
      'roomSearchFilter': const RoomSearchFilterModel().toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
