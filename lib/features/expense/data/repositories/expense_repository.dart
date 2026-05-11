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

  Future<void> addExpenseShares(List<ExpenseShareModel> shares) async {
    try {
      final batch = _firestore.batch();
      for (final share in shares) {
        final docRef = _shares.doc();
        final model = share.copyWith(id: docRef.id);
        batch.set(docRef, model.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Không thể lưu phân chia khoản chi: $e');
    }
  }

  Stream<List<ExpenseModel>> getExpensesByRoomGroup(String roomGroupId) {
    return _expenses
        .where('roomGroupId', isEqualTo: roomGroupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(ExpenseModel.fromDocument).toList());
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
}
