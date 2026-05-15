import 'package:cloud_firestore/cloud_firestore.dart';

enum SplitType { equal, custom }

class ExpenseModel {
  final String id;
  final String roomGroupId;
  final String title;
  final double amount;
  final String paidBy;
  final List<String> participantIds;
  final String note;
  final SplitType splitType;
  final Map<String, double> customSplits;
  final DateTime? createdAt;

  const ExpenseModel({
    required this.id,
    required this.roomGroupId,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.participantIds,
    required this.note,
    this.splitType = SplitType.equal,
    this.customSplits = const {},
    this.createdAt,
  });

  factory ExpenseModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final splitTypeStr = data['splitType'] as String? ?? 'equal';
    final rawCustomSplits = data['customSplits'] as Map<String, dynamic>? ?? {};
    return ExpenseModel(
      id: doc.id,
      roomGroupId: data['roomGroupId'] ?? '',
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      paidBy: data['paidBy'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      note: data['note'] ?? '',
      splitType: splitTypeStr == 'custom' ? SplitType.custom : SplitType.equal,
      customSplits: rawCustomSplits.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomGroupId': roomGroupId,
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'participantIds': participantIds,
      'note': note,
      'splitType': splitType == SplitType.custom ? 'custom' : 'equal',
      'customSplits': customSplits,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? roomGroupId,
    String? title,
    double? amount,
    String? paidBy,
    List<String>? participantIds,
    String? note,
    SplitType? splitType,
    Map<String, double>? customSplits,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      roomGroupId: roomGroupId ?? this.roomGroupId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      participantIds: participantIds ?? this.participantIds,
      note: note ?? this.note,
      splitType: splitType ?? this.splitType,
      customSplits: customSplits ?? this.customSplits,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
