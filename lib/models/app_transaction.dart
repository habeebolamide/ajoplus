import '../services/api_data.dart';

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
  factory AppTransaction.fromApi(Object? raw, String memberName) {
    final data = ApiData.object(raw);
    final group = ApiData.object(data['group']);
    final type = ApiData.oneOf(data, 'type', ['contribution', 'payout']);
    final status = ApiData.oneOf(data, 'status', ['successful', 'failed', 'pending']);
    return AppTransaction(
      ApiData.id(data, 'id'),
      ApiData.id(data, 'group_id'),
      ApiData.id(data, 'member_id'),
      memberName,
      ApiData.string(group, 'name'),
      '${type[0].toUpperCase()}${type.substring(1)}',
      ApiData.kobo(data, 'amount_kobo'),
      '${status[0].toUpperCase()}${status.substring(1)}',
      ApiData.string(data, 'reference'),
      ApiData.date(data, 'created_at'),
    );
  }
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
