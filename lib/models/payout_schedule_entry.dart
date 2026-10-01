import '../services/api_data.dart';

class PayoutScheduleEntry {
  final String groupId;
  final int cycle, amountKobo;
  final String recipientId, recipientName, status;
  final DateTime scheduledFor;

  const PayoutScheduleEntry(this.groupId, this.cycle, this.amountKobo,
      this.recipientId, this.recipientName, this.status, this.scheduledFor);

  factory PayoutScheduleEntry.fromApi(String groupId, Object? raw) {
    final data = ApiData.object(raw);
    final recipient = ApiData.object(data['recipient']);
    return PayoutScheduleEntry(
      groupId,
      ApiData.integer(data, 'cycle'),
      ApiData.kobo(data, 'amount_kobo'),
      ApiData.id(recipient, 'id'),
      ApiData.string(recipient, 'name'),
      ApiData.oneOf(data, 'status', ['pending', 'completed']),
      ApiData.date(data, 'scheduled_for'),
    );
  }
}
