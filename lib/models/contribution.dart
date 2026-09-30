class Contribution {
  final String id, groupId, memberId, memberName, status, paymentReference;
  final int cycle, amountKobo;
  final DateTime? paidAt;
  const Contribution(
    this.id,
    this.groupId,
    this.memberId,
    this.memberName,
    this.cycle,
    this.amountKobo,
    this.status,
    this.paymentReference,
    this.paidAt,
  );
  factory Contribution.from(Object? raw) {
    final m = Map<String, Object?>.from(raw as Map);
    return Contribution(
      m['id'] as String,
      m['groupId'] as String,
      m['memberId'] as String,
      m['memberName'] as String,
      m['cycle'] as int,
      m['amountKobo'] as int? ?? (m['amount'] as int) * 100,
      m['status'] as String,
      m['paymentReference'] as String,
      (m['paidAt'] as String?) == null
          ? null
          : DateTime.parse(m['paidAt'] as String),
    );
  }
  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'memberId': memberId,
    'memberName': memberName,
    'cycle': cycle,
    'amountKobo': amountKobo,
    'status': status,
    'paymentReference': paymentReference,
    'paidAt': paidAt?.toIso8601String(),
  };
  Contribution paid(String reference) => Contribution(
    id,
    groupId,
    memberId,
    memberName,
    cycle,
    amountKobo,
    'Paid',
    reference,
    DateTime.now(),
  );

  Contribution failed() => Contribution(
    id,
    groupId,
    memberId,
    memberName,
    cycle,
    amountKobo,
    'Failed',
    '',
    null,
  );
}
