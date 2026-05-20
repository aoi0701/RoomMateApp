import 'package:flutter/foundation.dart';

import '../../data/models/expense_model.dart';
import '../../data/models/expense_share_model.dart';
import '../../data/repositories/expense_repository.dart';

class NetDebtEntry {
  final String fromUserId;
  final String toUserId;
  final double netAmount;

  const NetDebtEntry({
    required this.fromUserId,
    required this.toUserId,
    required this.netAmount,
  });
}

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository _repository;

  ExpenseViewModel({ExpenseRepository? repository})
      : _repository = repository ?? ExpenseRepository();

  bool _isLoading = false;
  String? _errorMessage;
  List<ExpenseShareModel> _shares = [];
  List<ExpenseShareModel> _myDebts = [];
  List<ExpenseShareModel> _othersDebts = [];
  List<ExpenseModel> _monthlyExpenses = [];
  List<NetDebtEntry> _netDebts = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ExpenseShareModel> get shares => _shares;
  List<ExpenseShareModel> get myDebts => _myDebts;
  List<ExpenseShareModel> get othersDebts => _othersDebts;
  List<ExpenseModel> get monthlyExpenses => _monthlyExpenses;
  List<NetDebtEntry> get netDebts => _netDebts;

  double get monthlyTotal =>
      _monthlyExpenses.fold(0, (sum, e) => sum + e.amount);

  double myMonthlySpend(String currentUserId) => _monthlyExpenses
      .where((e) => e.paidBy == currentUserId)
      .fold(0, (sum, e) => sum + e.amount);

  Map<String, double> spendByMember(List<String> memberIds) {
    final map = <String, double>{for (final id in memberIds) id: 0};
    for (final e in _monthlyExpenses) {
      map[e.paidBy] = (map[e.paidBy] ?? 0) + e.amount;
    }
    return map;
  }

  Stream<List<ExpenseModel>> getExpensesStream(String roomGroupId) {
    return _repository.getExpensesByRoomGroup(roomGroupId);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  List<ExpenseShareModel> calculateSplit({
    required String expenseId,
    required String roomGroupId,
    required double amount,
    required String paidBy,
    required List<String> participantIds,
    required SplitType splitType,
    Map<String, double> customSplits = const {},
  }) {
    final nonPayers = participantIds.where((id) => id != paidBy).toList();
    if (nonPayers.isEmpty) return [];

    if (splitType == SplitType.custom) {
      return nonPayers
          .where((id) => (customSplits[id] ?? 0) > 0)
          .map(
            (id) => ExpenseShareModel(
              id: '',
              expenseId: expenseId,
              roomGroupId: roomGroupId,
              fromUserId: id,
              toUserId: paidBy,
              amountOwed: customSplits[id]!,
              isPaid: false,
            ),
          )
          .toList();
    }

    final amountPerPerson = amount / participantIds.length;
    return nonPayers
        .map(
          (id) => ExpenseShareModel(
            id: '',
            expenseId: expenseId,
            roomGroupId: roomGroupId,
            fromUserId: id,
            toUserId: paidBy,
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
    required String note,
    required SplitType splitType,
    Map<String, double> customSplits = const {},
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
        splitType: splitType,
        customSplits: customSplits,
      );
      final pendingShares = calculateSplit(
        expenseId: tempExpense.id,
        roomGroupId: roomGroupId,
        amount: amount,
        paidBy: paidBy,
        participantIds: participantIds,
        splitType: splitType,
        customSplits: customSplits,
      );
      final savedExpense = await _repository.addExpenseWithShares(
        tempExpense,
        pendingShares,
      );

      if (savedExpense.id.isEmpty) {
        throw Exception('Lưu khoản chi thất bại: không lấy được ID');
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

  Future<bool> updateExpense({
    required String expenseId,
    required String roomGroupId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> participantIds,
    required String note,
    required SplitType splitType,
    Map<String, double> customSplits = const {},
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final newShares = calculateSplit(
        expenseId: expenseId,
        roomGroupId: roomGroupId,
        amount: amount,
        paidBy: paidBy,
        participantIds: participantIds,
        splitType: splitType,
        customSplits: customSplits,
      );

      await _repository.updateExpense(
        expenseId: expenseId,
        title: title,
        amount: amount,
        paidBy: paidBy,
        participantIds: participantIds,
        note: note,
        splitType: splitType,
        customSplits: customSplits,
        newShares: newShares,
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

  Future<bool> deleteExpense(String expenseId) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      await _repository.deleteExpense(expenseId);
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

  Future<void> loadMonthlySummary({
    required String roomGroupId,
    required int year,
    required int month,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      _monthlyExpenses = await _repository.getExpensesByMonth(
        roomGroupId: roomGroupId,
        year: year,
        month: month,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadNetDebtSummary({
    required String roomGroupId,
    required String currentUserId,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final allShares = await _repository.getAllUnpaidSharesByGroup(roomGroupId);

      // Accumulate gross balance: balance[from][to] += amount
      final Map<String, Map<String, double>> gross = {};
      for (final share in allShares) {
        gross.putIfAbsent(share.fromUserId, () => {})[share.toUserId] =
            (gross[share.fromUserId]?[share.toUserId] ?? 0) + share.amountOwed;
      }

      // Simplify: net[A][B] = gross[A][B] - gross[B][A]
      final Set<String> processed = {};
      final List<NetDebtEntry> entries = [];

      for (final from in gross.keys) {
        for (final to in (gross[from] ?? {}).keys) {
          final key = [from, to]..sort();
          final pairKey = key.join('_');
          if (processed.contains(pairKey)) continue;
          processed.add(pairKey);

          final aOwesB = gross[from]?[to] ?? 0;
          final bOwesA = gross[to]?[from] ?? 0;
          final net = aOwesB - bOwesA;

          if (net > 0.01) {
            entries.add(NetDebtEntry(fromUserId: from, toUserId: to, netAmount: net));
          } else if (net < -0.01) {
            entries.add(NetDebtEntry(fromUserId: to, toUserId: from, netAmount: -net));
          }
        }
      }

      _netDebts = entries;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> settleAllDebts({
    required String fromUserId,
    required String toUserId,
    required String roomGroupId,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      await _repository.settleAllDebts(
        fromUserId: fromUserId,
        toUserId: toUserId,
        roomGroupId: roomGroupId,
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
}
