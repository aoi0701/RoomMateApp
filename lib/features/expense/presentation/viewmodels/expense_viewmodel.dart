import 'package:flutter/foundation.dart';

import '../../data/models/expense_model.dart';
import '../../data/models/expense_share_model.dart';
import '../../data/repositories/expense_repository.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository _repository;

  ExpenseViewModel({ExpenseRepository? repository})
      : _repository = repository ?? ExpenseRepository();

  bool _isLoading = false;
  String? _errorMessage;
  List<ExpenseShareModel> _shares = [];
  List<ExpenseShareModel> _myDebts = [];
  List<ExpenseShareModel> _othersDebts = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ExpenseShareModel> get shares => _shares;
  List<ExpenseShareModel> get myDebts => _myDebts;
  List<ExpenseShareModel> get othersDebts => _othersDebts;

  Stream<List<ExpenseModel>> getExpensesStream(String roomGroupId) {
    return _repository.getExpensesByRoomGroup(roomGroupId);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  List<ExpenseShareModel> calculateEqualSplit({
    required String expenseId,
    required String roomGroupId,
    required double amount,
    required String paidBy,
    required List<String> participantIds,
    required List<String> visibleToUserIds,
  }) {
    final nonPayers = participantIds.where((id) => id != paidBy).toList();
    if (nonPayers.isEmpty) return [];
    final amountPerPerson = amount / participantIds.length;
    return nonPayers
        .map(
          (id) => ExpenseShareModel(
            id: '',
            expenseId: expenseId,
            roomGroupId: roomGroupId,
            fromUserId: id,
            toUserId: paidBy,
            visibleToUserIds: visibleToUserIds,
            amountOwed: amountPerPerson,
            isPaid: false,
          ),
        )
        .toList();
  }

  Future<bool> addExpense({
    required String roomGroupId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> participantIds,
    required List<String> visibleToUserIds,
    required String note,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final tempExpense = ExpenseModel(
        id: '',
        roomGroupId: roomGroupId,
        title: title,
        amount: amount,
        paidBy: paidBy,
        participantIds: participantIds,
        note: note,
      );

      final savedExpense = await _repository.addExpense(tempExpense);

      if (savedExpense.id.isEmpty) {
        throw Exception('Lưu khoản chi thất bại: không lấy được ID');
      }

      final shares = calculateEqualSplit(
        expenseId: savedExpense.id,
        roomGroupId: roomGroupId,
        amount: amount,
        paidBy: paidBy,
        participantIds: participantIds,
        visibleToUserIds: visibleToUserIds,
      );

      if (shares.isNotEmpty) {
        await _repository.addExpenseShares(shares);
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

  Future<void> loadExpenseShares({
    required String expenseId,
    required String roomGroupId,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      _shares = await _repository.getExpenseSharesByExpense(
        expenseId: expenseId,
        roomGroupId: roomGroupId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadDebts({
    required String userId,
    required String roomGroupId,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      final results = await Future.wait([
        _repository.getDebtsOwedByUser(
          userId: userId,
          roomGroupId: roomGroupId,
        ),
        _repository.getDebtsOwedToUser(
          userId: userId,
          roomGroupId: roomGroupId,
        ),
      ]);
      _myDebts = results[0];
      _othersDebts = results[1];
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> markAsPaid(String shareId) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      await _repository.markShareAsPaid(shareId);
      _myDebts = _myDebts.map((s) {
        return s.id == shareId ? s.copyWith(isPaid: true) : s;
      }).toList();
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
