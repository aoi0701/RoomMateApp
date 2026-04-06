import 'package:cloud_firestore/cloud_firestore.dart';
import '../mappers/habit_roommate_criteria_mapper.dart';
import '../../data/models/user_model.dart';

class UserProfileRepository {
  final FirebaseFirestore _firestore;

  UserProfileRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    return UserModel.fromDocument(doc);
  }

  Stream<bool> hasUserPostsStream(String uid) {
    return _firestore
        .collection('posts')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  Future<void> updateHabits({
    required String uid,
    required List<String> habits,
  }) async {
    final normalizedHabits = habits.toSet().toList();
    final criteria = HabitRoommateCriteriaMapper.mapHabitsToRoommateCriteria(
      normalizedHabits,
    );

    await _firestore.collection('users').doc(uid).update({
      'habits': normalizedHabits,
      'roommateCriteria': criteria,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
