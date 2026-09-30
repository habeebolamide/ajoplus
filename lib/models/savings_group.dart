class SavingsGroup {
  final String id, name, description, creatorId, frequency, inviteCode;
  final int contributionAmountKobo, maxMembers, currentCycle;
  final DateTime startDate, createdAt;
  const SavingsGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.contributionAmountKobo,
    required this.frequency,
    required this.maxMembers,
    required this.startDate,
    required this.inviteCode,
    required this.currentCycle,
    required this.createdAt,
  });
  factory SavingsGroup.from(Object? raw) {
    final m = Map<String, Object?>.from(raw as Map);
    return SavingsGroup(
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String,
      creatorId: m['creatorId'] as String,
      contributionAmountKobo:
          m['contributionAmountKobo'] as int? ??
          (m['contributionAmount'] as int) * 100,
      frequency: m['frequency'] as String,
      maxMembers: m['maxMembers'] as int,
      startDate: DateTime.parse(m['startDate'] as String),
      inviteCode: m['inviteCode'] as String,
      currentCycle: m['currentCycle'] as int,
      createdAt: DateTime.parse(m['createdAt'] as String),
    );
  }
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'creatorId': creatorId,
    'contributionAmountKobo': contributionAmountKobo,
    'frequency': frequency,
    'maxMembers': maxMembers,
    'startDate': startDate.toIso8601String(),
    'inviteCode': inviteCode,
    'currentCycle': currentCycle,
    'createdAt': createdAt.toIso8601String(),
  };
  SavingsGroup withCycle(int cycle) => SavingsGroup(
    id: id,
    name: name,
    description: description,
    creatorId: creatorId,
    contributionAmountKobo: contributionAmountKobo,
    frequency: frequency,
    maxMembers: maxMembers,
    startDate: startDate,
    inviteCode: inviteCode,
    currentCycle: cycle,
    createdAt: createdAt,
  );
}
