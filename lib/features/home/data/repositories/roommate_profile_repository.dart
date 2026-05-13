import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../post/data/models/post_model.dart';
import '../../../profile/data/models/profile_habit_model.dart';
import '../../../profile/data/models/user_model.dart';
import '../helpers/home_formatters.dart';
import '../helpers/roommate_match_helper.dart';
import '../models/roommate_profile_model.dart';

class RoommateProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RoommateProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<List<RoommateProfileModel>> getSuggestedProfilesStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return const Stream<List<RoommateProfileModel>>.empty();
    }

    return _firestore.collection('users').snapshots().asyncMap((snapshot) async {
      final postSnapshot = await _firestore.collection('posts').get();
      final postsByOwner = <String, List<PostModel>>{};

      for (final doc in postSnapshot.docs) {
        final post = PostModel.fromDocument(doc);
        postsByOwner.putIfAbsent(post.ownerId, () => <PostModel>[]).add(post);
      }

      final users = snapshot.docs
          .map((doc) => UserModel.fromDocument(doc))
          .where((user) => user.role != 'admin')
          .toList();

      final currentUser = users.cast<UserModel?>().firstWhere(
            (user) => user?.uid == currentUserId,
            orElse: () => null,
          );

      final currentHabits = currentUser?.habits ?? const <String>[];
      final currentCriteria = currentUser?.roommateCriteria ?? const <String>[];
      final currentPosts = currentUser == null
          ? const <PostModel>[]
          : (postsByOwner[currentUser.uid] ?? const <PostModel>[]);
      final currentResolvedAddress = currentUser == null
          ? ''
          : _resolveSuggestedAddress(currentUser, currentPosts);
      final currentResolvedBudgetRange = currentUser == null
          ? ''
          : _resolveBudgetRange(currentUser, currentPosts);

      final suggestions = users
          .where((user) => user.uid != currentUserId)
          .map((user) {
            final userPosts = postsByOwner[user.uid] ?? const <PostModel>[];
            final resolvedAddress = _resolveSuggestedAddress(user, userPosts);
            final resolvedBudgetRange = _resolveBudgetRange(user, userPosts);

            final matchPercentage = calculateRoommateMatchPercentage(
              currentHabits: currentHabits,
              currentCriteria: currentCriteria,
              targetHabits: user.habits,
              targetCriteria: user.roommateCriteria,
              currentBudgetRange: currentResolvedBudgetRange,
              targetBudgetRange: resolvedBudgetRange,
              currentAddress: currentResolvedAddress,
              targetAddress: resolvedAddress,
            );

            return RoommateProfileModel(
              userId: user.uid,
              fullName: user.fullName,
              displayName: formatLastTwoWords(user.fullName),
              avatarUrl: user.avatarUrl,
              address: resolvedAddress,
              budgetRange: resolvedBudgetRange,
              habits: user.habits
                  .map((id) => ProfileHabitCatalog.findById(id)?.label ?? id)
                  .toList(),
              roommateCriteria: user.roommateCriteria,
              bio: user.bio.trim(),
              gender: user.gender.trim(),
              age: user.age,
              occupation: user.occupation.trim(),
              matchPercentage: matchPercentage,
            );
          })
          .toList()
        ..sort((a, b) {
          final matchCompare = b.matchPercentage.compareTo(a.matchPercentage);
          if (matchCompare != 0) return matchCompare;
          return a.displayName.compareTo(b.displayName);
        });

      return suggestions;
    });
  }

  String _resolveSuggestedAddress(UserModel user, List<PostModel> posts) {
    if (user.address.trim().isNotEmpty || user.preferredLocation.trim().isNotEmpty) {
      return formatReadableAddress(
        fullAddress: user.address,
        preferredLocation: user.preferredLocation,
      );
    }

    if (posts.isEmpty) {
      return 'Chưa cập nhật';
    }

    final latestPost = posts.first;
    return formatReadableAddress(
      fullAddress: latestPost.location,
      district: latestPost.district,
      province: latestPost.province,
    );
  }

  String _resolveBudgetRange(UserModel user, List<PostModel> posts) {
    if (user.budgetRange.trim().isNotEmpty) {
      return user.budgetRange.trim();
    }

    final validPrices = posts
        .map((post) => post.price)
        .where((price) => price > 0)
        .toList()
      ..sort();

    if (validPrices.isEmpty) {
      return 'Chưa cập nhật';
    }

    final minPrice = validPrices.first;
    final maxPrice = validPrices.last;
    if (minPrice == maxPrice) {
      return '${_formatMoney(minPrice)}đ/tháng';
    }
    return '${_formatMoney(minPrice)} - ${_formatMoney(maxPrice)}đ/tháng';
  }

  String _formatMoney(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = text.length - 1; i >= 0; i--) {
      buffer.write(text[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  Future<void> sendInvite({
    required String targetUserId,
    required String targetName,
    required String targetAvatar,
    String message = '',
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Người dùng chưa đăng nhập');
    if (currentUser.uid == targetUserId) throw Exception('Bạn không thể mời chính mình');

    final duplicate = await _firestore
        .collection('roommate_requests')
        .where('requesterId', isEqualTo: currentUser.uid)
        .where('postOwnerId', isEqualTo: targetUserId)
        .where('inviteType', isEqualTo: 'profile_invite')
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      throw Exception('Bạn đã gửi lời mời cho người này rồi');
    }

    final senderDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
    final sender = senderDoc.exists ? UserModel.fromDocument(senderDoc) : null;

    await _firestore.collection('roommate_requests').add({
      'postId': '',
      'postOwnerId': targetUserId,
      'requesterId': currentUser.uid,
      'requesterName': sender?.fullName ?? currentUser.displayName ?? '',
      'requesterAvatar': sender?.avatarUrl ?? currentUser.photoURL ?? '',
      'message': message.trim(),
      'status': 'pending',
      'inviteType': 'profile_invite',
      'targetName': targetName,
      'targetAvatar': targetAvatar,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
    });
  }
}
