class Payout {
  final String id, groupId, memberId, status;
  final int cycle, amountKobo;
  final DateTime payoutDate;
  final DateTime? completedAt;
  const Payout(
    this.id,
    this.groupId,
    this.memberId,
    this.cycle,
    this.amountKobo,
    this.payoutDate,
    this.status,
    this.completedAt,
  );
  factory Payout.from(Object? raw) {
    final m = Map<String, Object?>.from(raw as Map);
    final completedAt = m['completedAt'] as String?;
    return Payout(
      m['id'] as String,
      m['groupId'] as String,
      m['memberId'] as String,
      m['cycle'] as int,
      m['amountKobo'] as int? ?? (m['amount'] as int) * 100,
      DateTime.parse(m['payoutDate'] as String),
      m['status'] as String,
      completedAt == null ? null : DateTime.parse(completedAt),
    );
  }
  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'memberId': memberId,
    'cycle': cycle,
    'amountKobo': amountKobo,
    'payoutDate': payoutDate.toIso8601String(),
    'status': status,
    'completedAt': completedAt?.toIso8601String(),
  };
}
