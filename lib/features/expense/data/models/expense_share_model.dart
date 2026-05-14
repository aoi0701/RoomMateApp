import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseShareModel {
  final String id;
  final String expenseId;
  final String roomGroupId;
  final String fromUserId;
  final String toUserId;
  final List<String> visibleToUserIds;
  final double amountOwed;
  final bool isPaid;
  final DateTime? paidAt;
  final DateTime? createdAt;

  const ExpenseShareModel({
    required this.id,
    required this.expenseId,
    required this.roomGroupId,
    required this.fromUserId,
    required this.toUserId,
    required this.visibleToUserIds,
    required this.amountOwed,
    required this.isPaid,
    this.paidAt,
    this.createdAt,
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
      visibleToUserIds: List<String>.from(data['visibleToUserIds'] ?? []),
      amountOwed: (data['amountOwed'] as num?)?.toDouble() ?? 0,
      isPaid: data['isPaid'] as bool? ?? false,
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expenseId': expenseId,
      'roomGroupId': roomGroupId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'visibleToUserIds': visibleToUserIds,
      'amountOwed': amountOwed,
      'isPaid': isPaid,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  ExpenseShareModel copyWith({
    String? id,
    String? expenseId,
    String? roomGroupId,
    String? fromUserId,
    String? toUserId,
    List<String>? visibleToUserIds,
    double? amountOwed,
    bool? isPaid,
    DateTime? paidAt,
    DateTime? createdAt,
  }) {
    return ExpenseShareModel(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      roomGroupId: roomGroupId ?? this.roomGroupId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      visibleToUserIds: visibleToUserIds ?? this.visibleToUserIds,
      amountOwed: amountOwed ?? this.amountOwed,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
