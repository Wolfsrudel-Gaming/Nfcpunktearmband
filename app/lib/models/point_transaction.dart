class PointTransaction {
  final String id;
  final int amount;
  final int balanceAfter;
  final String reason;
  final String? note;
  final String? pointType;
  final String participantId;
  final String createdAt;

  const PointTransaction({
    required this.id,
    required this.amount,
    required this.balanceAfter,
    required this.reason,
    this.note,
    this.pointType,
    required this.participantId,
    required this.createdAt,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) =>
      PointTransaction(
        id: json['id'] as String,
        amount: json['amount'] as int,
        balanceAfter: json['balanceAfter'] as int,
        reason: json['reason'] as String,
        note: json['note'] as String?,
        pointType: json['pointType'] as String?,
        participantId: json['participantId'] as String? ?? '',
        createdAt: json['createdAt'] as String,
      );
}
