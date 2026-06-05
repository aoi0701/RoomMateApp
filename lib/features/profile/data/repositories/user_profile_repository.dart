import 'package:cloud_firestore/cloud_firestore.dart';

import '../mappers/habit_roommate_criteria_mapper.dart';
import '../../data/models/user_model.dart';

class UserProfileRepository {
  final FirebaseFirestore _firestore;

  UserProfileRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) return null;

      return UserModel.fromDocument(doc);
    } on FirebaseException {
      return null;
    }
  }

  Future<bool> isProfileComplete(String uid) async {
    final profile = await getUserProfile(uid);
    return profile?.profileCompleted ?? false;
  }

  Stream<bool> hasUserPostsStream(String uid) {
    return _firestore
        .collection('posts')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  // Cập nhật thói quen của user, tự động map sang roommateCriteria và tính lại profileCompleted
  Future<void> updateHabits({
    required String uid,
    required List<String> habits,
  }) async {
    final normalizedHabits = habits.toSet().toList();
    final criteria = HabitRoommateCriteriaMapper.mapHabitsToRoommateCriteria(
      normalizedHabits,
    );
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? const <String, dynamic>{};
    final profileCompleted = _computeProfileCompleted(
      address: data['address'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      habits: normalizedHabits,
      roommateCriteria: criteria,
    );

    await _firestore.collection('users').doc(uid).update({
      'habits': normalizedHabits,
      'roommateCriteria': criteria,
      'profileCompleted': profileCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Hoàn thiện hồ sơ lần đầu: lưu phone/address/gender/habits và đánh dấu profileCompleted
  Future<void> completeProfile({
    required String uid,
    required String phone,
    required String address,
    required String gender,
    required List<String> habits,
  }) async {
    final normalizedHabits = habits.toSet().toList();
    final criteria = HabitRoommateCriteriaMapper.mapHabitsToRoommateCriteria(
      normalizedHabits,
    );

    await _firestore.collection('users').doc(uid).set({
      'phone': phone.trim(),
      'address': address.trim(),
      'gender': gender.trim(),
      'habits': normalizedHabits,
      'roommateCriteria': criteria,
      'profileCompleted': _computeProfileCompleted(
        address: address,
        gender: gender,
        habits: normalizedHabits,
        roommateCriteria: criteria,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateBasicInfo({
    required String uid,
    required String fullName,
    required String phone,
    required String address,
    required String gender,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'gender': gender.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Xóa mềm tài khoản: đánh dấu deleted + isBlocked, Cloud Function sẽ xử lý cascade sau
  Future<void> softDeleteAccount(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'deleted': true,
      'isBlocked': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  bool _computeProfileCompleted({
    required String address,
    required String gender,
    required List<String> habits,
    required List<String> roommateCriteria,
  }) {
    return address.trim().isNotEmpty &&
        gender.trim().isNotEmpty &&
        habits.isNotEmpty &&
        roommateCriteria.isNotEmpty;
  }
}
