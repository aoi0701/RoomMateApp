import 'package:flutter/foundation.dart';

import '../../../post/data/models/post_model.dart';
import '../../../profile/data/models/user_model.dart';
import '../../data/repositories/admin_repository.dart';

class AdminViewModel extends ChangeNotifier {
  final AdminRepository _repository;

  AdminViewModel({required AdminRepository repository})
      : _repository = repository;

  Stream<int> get usersCountStream => _repository.getUsersCountStream();
  Stream<int> get postsCountStream => _repository.getPostsCountStream();
  Stream<int> get requestsCountStream => _repository.getRequestsCountStream();
  Stream<int> get bannedCountStream => _repository.getBannedUsersCountStream();
  Stream<List<UserModel>> get usersStream =>
      _repository.getUsersStream(limit: 100);
  Stream<List<PostModel>> get postsStream =>
      _repository.getPostsStream(limit: 50);

  bool _busy = false;
  bool get busy => _busy;

  Future<void> banUser(String uid) async {
    _busy = true;
    notifyListeners();
    await _repository.banUser(uid);
    _busy = false;
    notifyListeners();
  }

  Future<void> unbanUser(String uid) async {
    _busy = true;
    notifyListeners();
    await _repository.unbanUser(uid);
    _busy = false;
    notifyListeners();
  }

  Future<void> deletePost(String postId) async {
    await _repository.deletePost(postId);
  }
}
