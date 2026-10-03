import 'dart:convert';

import 'package:ajoplus/models/contribution.dart';
import 'package:ajoplus/models/group_member.dart';
import 'package:ajoplus/models/group_preview.dart';
import 'package:ajoplus/models/savings_group.dart';
import 'package:ajoplus/models/app_user.dart';
import 'package:ajoplus/providers/app_provider.dart';
import 'package:ajoplus/screens/groups/create_group_screen.dart';
import 'package:ajoplus/screens/groups/members_screen.dart';
import 'package:ajoplus/screens/contributions/contributions_screen.dart';
import 'package:ajoplus/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:ajoplus/services/api_client.dart';
import 'package:ajoplus/services/group_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:http/testing.dart';

import 'api_integration_test.dart' show group, user, jsonResponse, page;

void main() {
  final savingsData = {
    ...group,
    'ajo_type': 'savings',
    'savings_cycles': 3,
    'frequency': 'weekly',
    'start_date': '2026-10-03',
  };

  test('old groups remain rotating and savings duration survives storage', () {
    final legacy = SavingsGroup.fromApi(group);
    expect(legacy.ajoType, AjoType.rotating);
    expect(legacy.totalCycles, 2);
    final saved = SavingsGroup.fromApi(savingsData);
    final restored = SavingsGroup.from(saved.toMap()).withCycle(2);
    expect(restored.ajoType, AjoType.savings);
    expect(restored.totalCycles, 3);
    expect(
      () => SavingsGroup.from({...saved.toMap(), 'totalCycles': 0}),
      throwsFormatException,
    );
    expect(restored.contributionAmountKobo, 125050);
    expect(GroupService.maturityDate(restored), DateTime(2026, 10, 24));
    expect(
      GroupService.dateForCycle(DateTime(2026, 1, 31), 'Monthly', 2),
      DateTime(2026, 2, 28),
    );
    final legacyMap = legacy.toMap()
      ..remove('ajoType')
      ..remove('totalCycles')
      ..remove('contributionAmountKobo');
    legacyMap['contributionAmount'] = 1250;
    expect(SavingsGroup.from(legacyMap).contributionAmountKobo, 125000);
  });

  test('unknown types and invalid savings durations fail at the boundary', () {
    for (final data in [
      {...savingsData, 'ajo_type': 'unknown'},
      {...savingsData, 'savings_cycles': null},
      {...savingsData, 'savings_cycles': 0},
      {...savingsData, 'savings_cycles': 366},
      {...savingsData, 'savings_cycles': '3'},
    ]) {
      expect(() => SavingsGroup.fromApi(data), throwsA(isA<ApiException>()));
      expect(
        () => GroupPreview.fromApi({...data, 'members_count': 1}),
        throwsA(isA<ApiException>()),
      );
    }
  });

  test(
    'savings balance accumulates and cycles are independent of member count',
    () {
      final api = ApiClient(baseUri: Uri.parse('https://example.com/api/v1/'));
      final app = AppProvider(api: api);
      addTearDown(app.dispose);
      final saved = SavingsGroup.fromApi(savingsData).withCycle(3);
      app.groups = [saved];
      app.members = [
        GroupMember('11', saved.id, '7', 'Ada', 1, saved.startDate),
        GroupMember('12', saved.id, '8', 'Bola', 2, saved.startDate),
      ];
      app.contributions = [
        for (var cycle = 1; cycle <= 3; cycle++)
          for (final member in app.members)
            Contribution(
              '$cycle-${member.id}',
              saved.id,
              member.id,
              member.name,
              cycle,
              125050,
              'Paid',
              'REF-$cycle-${member.id}',
              saved.startDate,
            ),
      ];
      expect(app.balance(saved), 750300);
      expect(app.expected(saved), 750300);
      expect(app.recipient(saved), isNull);
      expect(app.nextContribution('7', saved.startDate), isNull);
      final earlier = saved.withCycle(2);
      app.groups = [earlier];
      expect(app.nextContribution('7', saved.startDate)!.cycle, 3);
      app.groups = [saved.withCycle(4)];
      expect(app.canComplete(app.groups.single), isFalse);
    },
  );

  test('fully paid savings cannot prepare repayments before maturity', () {
    final future = SavingsGroup.fromApi({
      ...savingsData,
      'start_date': '${DateTime.now().year + 1}-01-01',
    }).withCycle(3);
    final app = AppProvider(
      api: ApiClient(baseUri: Uri.parse('https://example.com/api/v1/')),
    );
    addTearDown(app.dispose);
    app.members = [
      GroupMember('11', future.id, '7', 'Ada', 1, future.startDate),
      GroupMember('12', future.id, '8', 'Bola', 2, future.startDate),
    ];
    app.contributions = [
      for (var cycle = 1; cycle <= 3; cycle++)
        for (final member in app.members)
          Contribution(
            '$cycle-${member.id}',
            future.id,
            member.id,
            member.name,
            cycle,
            125050,
            'Paid',
            'REF',
            future.startDate,
          ),
    ];
    expect(app.canComplete(future), isFalse);
    expect(app.canComplete(future.withCycle(2)), isTrue);
  });

  test(
    'create and settlement requests carry type, duration and chosen repayment',
    () async {
      final api = ApiClient(
        baseUri: Uri.parse('https://example.com/api/v1/'),
        httpClient: MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith('/groups')) {
            final body = jsonDecode(request.body);
            expect(body['ajo_type'], 'savings');
            expect(body['savings_cycles'], 3);
            expect(body['contribution_amount_kobo'], 125050);
            return jsonResponse(savingsData, 201);
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/settle-payout')) {
            expect(jsonDecode(request.body), {
              'reference': 'BANK-123',
              'payout_id': 52,
            });
            return jsonResponse({});
          }
          return jsonResponse(page([]));
        }),
      );
      final app = AppProvider(api: api);
      addTearDown(app.dispose);
      final created = await app.createGroup(
        user: AppUser.fromApi(user),
        name: 'Circle',
        description: 'Savings',
        amountKobo: 125050,
        frequency: 'Weekly',
        maxMembers: 2,
        requiresApproval: false,
        startDate: DateTime(2026, 10, 3),
        ajoType: AjoType.savings,
        savingsCycles: 3,
      );
      expect(created.totalCycles, 3);
      await app.settlePayout(created, ' BANK-123 ', payoutId: '52');
    },
  );

  testWidgets(
    'completed savings show final contributions without overdue members',
    (tester) async {
      final saved = SavingsGroup.fromApi(savingsData).withCycle(4);
      final api = ApiClient(baseUri: Uri.parse('https://example.com/api/v1/'));
      final app = AppProvider(api: api);
      final auth = AuthProvider(api: api)..user = AppUser.fromApi(user);
      addTearDown(app.dispose);
      addTearDown(auth.dispose);
      app.groups = [saved];
      app.members = [
        GroupMember('11', saved.id, '7', 'Ada', 1, saved.startDate),
        GroupMember('12', saved.id, '8', 'Bola', 2, saved.startDate),
      ];
      app.contributions = [
        for (final member in app.members)
          Contribution(
            member.id,
            saved.id,
            member.id,
            member.name,
            3,
            125050,
            'Paid',
            'REF',
            saved.startDate,
          ),
      ];
      Widget screen(Widget child) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: app),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: MaterialApp(home: child),
      );
      await tester.pumpWidget(screen(MembersScreen(groupId: saved.id)));
      expect(find.text('Completed'), findsNWidgets(2));
      expect(find.text('Overdue'), findsNothing);
      await tester.pumpWidget(screen(ContributionsScreen(groupId: saved.id)));
      expect(find.text('Final cycle'), findsOneWidget);
      expect(find.text('No contributions yet'), findsNothing);
      expect(find.text('Pay Contribution'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'creation explains both options and asks duration only for savings',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CreateGroupScreen()));
      expect(find.text(AjoType.rotating.description), findsOneWidget);
      expect(find.text(AjoType.savings.description), findsOneWidget);
      expect(find.text('Savings duration (months)'), findsNothing);
      await tester.tap(find.text('Savings Ajo'));
      await tester.pump();
      expect(find.text('Savings duration (months)'), findsOneWidget);
      await tester.tap(find.text('Rotating Ajo'));
      await tester.pump();
      expect(find.text('Savings duration (months)'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
