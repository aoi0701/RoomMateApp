import '../../../../core/viewmodels/view_model_base.dart';
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

// ViewModel quản lý chi phí: tính chia tiền, load công nợ, thống kê tháng, quyết toán
class ExpenseViewModel extends ViewModelBase {
  final ExpenseRepository _repository;

  ExpenseViewModel({required ExpenseRepository repository})
      : _repository = repository;

  List<ExpenseShareModel> _shares = [];
  List<ExpenseShareModel> _myDebts = [];
  List<ExpenseShareModel> _othersDebts = [];
  List<ExpenseModel> _monthlyExpenses = [];
  List<NetDebtEntry> _netDebts = [];

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

  Future<ExpenseModel?> getExpenseById(String expenseId) {
    return _repository.getExpenseById(expenseId);
  }

  // Tính danh sách chia tiền: chia đều hoặc chia tùy chỉnh, trả về List<ExpenseShareModel>
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
      final totalCustom = customSplits.values.fold(0.0, (sum, v) => sum + v);
      final remaining = amount - totalCustom;

      if (remaining.abs() > 0.01) {
        throw Exception(
          'Tổng phần chia (${totalCustom.toStringAsFixed(0)}đ) '
          'không bằng tổng chi phí (${amount.toStringAsFixed(0)}đ). '
          'Vui lòng điều chỉnh để tổng phần chia đúng bằng ${amount.toStringAsFixed(0)}đ.',
        );
      }

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
      beginLoad();

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
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
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
      beginLoad();

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
        roomGroupId: roomGroupId,
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
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> deleteExpense({
    required String expenseId,
    required String roomGroupId,
  }) async {
    try {
      beginLoad();
      await _repository.deleteExpense(
        expenseId: expenseId,
        roomGroupId: roomGroupId,
      );
      return true;
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadExpenseShares({
    required String expenseId,
    required String roomGroupId,
  }) async {
    try {
      beginLoad();
      _shares = await _repository.getExpenseSharesByExpense(
        expenseId: expenseId,
        roomGroupId: roomGroupId,
      );
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setLoading(false);
    }
  }

  // Load đồng thời: công nợ cá nhân (myDebts/othersDebts) + công nợ ròng toàn nhóm (netDebts)
  Future<void> loadDebtScreenData({
    required String userId,
    required String roomGroupId,
  }) async {
    try {
      beginLoad();

      await Future.wait<void>([
        () async {
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
        }(),
        () async {
          final allShares =
              await _repository.getAllUnpaidSharesByGroup(roomGroupId);

          final Map<String, Map<String, double>> gross = {};
          for (final share in allShares) {
            gross.putIfAbsent(share.fromUserId, () => {})[share.toUserId] =
                (gross[share.fromUserId]?[share.toUserId] ?? 0) +
                    share.amountOwed;
          }

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
                entries.add(
                    NetDebtEntry(fromUserId: from, toUserId: to, netAmount: net));
              } else if (net < -0.01) {
                entries.add(
                    NetDebtEntry(fromUserId: to, toUserId: from, netAmount: -net));
              }
            }
          }

          _netDebts = entries;
        }(),
      ]);
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadDebts({
    required String userId,
    required String roomGroupId,
  }) async {
    try {
      beginLoad();
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
      setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> markAsPaid(String shareId) async {
    try {
      beginLoad();
      await _repository.markShareAsPaid(shareId);
      _myDebts = _myDebts.map((s) {
        return s.id == shareId ? s.copyWith(isPaid: true) : s;
      }).toList();
      return true;
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadMonthlySummary({
    required String roomGroupId,
    required int year,
    required int month,
  }) async {
    try {
      beginLoad();
      _monthlyExpenses = await _repository.getExpensesByMonth(
        roomGroupId: roomGroupId,
        year: year,
        month: month,
      );
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadNetDebtSummary({
    required String roomGroupId,
    required String currentUserId,
  }) async {
    try {
      beginLoad();

      final allShares = await _repository.getAllUnpaidSharesByGroup(roomGroupId);

      // Tích lũy tổng nợ gộp: gross[from][to] += số tiền
      final Map<String, Map<String, double>> gross = {};
      for (final share in allShares) {
        gross.putIfAbsent(share.fromUserId, () => {})[share.toUserId] =
            (gross[share.fromUserId]?[share.toUserId] ?? 0) + share.amountOwed;
      }

      // Tính nợ ròng: net[A][B] = gross[A][B] - gross[B][A], bỏ qua cặp đã xử lý
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
      setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> settleAllDebts({
    required String fromUserId,
    required String toUserId,
    required String roomGroupId,
  }) async {
    try {
      beginLoad();
      await _repository.settleAllDebts(
        fromUserId: fromUserId,
        toUserId: toUserId,
        roomGroupId: roomGroupId,
      );
      return true;
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      setLoading(false);
    }
  }
}
