import '../services/api_data.dart';

class GroupJoinRequest {
  final String id, userId, name;

  const GroupJoinRequest({
    required this.id,
    required this.userId,
    required this.name,
  });

  factory GroupJoinRequest.fromApi(Object? raw) {
    final data = ApiData.object(raw);
    final user = ApiData.object(data['user']);
    return GroupJoinRequest(
      id: ApiData.id(data, 'id'),
      userId: ApiData.id(data, 'user_id'),
      name: ApiData.string(user, 'name'),
    );
  }
}
