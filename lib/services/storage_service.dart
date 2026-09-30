import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'password_hash.dart';

class StorageService {
  static late Box users,
      groups,
      members,
      contributions,
      payouts,
      transactions,
      notifications;
  static late SharedPreferences prefs;
  static Future<void> init() async {
    await Hive.initFlutter();
    users = await Hive.openBox('users');
    groups = await Hive.openBox('groups');
    members = await Hive.openBox('members');
    contributions = await Hive.openBox('contributions');
    payouts = await Hive.openBox('payouts');
    transactions = await Hive.openBox('transactions');
    notifications = await Hive.openBox('notifications');
    prefs = await SharedPreferences.getInstance();
    await migrateLocalData();
    await seed();
  }

  static List<T> read<T>(Box box, T Function(Object?) decode) =>
      box.values.map(decode).toList();

  static Future<void> migrateLocalData() async {
    await _migrateAmount(
      groups,
      'contributionAmount',
      'contributionAmountKobo',
    );
    for (final box in [contributions, payouts, transactions]) {
      await _migrateAmount(box, 'amount', 'amountKobo');
    }

    for (final key in users.keys.toList()) {
      final stored = Map<String, Object?>.from(users.get(key) as Map);
      final password = stored.remove('password') as String?;
      if (password == null) continue;
      stored['passwordHash'] = await hashPassword(password);
      await users.put(key, stored);
    }
  }

  static Future<void> _migrateAmount(
    Box box,
    String oldKey,
    String newKey,
  ) async {
    for (final key in box.keys.toList()) {
      final stored = Map<String, Object?>.from(box.get(key) as Map);
      if (stored.containsKey(newKey)) continue;
      stored[newKey] = (stored.remove(oldKey) as int) * 100;
      await box.put(key, stored);
    }
  }

  static Future<void> seed() async {
    if (prefs.getBool('seeded') == true) return;
    final now = DateTime.now();
    final demo = AppUser(
      'demo',
      'Habeeblah Adenubi',
      'demo@ajoplus.local',
      '08012345678',
      now,
    );
    await users.put(demo.id, {
      ...demo.toMap(),
      'passwordHash': await hashPassword('password123'),
    });
    final first = SavingsGroup(
      id: 'campus',
      name: 'Campus Savers',
      description: 'A trusted monthly savings circle for friends.',
      creatorId: demo.id,
      contributionAmountKobo: 2000000,
      frequency: 'Monthly',
      maxMembers: 5,
      startDate: DateTime(now.year, now.month - 1, 1),
      inviteCode: 'AJO-CAMPUS',
      currentCycle: 2,
      createdAt: now,
    );
    final second = SavingsGroup(
      id: 'market',
      name: 'Market Circle',
      description: 'Small weekly contributions, steady progress.',
      creatorId: 'organizer-market',
      contributionAmountKobo: 500000,
      frequency: 'Weekly',
      maxMembers: 4,
      startDate: DateTime(now.year, now.month, now.day + 2),
      inviteCode: 'AJO-MARKET',
      currentCycle: 1,
      createdAt: now,
    );
    final third = SavingsGroup(
      id: 'family',
      name: 'Family Goals',
      description: 'A biweekly family savings group.',
      creatorId: 'organizer-family',
      contributionAmountKobo: 1000000,
      frequency: 'Biweekly',
      maxMembers: 6,
      startDate: DateTime(now.year, now.month, now.day + 5),
      inviteCode: 'AJO-FAMILY',
      currentCycle: 1,
      createdAt: now,
    );
    for (final group in [first, second, third]) {
      await groups.put(group.id, group.toMap());
    }
    final names = [
      'Habeeblah Adenubi',
      'Sodiq Badmus',
      'Aleem Karemu',
      'Ibrahim Yusuf',
      'Tobi Adeyemi',
    ];
    for (var i = 0; i < names.length; i++) {
      final member = GroupMember(
        'campus-$i',
        first.id,
        i == 0 ? demo.id : 'demo-$i',
        names[i],
        i + 1,
        now,
      );
      await members.put(member.id, member.toMap());
      final current = Contribution(
        'campus-2-$i',
        first.id,
        member.id,
        member.name,
        2,
        first.contributionAmountKobo,
        i == 2 ? 'Pending' : 'Paid',
        i == 2 ? '' : 'AJO-DEMO-$i',
        i == 2 ? null : now.subtract(const Duration(days: 1)),
      );
      await contributions.put(current.id, current.toMap());
      if (i != 2) {
        final tx = AppTransaction(
          'tx-demo-$i',
          first.id,
          member.id,
          member.name,
          first.name,
          'Contribution',
          first.contributionAmountKobo,
          'Successful',
          current.paymentReference,
          now.subtract(Duration(days: 1, minutes: i)),
        );
        await transactions.put(tx.id, tx.toMap());
      }
      final previous = Contribution(
        'campus-1-$i',
        first.id,
        member.id,
        member.name,
        1,
        first.contributionAmountKobo,
        'Paid',
        'AJO-PREV-$i',
        now.subtract(const Duration(days: 35)),
      );
      await contributions.put(previous.id, previous.toMap());
    }
    final payout = Payout(
      'payout-demo-1',
      first.id,
      'campus-0',
      1,
      10000000,
      first.startDate,
      'Completed',
      now.subtract(const Duration(days: 30)),
    );
    await payouts.put(payout.id, payout.toMap());
    final marketNames = ['Ada Okafor', 'Chinedu Eze'];
    for (var i = 0; i < marketNames.length; i++) {
      final member = GroupMember(
        'market-$i',
        second.id,
        'market-user-$i',
        marketNames[i],
        i + 1,
        now,
      );
      await members.put(member.id, member.toMap());
      final contribution = Contribution(
        'market-1-$i',
        second.id,
        member.id,
        member.name,
        1,
        second.contributionAmountKobo,
        'Pending',
        '',
        null,
      );
      await contributions.put(contribution.id, contribution.toMap());
    }
    final familyMember = GroupMember(
      'family-0',
      third.id,
      'family-user-0',
      'Bisi Adebayo',
      1,
      now,
    );
    await members.put(familyMember.id, familyMember.toMap());
    await contributions.put(
      'family-1-0',
      Contribution(
        'family-1-0',
        third.id,
        familyMember.id,
        familyMember.name,
        1,
        third.contributionAmountKobo,
        'Pending',
        '',
        null,
      ).toMap(),
    );
    await notifications.put(
      'welcome',
      AppNotification(
        'welcome',
        'Welcome to AjoPlus',
        'Campus Savers is ready. Follow contributions and your payout turn here.',
        'info',
        now,
        false,
      ).toMap(),
    );
    await prefs.setBool('seeded', true);
  }
}
