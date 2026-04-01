// import 'dart:async';

// import 'package:flutter/foundation.dart';

// import '../../data/models/roommate_request_model.dart';
// import '../../data/repositories/roommate_request_repository.dart';


// class RoommateRequestViewModel extends ChangeNotifier {
//   final RoommateRequestRepository _repository;

//   RoommateRequestViewModel({
//     RoommateRequestRepository? repository,
//   }) : _repository = repository ?? RoommateRequestRepository();

//   bool _isLoading = false;
//   String? _errorMessage;

//   List<RoommateRequestModel> _receivedRequests = [];
//   List<RoommateRequestModel> _sentRequests = [];

//   StreamSubscription<List<RoommateRequestModel>>? _receivedSubscription;
//   StreamSubscription<List<RoommateRequestModel>>? _sentSubscription;

//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;

//   List<RoommateRequestModel> get receivedRequests => _receivedRequests;
//   List<RoommateRequestModel> get sentRequests => _sentRequests;
  
//   int get pendingCount =>
//     _receivedRequests
//         .where((e) => e.status == RoommateRequestStatus.pending)
//         .length;

//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }

//   void clearError() {
//     _errorMessage = null;
//     notifyListeners();
//   }

//   Future<bool> sendRequest({
//     required String postId,
//     required String message,
//   }) async {
//     try {
//       _setLoading(true);
//       _errorMessage = null;

//       await _repository.sendRequest(
//         postId: postId,
//         message: message,
//       );

//       return true;
//     } catch (e) {
//       _errorMessage = e.toString().replaceFirst('Exception: ', '');
//       notifyListeners();
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }

//   Future<bool> hasPendingRequest(String postId) async {
//     try {
//       return await _repository.hasPendingRequest(postId);
//     } catch (_) {
//       return false;
//     }
//   }

//   void listenToReceivedRequests() {
//     _receivedSubscription?.cancel();

//     _receivedSubscription = _repository.getReceivedRequests().listen(
//       (requests) {
//         _receivedRequests = requests;
//         notifyListeners();
//       },
//       onError: (error) {
//         _errorMessage = error.toString().replaceFirst('Exception: ', '');
//         notifyListeners();
//       },
//     );
//   }

//   void listenToSentRequests() {
//     _sentSubscription?.cancel();

//     _sentSubscription = _repository.getSentRequests().listen(
//       (requests) {
//         _sentRequests = requests;
//         notifyListeners();
//       },
//       onError: (error) {
//         _errorMessage = error.toString().replaceFirst('Exception: ', '');
//         notifyListeners();
//       },
//     );
//   }

//   Future<bool> acceptRequest(String requestId) async {
//     try {
//       _setLoading(true);
//       _errorMessage = null;

//       await _repository.acceptRequest(requestId);
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString().replaceFirst('Exception: ', '');
//       notifyListeners();
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }

//   Future<bool> rejectRequest(String requestId) async {
//     try {
//       _setLoading(true);
//       _errorMessage = null;

//       await _repository.rejectRequest(requestId);
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString().replaceFirst('Exception: ', '');
//       notifyListeners();
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }

//   @override
//   void dispose() {
//     _receivedSubscription?.cancel();
//     _sentSubscription?.cancel();
//     super.dispose();
//   }
// }

// import 'dart:async';

// import 'package:flutter/foundation.dart';

// import '../../data/models/roommate_request_model.dart';
// import '../../data/repositories/roommate_request_repository.dart';

// class RoommateRequestViewModel extends ChangeNotifier {
//   final RoommateRequestRepository _repository;

//   RoommateRequestViewModel({
//     RoommateRequestRepository? repository,
//   }) : _repository = repository ?? RoommateRequestRepository();

//   bool _isLoading = false;
//   String? _errorMessage;

//   List<RoommateRequestModel> _receivedRequests = [];
//   List<RoommateRequestModel> _sentRequests = [];

//   StreamSubscription<List<RoommateRequestModel>>? _receivedSubscription;
//   StreamSubscription<List<RoommateRequestModel>>? _sentSubscription;

//   bool _isReceivedListening = false;
//   bool _isSentListening = false;

//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;

//   List<RoommateRequestModel> get receivedRequests => _receivedRequests;
//   List<RoommateRequestModel> get sentRequests => _sentRequests;

//   int get pendingCount => _receivedRequests
//       .where((e) => e.status == RoommateRequestStatus.pending)
//       .length;

//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }

//   void clearError() {
//     _errorMessage = null;
//     notifyListeners();
//   }

//   Future<bool> sendRequest({
//     required String postId,
//     required String message,
//   }) async {
//     try {
//       _setLoading(true);
//       _errorMessage = null;

//       await _repository.sendRequest(
//         postId: postId,
//         message: message,
//       );

//       return true;
//     } catch (e) {
//       _errorMessage = e.toString().replaceFirst('Exception: ', '');
//       notifyListeners();
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }

//   Future<bool> hasPendingRequest(String postId) async {
//     try {
//       return await _repository.hasPendingRequest(postId);
//     } catch (_) {
//       return false;
//     }
//   }

//   void ensureReceivedRequestsListening() {
//     if (_isReceivedListening) return;
//     _isReceivedListening = true;
//     listenToReceivedRequests();
//   }

//   void ensureSentRequestsListening() {
//     if (_isSentListening) return;
//     _isSentListening = true;
//     listenToSentRequests();
//   }

//   void listenToReceivedRequests() {
//     _receivedSubscription?.cancel();

//     _receivedSubscription = _repository.getReceivedRequests().listen(
//       (requests) {
//         _receivedRequests = requests;
//         notifyListeners();
//       },
//       onError: (error) {
//         _errorMessage = error.toString().replaceFirst('Exception: ', '');
//         notifyListeners();
//       },
//     );
//   }

//   void listenToSentRequests() {
//     _sentSubscription?.cancel();

//     _sentSubscription = _repository.getSentRequests().listen(
//       (requests) {
//         _sentRequests = requests;
//         notifyListeners();
//       },
//       onError: (error) {
//         _errorMessage = error.toString().replaceFirst('Exception: ', '');
//         notifyListeners();
//       },
//     );
//   }

//   Future<bool> acceptRequest(String requestId) async {
//     try {
//       _setLoading(true);
//       _errorMessage = null;

//       await _repository.acceptRequest(requestId);
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString().replaceFirst('Exception: ', '');
//       notifyListeners();
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }

//   Future<bool> rejectRequest(String requestId) async {
//     try {
//       _setLoading(true);
//       _errorMessage = null;

//       await _repository.rejectRequest(requestId);
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString().replaceFirst('Exception: ', '');
//       notifyListeners();
//       return false;
//     } finally {
//       _setLoading(false);
//     }
//   }

//   @override
//   void dispose() {
//     _receivedSubscription?.cancel();
//     _sentSubscription?.cancel();
//     super.dispose();
//   }
// }







import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/roommate_request_model.dart';
import '../../data/repositories/roommate_request_repository.dart';

class RoommateRequestViewModel extends ChangeNotifier {
  final RoommateRequestRepository _repository;

  RoommateRequestViewModel({
    RoommateRequestRepository? repository,
  }) : _repository = repository ?? RoommateRequestRepository();

  bool _isLoading = false;
  String? _errorMessage;

  List<RoommateRequestModel> _receivedRequests = [];
  List<RoommateRequestModel> _sentRequests = [];

  StreamSubscription<List<RoommateRequestModel>>? _receivedSubscription;
  StreamSubscription<List<RoommateRequestModel>>? _sentSubscription;

  String? _receivedListeningUserId;
  String? _sentListeningUserId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
    listenToSentRequests();
  }

  void listenToReceivedRequests() {
    _receivedSubscription?.cancel();
    _receivedSubscription = null;

    _receivedSubscription = _repository.getReceivedRequests().listen(
      (requests) {
        _receivedRequests = requests;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
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
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
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

      await _repository.acceptRequest(requestId);
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