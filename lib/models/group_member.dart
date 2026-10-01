import '../services/api_data.dart';

class GroupMember {
  final String id, groupId, userId, name;
  final int payoutPosition;
  final DateTime joinedAt;
  const GroupMember(
    this.id,
    this.groupId,
    this.userId,
    this.name,
    this.payoutPosition,
    this.joinedAt,
  );
  factory GroupMember.fromApi(Object? raw) {
    final data = ApiData.object(raw);
    final user = ApiData.object(data['user']);
    return GroupMember(
      ApiData.id(data, 'id'),
      ApiData.id(data, 'group_id'),
      ApiData.id(data, 'user_id'),
      ApiData.string(user, 'name'),
      ApiData.integer(data, 'payout_position'),
      ApiData.date(data, 'joined_at'),
    );
  }
  factory GroupMember.from(Object? raw) {
    final m = Map<String, Object?>.from(raw as Map);
    return GroupMember(
      m['id'] as String,
      m['groupId'] as String,
      m['userId'] as String,
      m['name'] as String,
      m['payoutPosition'] as int,
      DateTime.parse(m['joinedAt'] as String),
    );
  }
  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'userId': userId,
    'name': name,
    'payoutPosition': payoutPosition,
    'joinedAt': joinedAt.toIso8601String(),
  };
}
