import '../services/api_data.dart';
import '../services/api_client.dart';

enum AjoType {
  rotating,
  savings;

  String get label => this == rotating ? 'Rotating Ajo' : 'Savings Ajo';
  String get description => this == rotating
      ? 'Money is paid to one member every agreed cycle.'
      : 'Contributions accumulate and are paid back after an agreed period.';

  static AjoType parse(Object? value) => switch (value) {
    'rotating' => rotating,
    'savings' => savings,
    _ => throw const ApiException(
      'The server returned an unsupported Ajo type.',
    ),
  };
}

class SavingsGroup {
  final String id, name, description, creatorId, frequency, inviteCode;
  final int contributionAmountKobo, maxMembers, currentCycle;
  final bool requiresApproval;
  final AjoType ajoType;
  final int totalCycles;

  bool get isSavings => ajoType == AjoType.savings;
  bool get isComplete => currentCycle > totalCycles;
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
    this.requiresApproval = true,
    required this.currentCycle,
    required this.createdAt,
    this.ajoType = AjoType.rotating,
    int? totalCycles,
  }) : totalCycles = totalCycles ?? maxMembers;
  factory SavingsGroup.fromApi(Object? raw) {
    final data = ApiData.object(raw);
    final frequency = ApiData.oneOf(data, 'frequency', [
      'daily',
      'weekly',
      'biweekly',
      'monthly',
    ]);
    final type = AjoType.parse(
      data.containsKey('ajo_type') ? data['ajo_type'] : 'rotating',
    );
    final cycles = type == AjoType.savings
        ? ApiData.integer(data, 'savings_cycles')
        : ApiData.integer(data, 'max_members');
    if (cycles < 1 || cycles > 365) {
      throw const ApiException('The server returned an invalid Ajo duration.');
    }
    return SavingsGroup(
      ajoType: type,
      totalCycles: cycles,
      id: ApiData.id(data, 'id'),
      name: ApiData.string(data, 'name'),
      description: ApiData.optionalString(data, 'description'),
      creatorId: ApiData.id(data, 'creator_id'),
      contributionAmountKobo: ApiData.kobo(data, 'contribution_amount_kobo'),
      frequency: '${frequency[0].toUpperCase()}${frequency.substring(1)}',
      maxMembers: ApiData.integer(data, 'max_members'),
      startDate: ApiData.date(data, 'start_date'),
      inviteCode: ApiData.string(data, 'invite_code'),
      requiresApproval: ApiData.boolean(data, 'requires_approval'),
      currentCycle: ApiData.integer(data, 'current_cycle'),
      createdAt: ApiData.date(data, 'created_at'),
    );
  }
  factory SavingsGroup.from(Object? raw) {
    final m = Map<String, Object?>.from(raw as Map);
    final type = AjoType.parse(
      m.containsKey('ajoType') ? m['ajoType'] : 'rotating',
    );
    final cycles = type == AjoType.savings
        ? m['totalCycles'] as int
        : m['maxMembers'] as int;
    if (cycles < 1 || cycles > 365) {
      throw const FormatException('Invalid saved Ajo duration.');
    }
    return SavingsGroup(
      ajoType: type,
      totalCycles: cycles,
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
      requiresApproval: m['requiresApproval'] as bool? ?? true,
      currentCycle: m['currentCycle'] as int,
      createdAt: DateTime.parse(m['createdAt'] as String),
    );
  }
  Map<String, dynamic> toMap() => {
    'ajoType': ajoType.name,
    'totalCycles': totalCycles,
    'id': id,
    'name': name,
    'description': description,
    'creatorId': creatorId,
    'contributionAmountKobo': contributionAmountKobo,
    'frequency': frequency,
    'maxMembers': maxMembers,
    'startDate': startDate.toIso8601String(),
    'inviteCode': inviteCode,
    'requiresApproval': requiresApproval,
    'currentCycle': currentCycle,
    'createdAt': createdAt.toIso8601String(),
  };
  SavingsGroup withCycle(int cycle) => SavingsGroup(
    ajoType: ajoType,
    totalCycles: totalCycles,
    id: id,
    name: name,
    description: description,
    creatorId: creatorId,
    contributionAmountKobo: contributionAmountKobo,
    frequency: frequency,
    maxMembers: maxMembers,
    startDate: startDate,
    inviteCode: inviteCode,
    requiresApproval: requiresApproval,
    currentCycle: cycle,
    createdAt: createdAt,
  );
}
