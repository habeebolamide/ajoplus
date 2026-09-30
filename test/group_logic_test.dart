import 'dart:io';
import 'package:ajoplus/models/models.dart';
import 'package:ajoplus/providers/providers.dart';
import 'package:ajoplus/services/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('ajoplus-test-');
    Hive.init(directory.path);
    StorageService.users = await Hive.openBox('users');
    StorageService.groups = await Hive.openBox('groups');
    StorageService.members = await Hive.openBox('members');
    StorageService.contributions = await Hive.openBox('contributions');
    StorageService.payouts = await Hive.openBox('payouts');
    StorageService.transactions = await Hive.openBox('transactions');
    StorageService.notifications = await Hive.openBox('notifications');
    SharedPreferences.setMockInitialValues({'seeded': true});
    StorageService.prefs = await SharedPreferences.getInstance();
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('balance and progress include paid contributions only', () {
    final rows = [
      Contribution(
        '1',
        'g',
        'a',
        'Ada',
        2,
        2000000,
        'Paid',
        'ref',
        DateTime.now(),
      ),
      Contribution('2', 'g', 'b', 'Bisi', 2, 2000000, 'Pending', '', null),
      Contribution(
        '3',
        'g',
        'a',
        'Ada',
        1,
        2000000,
        'Paid',
        'old',
        DateTime.now(),
      ),
    ];
    expect(GroupService.balance(rows, 2), 2000000);
    expect(GroupService.progress(2000000, 4000000), .5);
    expect(GroupService.progress(0, 0), 0);
  });

  test('rotation keeps payout order and handles empty members', () {
    final now = DateTime.now();
    final members = [
      GroupMember('b', 'g', 'b', 'Bisi', 2, now),
      GroupMember('a', 'g', 'a', 'Ada', 1, now),
    ];
    expect(GroupService.recipient(members, 1)?.name, 'Ada');
    expect(GroupService.recipient(members, 2)?.name, 'Bisi');
    expect(GroupService.recipient(members, 3)?.name, 'Ada');
    expect(GroupService.recipient([], 1), isNull);
  });

  test('monthly payout date clamps long month endings', () {
    final group = SavingsGroup(
      id: 'g',
      name: 'Test',
      description: '',
      creatorId: 'a',
      contributionAmountKobo: 100000,
      frequency: 'Monthly',
      maxMembers: 2,
      startDate: DateTime(2026, 1, 31),
      inviteCode: 'AJO-TEST',
      currentCycle: 1,
      createdAt: DateTime(2026),
    );
    expect(GroupService.cycleDate(group, 2), DateTime(2026, 2, 28));
    expect(GroupService.cycleDate(group, 3), DateTime(2026, 3, 31));
    expect(GroupService.currentCycle(group), 1);
  });

  test(
    'cycle completion records payout and resets new contributions',
    () async {
      final now = DateTime.now();
      final user = AppUser(
        'owner',
        'Ada Owner',
        'ada@test.local',
        '08012345678',
        now,
      );
      final group = SavingsGroup(
        id: 'cycle',
        name: 'Cycle Test',
        description: 'Test',
        creatorId: user.id,
        contributionAmountKobo: 500000,
        frequency: 'Weekly',
        maxMembers: 2,
        startDate: now,
        inviteCode: 'AJO-CYCLE',
        currentCycle: 1,
        createdAt: now,
      );
      await StorageService.groups.put(group.id, group.toMap());
      for (var i = 0; i < 2; i++) {
        final member = GroupMember(
          'member-$i',
          group.id,
          i == 0 ? user.id : 'other',
          i == 0 ? 'Ada Owner' : 'Bisi Member',
          i + 1,
          now,
        );
        await StorageService.members.put(member.id, member.toMap());
        final contribution = Contribution(
          'contribution-$i',
          group.id,
          member.id,
          member.name,
          1,
          500000,
          'Paid',
          'ref-$i',
          now,
        );
        await StorageService.contributions.put(
          contribution.id,
          contribution.toMap(),
        );
      }
      final app = AppProvider();
      expect(app.canComplete(group), isTrue);
      await app.completeCycle(group, user);
      expect(app.group(group.id).currentCycle, 2);
      expect(
        app.payouts.where((row) => row.groupId == group.id).single.amountKobo,
        1000000,
      );
      expect(
        app
            .groupContributions(group.id, cycle: 2)
            .every((row) => row.status == 'Pending'),
        isTrue,
      );
      expect(app.groupTransactions(group.id).single.type, 'Payout');
    },
  );

  test('simulated payment writes contribution and transaction once', () async {
    final now = DateTime.now();
    final group = SavingsGroup(
      id: 'payment-group',
      name: 'Payment Test',
      description: '',
      creatorId: 'owner',
      contributionAmountKobo: 300000,
      frequency: 'Weekly',
      maxMembers: 2,
      startDate: now,
      inviteCode: 'AJO-PAYTEST',
      currentCycle: 1,
      createdAt: now,
    );
    final row = Contribution(
      'payment-row',
      group.id,
      'member',
      'Ada',
      1,
      300000,
      'Pending',
      '',
      null,
    );
    await StorageService.groups.put(group.id, group.toMap());
    await StorageService.contributions.put(row.id, row.toMap());
    final app = AppProvider();
    final reference = await app.pay(group, row, succeed: true);
    expect(reference, startsWith('AJO-PAY-'));
    expect(app.balance(group), 300000);
    expect(app.groupTransactions(group.id).single.reference, reference);
    await expectLater(
      app.pay(group, app.groupContributions(group.id).single, succeed: true),
      throwsStateError,
    );
    final failedRow = Contribution(
      'failed-row',
      group.id,
      'second-member',
      'Bisi',
      1,
      300000,
      'Pending',
      '',
      null,
    );
    await StorageService.contributions.put(failedRow.id, failedRow.toMap());
    await expectLater(
      app.pay(group, failedRow, succeed: false),
      throwsStateError,
    );
    expect(
      app
          .groupContributions(group.id)
          .firstWhere((item) => item.id == failedRow.id)
          .status,
      'Failed',
    );
    expect(app.balance(group), 300000);
    expect(app.groupTransactions(group.id).first.status, 'Failed');
  });

  test('local registration, session restore, and logout', () async {
    final auth = AuthService();
    final registered = await auth.register(
      'Test Saver',
      'saver@test.local',
      '08012345678',
      'password123',
    );
    expect(auth.active?.id, registered.id);
    final stored = Map<String, Object?>.from(
      StorageService.users.get(registered.id) as Map,
    );
    expect(stored, isNot(contains('password')));
    expect(stored['passwordHash'], isNot('password123'));
    await expectLater(
      auth.register(
        'Another Saver',
        'saver@test.local',
        '08099999999',
        'password123',
      ),
      throwsStateError,
    );
    await auth.logout();
    expect(auth.active, isNull);
    final loggedIn = await auth.login('saver@test.local', 'password123');
    expect(loggedIn.id, registered.id);
    expect(auth.active?.id, registered.id);
  });

  test('legacy Hive amounts and passwords migrate once', () async {
    await StorageService.groups.put('legacy-money', {
      'contributionAmount': 1250,
    });
    await StorageService.contributions.put('legacy-contribution', {
      'amount': 1250,
    });
    final legacyUser = AppUser(
      'legacy-user',
      'Legacy Saver',
      'legacy@test.local',
      '08012345678',
      DateTime(2026),
    );
    await StorageService.users.put(legacyUser.id, {
      ...legacyUser.toMap(),
      'password': 'password123',
    });

    try {
      await StorageService.migrateLocalData();
      await StorageService.migrateLocalData();
      final group = Map<String, Object?>.from(
        StorageService.groups.get('legacy-money') as Map,
      );
      final contribution = Map<String, Object?>.from(
        StorageService.contributions.get('legacy-contribution') as Map,
      );
      final user = Map<String, Object?>.from(
        StorageService.users.get(legacyUser.id) as Map,
      );
      expect(group['contributionAmountKobo'], 125000);
      expect(group, isNot(contains('contributionAmount')));
      expect(contribution['amountKobo'], 125000);
      expect(contribution, isNot(contains('amount')));
      expect(user, isNot(contains('password')));
      expect(user['passwordHash'], isA<String>());
      expect(money(125050), '₦1,250.50');
      expect(
        (await AuthService().login(legacyUser.email, 'password123')).id,
        legacyUser.id,
      );
    } finally {
      await StorageService.groups.delete('legacy-money');
      await StorageService.contributions.delete('legacy-contribution');
      await StorageService.users.delete(legacyUser.id);
    }
  });

  test(
    'next contribution moves to next month after current cycle is paid',
    () async {
      final group = SavingsGroup(
        id: 'next-month-group',
        name: 'Next Month Test',
        description: '',
        creatorId: 'next-month-user',
        contributionAmountKobo: 2000000,
        frequency: 'Monthly',
        maxMembers: 5,
        startDate: DateTime(2026, 8, 1),
        inviteCode: 'AJO-NEXT',
        currentCycle: 2,
        createdAt: DateTime(2026, 8, 1),
      );
      final member = GroupMember(
        'next-month-member',
        group.id,
        'next-month-user',
        'Test Saver',
        1,
        DateTime(2026, 8, 1),
      );
      final contribution = Contribution(
        'next-month-paid',
        group.id,
        member.id,
        member.name,
        2,
        2000000,
        'Paid',
        'AJO-PAID',
        DateTime(2026, 9, 1),
      );
      await StorageService.groups.put(group.id, group.toMap());
      await StorageService.members.put(member.id, member.toMap());
      await StorageService.contributions.put(
        contribution.id,
        contribution.toMap(),
      );

      final next = AppProvider().nextContribution(
        member.userId,
        DateTime(2026, 9, 30),
      );
      expect(next?.cycle, 3);
      expect(next!.dueDate, DateTime(2026, 10, 1));
    },
  );

  test('contribution dates follow calendar frequencies', () {
    SavingsGroup group(String frequency) => SavingsGroup(
      id: frequency,
      name: frequency,
      description: '',
      creatorId: 'user',
      contributionAmountKobo: 100000,
      frequency: frequency,
      maxMembers: 5,
      startDate: DateTime(2026, 1, 1),
      inviteCode: 'AJO-$frequency',
      currentCycle: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    expect(
      GroupService.nextContributionDate(
        group('Monthly'),
        DateTime(2026, 9, 30),
        currentContributionPaid: false,
      ),
      DateTime(2026, 10, 1),
    );
    expect(
      GroupService.nextContributionDate(
        group('Weekly'),
        DateTime(2026, 9, 30),
        currentContributionPaid: false,
      ),
      DateTime(2026, 10, 5),
    );
    expect(
      GroupService.nextContributionDate(
        group('Daily'),
        DateTime(2026, 9, 30),
        currentContributionPaid: false,
      ),
      DateTime(2026, 9, 30),
    );
  });
}
