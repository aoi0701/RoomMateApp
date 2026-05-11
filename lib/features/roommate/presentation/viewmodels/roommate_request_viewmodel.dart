import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../room_group/data/repositories/room_group_repository.dart';
import '../../data/models/roommate_request_model.dart';
import '../../data/repositories/roommate_request_repository.dart';

class RoommateRequestViewModel extends ChangeNotifier {
  final RoommateRequestRepository _repository;
  final RoomGroupRepository _roomGroupRepository;

  RoommateRequestViewModel({
    RoommateRequestRepository? repository,
    RoomGroupRepository? roomGroupRepository,
  })  : _repository = repository ?? RoommateRequestRepository(),
        _roomGroupRepository = roomGroupRepository ?? RoomGroupRepository();

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
    } catch (_) {
      return false;
    }
  }

  void ensureReceivedRequestsListening() {
    final currentUid = _repository.currentUser?.uid;

    if (currentUid == null) {
      _receivedRequests = [];
      _receivedListeningUserId = null;
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
      _sentRequests = [];
      _sentListeningUserId = null;
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

      await _roomGroupRepository.createGroupAfterAcceptRequest(
        ownerId: request.postOwnerId,
        requesterId: request.requesterId,
        postId: request.postId,
        groupName: 'Nhóm phòng',
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
