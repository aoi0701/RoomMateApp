import 'package:flutter/foundation.dart';

import '../../data/models/room_group_model.dart';
import '../../data/repositories/room_group_repository.dart';

class RoomGroupViewModel extends ChangeNotifier {
  final RoomGroupRepository _repository;

  RoomGroupViewModel({RoomGroupRepository? repository})
      : _repository = repository ?? RoomGroupRepository();

  bool _isLoading = false;
  String? _errorMessage;
  List<RoomGroupModel> _roomGroups = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<RoomGroupModel> get roomGroups => _roomGroups;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadUserRoomGroups(String userId) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      _roomGroups = await _repository.getUserRoomGroups(userId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> disbandGroup(String groupId) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      await _repository.disbandGroup(groupId);
      _roomGroups = _roomGroups
          .map((g) => g.id == groupId ? g.copyWith(status: 'disbanded') : g)
          .toList();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
