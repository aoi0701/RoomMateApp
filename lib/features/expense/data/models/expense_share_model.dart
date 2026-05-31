import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseShareModel {
  final String id;
  final String expenseId;
  final String roomGroupId;
  final String fromUserId;
  final String toUserId;
  final double amountOwed;
  final bool isPaid;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final bool isArchived;
  final DateTime? archivedAt;

  const ExpenseShareModel({
    required this.id,
    required this.expenseId,
    required this.roomGroupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amountOwed,
    required this.isPaid,
    this.paidAt,
    this.createdAt,
    this.isArchived = false,
    this.archivedAt,
  });

  factory ExpenseShareModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ExpenseShareModel(
      id: doc.id,
      expenseId: data['expenseId'] ?? '',
      roomGroupId: data['roomGroupId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      amountOwed: (data['amountOwed'] as num?)?.toDouble() ?? 0,
      isPaid: data['isPaid'] as bool? ?? false,
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isArchived: data['isArchived'] as bool? ?? false,
      archivedAt: (data['archivedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expenseId': expenseId,
      'roomGroupId': roomGroupId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amountOwed': amountOwed,
      'isPaid': isPaid,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'isArchived': isArchived,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
    };
  }

  ExpenseShareModel copyWith({
    String? id,
    String? expenseId,
    String? roomGroupId,
    String? fromUserId,
    String? toUserId,
    double? amountOwed,
    bool? isPaid,
    DateTime? paidAt,
    DateTime? createdAt,
    bool? isArchived,
    DateTime? archivedAt,
  }) {
    return ExpenseShareModel(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      roomGroupId: roomGroupId ?? this.roomGroupId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      amountOwed: amountOwed ?? this.amountOwed,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}
