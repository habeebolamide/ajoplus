class AppTransaction {
  final String id,
      groupId,
      memberId,
      memberName,
      groupName,
      type,
      status,
      reference;
  final int amountKobo;
  final DateTime createdAt;
  const AppTransaction(
    this.id,
    this.groupId,
    this.memberId,
    this.memberName,
    this.groupName,
    this.type,
    this.amountKobo,
    this.status,
    this.reference,
    this.createdAt,
  );
  factory AppTransaction.from(Object? raw) {
    final m = Map<String, Object?>.from(raw as Map);
    return AppTransaction(
      m['id'] as String,
      m['groupId'] as String,
      m['memberId'] as String,
      m['memberName'] as String,
      m['groupName'] as String,
      m['type'] as String,
      m['amountKobo'] as int? ?? (m['amount'] as int) * 100,
      m['status'] as String,
      m['reference'] as String,
      DateTime.parse(m['createdAt'] as String),
    );
  }
  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'memberId': memberId,
    'memberName': memberName,
    'groupName': groupName,
    'type': type,
    'amountKobo': amountKobo,
    'status': status,
    'reference': reference,
    'createdAt': createdAt.toIso8601String(),
  };
}
