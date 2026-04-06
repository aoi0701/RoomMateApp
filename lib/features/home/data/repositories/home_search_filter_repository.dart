import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/room_search_filter_model.dart';

class HomeSearchFilterRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HomeSearchFilterRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<RoomSearchFilterModel> getSavedFilter() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const RoomSearchFilterModel();

    final doc = await _firestore.collection('users').doc(uid).get();
    return RoomSearchFilterModel.fromMap(doc.data()?['roomSearchFilter']);
  }

  Future<void> saveFilter(RoomSearchFilterModel filter) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    await _firestore.collection('users').doc(uid).set({
      'roomSearchFilter': filter.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  Future<void> clearSavedFilter() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).set({
      'roomSearchFilter': const RoomSearchFilterModel().toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
