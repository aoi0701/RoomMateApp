import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../room_group/data/repositories/room_group_repository.dart';
import '../../data/models/roommate_request_model.dart';
import '../../data/repositories/roommate_request_repository.dart';

class RoommateRequestViewModel extends ChangeNotifier {
  final RoommateRequestRepository _repository;
  final RoomGroupRepository _roomGroupRepository;

  RoommateRequestViewModel({
    required RoommateRequestRepository repository,
    required RoomGroupRepository roomGroupRepository,
  })  : _repository = repository,
        _roomGroupRepository = roomGroupRepository;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isReceivedRequestsLoading = false;
  bool _isSentRequestsLoading = false;

  List<RoommateRequestModel> _receivedRequests = [];
  List<RoommateRequestModel> _sentRequests = [];

  StreamSubscription<List<RoommateRequestModel>>? _receivedSubscription;
  StreamSubscription<List<RoommateRequestModel>>? _sentSubscription;

  String? _receivedListeningUserId;
  String? _sentListeningUserId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isReceivedRequestsLoading => _isReceivedRequestsLoading;
  bool get isSentRequestsLoading => _isSentRequestsLoading;

  List<RoommateRequestModel> get receivedRequests => _receivedRequests;
  List<RoommateRequestModel> get sentRequests => _sentRequests;

  int get pendingCount => _receivedRequests
      .where((e) => e.status == RoommateRequestStatus.pending)
      .length;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> sendRequest({
    required String postId,
    required String message,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _repository.sendRequest(
        postId: postId,
        message: message,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> hasPendingRequest(String postId) async {
    try {
      return await _repository.hasPendingRequest(postId);
    } catch (e) {
      debugPrint('[RoommateRequestViewModel] hasPendingRequest failed for post $postId: $e');
      return false;
    }
  }

  Future<bool> hasPendingProfileInvite(String targetUserId) async {
    try {
      return await _repository.hasPendingProfileInvite(targetUserId);
    } catch (e) {
      debugPrint('[RoommateRequestViewModel] hasPendingProfileInvite failed for user $targetUserId: $e');
      return false;
    }
  }

  Stream<List<RoommateRequestModel>> get sentProfileInvitesStream =>
      _repository.getSentProfileInvitesStream();

  Future<void> resetSession() async {
    await _receivedSubscription?.cancel();
    await _sentSubscription?.cancel();
    _receivedSubscription = null;
    _sentSubscription = null;
    _receivedListeningUserId = null;
    _sentListeningUserId = null;
    _receivedRequests = [];
    _sentRequests = [];
    _isReceivedRequestsLoading = false;
    _isSentRequestsLoading = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void ensureReceivedRequestsListening() {
    final currentUid = _repository.currentUser?.uid;

    if (currentUid == null) {
      _receivedSubscription?.cancel();
      _receivedSubscription = null;
      _receivedRequests = [];
      _receivedListeningUserId = null;
      _isReceivedRequestsLoading = false;
      notifyListeners();
      return;
    }

    if (_receivedListeningUserId == currentUid &&
        _receivedSubscription != null) {
      return;
    }

    _receivedListeningUserId = currentUid;
    _isReceivedRequestsLoading = true;
    _errorMessage = null;
    notifyListeners();
    listenToReceivedRequests();
  }

  void ensureSentRequestsListening() {
    final currentUid = _repository.currentUser?.uid;

    if (currentUid == null) {
      _sentSubscription?.cancel();
      _sentSubscription = null;
      _sentRequests = [];
      _sentListeningUserId = null;
      _isSentRequestsLoading = false;
      notifyListeners();
      return;
    }

    if (_sentListeningUserId == currentUid &&
        _sentSubscription != null) {
      return;
    }

    _sentListeningUserId = currentUid;
    _isSentRequestsLoading = true;
    _errorMessage = null;
    notifyListeners();
    listenToSentRequests();
  }

  void listenToReceivedRequests() {
    _receivedSubscription?.cancel();
    _receivedSubscription = null;

    _receivedSubscription = _repository.getReceivedRequests().listen(
      (requests) {
        _receivedRequests = requests;
        _isReceivedRequestsLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isReceivedRequestsLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _receivedListeningUserId = null;
        notifyListeners();
      },
    );
  }

  void listenToSentRequests() {
    _sentSubscription?.cancel();
    _sentSubscription = null;

    _sentSubscription = _repository.getSentRequests().listen(
      (requests) {
        _sentRequests = requests;
        _isSentRequestsLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isSentRequestsLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _sentListeningUserId = null;
        notifyListeners();
      },
    );
  }

  Future<bool> acceptRequest(String requestId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final request = await _repository.acceptRequest(requestId);

      try {
        final ownerName = request.targetName.isNotEmpty ? request.targetName : 'Chủ phòng';
        final requesterName = request.requesterName.isNotEmpty ? request.requesterName : 'Người thuê';
        final groupName = 'Nhóm phòng - $ownerName & $requesterName';

        await _roomGroupRepository.createGroupAfterAcceptRequest(
          ownerId: request.postOwnerId,
          requesterId: request.requesterId,
          postId: request.postId,
          groupName: groupName,
        );
      } catch (groupError) {
        try {
          await _repository.undoAcceptRequest(requestId);
        } catch (undoError) {
          debugPrint('[RoommateRequestViewModel] undoAcceptRequest also failed for $requestId: $undoError');
        }
        throw Exception(
          'Không thể tạo nhóm phòng. Yêu cầu đã được hoàn tác. Vui lòng thử lại.',
        );
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteRequest(String requestId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.deleteRequest(requestId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectRequest(String requestId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _repository.rejectRequest(requestId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _receivedSubscription?.cancel();
    _sentSubscription?.cancel();
    super.dispose();
  }
}
