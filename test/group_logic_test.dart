import 'package:ajoplus/models/savings_group.dart';
import 'package:ajoplus/services/group_service.dart';
import 'package:ajoplus/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final group = SavingsGroup(
    id: '1', name: 'Savings circle', description: '', creatorId: '7',
    contributionAmountKobo: 125050, frequency: 'Monthly', maxMembers: 2,
    startDate: DateTime(2026, 10, 1), inviteCode: 'ABCD1234', currentCycle: 1,
    createdAt: DateTime(2026, 9, 30),
  );

  test('monthly cycle follows configured start date and keeps amounts in kobo', () {
    expect(GroupService.cycleDate(group, 1), DateTime(2026, 10, 1));
    expect(GroupService.cycleDate(group, 2), DateTime(2026, 11, 1));
    expect(group.contributionAmountKobo * group.maxMembers, 250100);
  });

  test('naira input converts exactly to integer kobo', () {
    expect(parseNairaToKobo('1250.50'), 125050);
    expect(parseNairaToKobo('0.01'), 1);
    expect(parseNairaToKobo('1250.999'), isNull);
    expect(parseNairaToKobo('0'), isNull);
  });
}
