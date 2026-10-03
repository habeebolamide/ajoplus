import '../services/api_data.dart';
import 'savings_group.dart';
import '../services/api_client.dart';

class GroupPreview {
  final String id, name, description, frequency;
  final int amountKobo, maxMembers, membersCount;
  final bool requiresApproval;
  final String? joinRequestStatus;
  final DateTime startDate;
  final AjoType ajoType;
  final int totalCycles;

  const GroupPreview(
    this.id,
    this.name,
    this.description,
    this.frequency,
    this.amountKobo,
    this.maxMembers,
    this.membersCount,
    this.requiresApproval,
    this.joinRequestStatus,
    this.startDate, {
    this.ajoType = AjoType.rotating,
    int? totalCycles,
  }) : totalCycles = totalCycles ?? maxMembers;

  factory GroupPreview.fromApi(Object? raw) {
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
    return GroupPreview(
      ApiData.id(data, 'id'),
      ApiData.string(data, 'name'),
      ApiData.optionalString(data, 'description'),
      '${frequency[0].toUpperCase()}${frequency.substring(1)}',
      ApiData.kobo(data, 'contribution_amount_kobo'),
      ApiData.integer(data, 'max_members'),
      ApiData.integer(data, 'members_count'),
      ApiData.boolean(data, 'requires_approval'),
      ApiData.optionalOneOf(data, 'join_request_status', [
        'pending',
        'rejected',
        'approved',
        'joined',
      ]),
      ApiData.date(data, 'start_date'),
      ajoType: type,
      totalCycles: cycles,
    );
  }
}
