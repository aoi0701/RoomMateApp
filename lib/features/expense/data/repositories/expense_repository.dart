import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense_model.dart';
import '../models/expense_share_model.dart';

class ExpenseRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ExpenseRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _expenses =>
      _firestore.collection('expenses');

  CollectionReference<Map<String, dynamic>> get _shares =>
      _firestore.collection('expense_shares');

  // ── existing ────────────────────────────────────────────────────────────────

  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    try {
      final docRef = _expenses.doc();
      final model = expense.copyWith(id: docRef.id);
      await docRef.set(model.toMap());
      return model;
    } catch (e) {
      throw Exception('Không thể thêm khoản chi: $e');
    }
  }

  Future<ExpenseModel> addExpenseWithShares(
    ExpenseModel expense,
    List<ExpenseShareModel> shares,
  ) async {
    try {
      final batch = _firestore.batch();
      final expenseRef = _expenses.doc();
      final savedExpense = expense.copyWith(id: expenseRef.id);

      batch.set(expenseRef, savedExpense.toMap());

      for (final share in shares) {
        final shareRef = _shares.doc();
        final savedShare = share.copyWith(
          id: shareRef.id,
          expenseId: savedExpense.id,
        );
        batch.set(shareRef, savedShare.toMap());
      }

      await batch.commit();
      return savedExpense;
    } catch (e) {
      throw Exception('KhÃ´ng thá»ƒ thÃªm khoáº£n chi vÃ  phÃ¢n chia: $e');
    }
  }

  Future<void> addExpenseShares(List<ExpenseShareModel> shares) async {
    try {
      final batch = _firestore.batch();
      for (final share in shares) {
        final docRef = _shares.doc();
        batch.set(docRef, share.copyWith(id: docRef.id).toMap());
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Không thể lưu phân chia khoản chi: $e');
    }
  }

  Future<ExpenseModel?> getExpenseById(String expenseId) async {
    final doc = await _expenses.doc(expenseId).get();
    if (!doc.exists) return null;
    return ExpenseModel.fromDocument(doc);
  }

  Stream<List<ExpenseModel>> getExpensesByRoomGroup(String roomGroupId) {
    return _expenses
        .where('roomGroupId', isEqualTo: roomGroupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ExpenseModel.fromDocument).toList());
  }

  Future<List<ExpenseShareModel>> getExpenseSharesByExpense({
    required String expenseId,
    required String roomGroupId,
  }) async {
    try {
      final snapshot = await _shares
          .where('expenseId', isEqualTo: expenseId)
          .where('roomGroupId', isEqualTo: roomGroupId)
          .get();
      return snapshot.docs.map(ExpenseShareModel.fromDocument).toList();
    } catch (e) {
      throw Exception('Không thể tải chi tiết phân chia: $e');
    }
  }

  Future<List<ExpenseShareModel>> getDebtsOwedByUser({
    required String userId,
    required String roomGroupId,
  }) async {
    try {
      final snapshot = await _shares
          .where('roomGroupId', isEqualTo: roomGroupId)
          .where('fromUserId', isEqualTo: userId)
          .where('isPaid', isEqualTo: false)
          .get();
      return snapshot.docs.map(ExpenseShareModel.fromDocument).toList();
    } catch (e) {
      throw Exception('Không thể tải công nợ: $e');
    }
  }

  Future<List<ExpenseShareModel>> getDebtsOwedToUser({
    required String userId,
    required String roomGroupId,
  }) async {
    try {
      final snapshot = await _shares
          .where('roomGroupId', isEqualTo: roomGroupId)
          .where('toUserId', isEqualTo: userId)
          .where('isPaid', isEqualTo: false)
          .get();
      return snapshot.docs.map(ExpenseShareModel.fromDocument).toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách người nợ: $e');
    }
  }

  Future<void> markShareAsPaid(String shareId) async {
    try {
      await _shares.doc(shareId).update({
        'isPaid': true,
        'paidAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Không thể cập nhật trạng thái thanh toán: $e');
    }
  }

  // ── new ─────────────────────────────────────────────────────────────────────

  Future<void> updateExpense({
    required String expenseId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> participantIds,
    required String note,
    required SplitType splitType,
    required Map<String, double> customSplits,
    required List<ExpenseShareModel> newShares,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      final oldShares = await _shares
          .where('expenseId', isEqualTo: expenseId)
          .get();

      final batch = _firestore.batch();

      batch.update(_expenses.doc(expenseId), {
        'title': title,
        'amount': amount,
        'paidBy': paidBy,
        'participantIds': participantIds,
        'note': note,
        'splitType': splitType == SplitType.custom ? 'custom' : 'equal',
        'customSplits': customSplits,
      });

      for (final doc in oldShares.docs) {
        batch.delete(doc.reference);
      }

      for (final share in newShares) {
        final ref = _shares.doc();
        batch.set(ref, share.copyWith(id: ref.id).toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Không thể cập nhật khoản chi: $e');
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      final shares = await _shares
          .where('expenseId', isEqualTo: expenseId)
          .get();

      final batch = _firestore.batch();
      batch.delete(_expenses.doc(expenseId));
      for (final doc in shares.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Không thể xoá khoản chi: $e');
    }
  }

  Future<List<ExpenseModel>> getExpensesByMonth({
    required String roomGroupId,
    required int year,
    required int month,
  }) async {
    try {
      final firstDay = DateTime(year, month);
      final lastDay = DateTime(year, month + 1);
      final snapshot = await _expenses
          .where('roomGroupId', isEqualTo: roomGroupId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(lastDay))
          .orderBy('createdAt')
          .get();
      return snapshot.docs.map(ExpenseModel.fromDocument).toList();
    } catch (e) {
      throw Exception('Không thể tải thống kê tháng: $e');
    }
  }

  Future<List<ExpenseShareModel>> getAllUnpaidSharesByGroup(
    String roomGroupId,
  ) async {
    try {
      final snapshot = await _shares
          .where('roomGroupId', isEqualTo: roomGroupId)
          .where('isPaid', isEqualTo: false)
          .get();
      return snapshot.docs.map(ExpenseShareModel.fromDocument).toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách công nợ: $e');
    }
  }

  Future<void> settleAllDebts({
    required String fromUserId,
    required String toUserId,
    required String roomGroupId,
  }) async {
    try {
      // Query by 3 fields, filter toUserId client-side to avoid 4-field composite index
      final snapshot = await _shares
          .where('roomGroupId', isEqualTo: roomGroupId)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('isPaid', isEqualTo: false)
          .get();

      final relevant = snapshot.docs
          .where((doc) => doc.data()['toUserId'] == toUserId)
          .toList();

      final batch = _firestore.batch();
      for (final doc in relevant) {
        batch.update(doc.reference, {
          'isPaid': true,
          'paidAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Không thể thanh toán tất cả công nợ: $e');
    }
  }
}
