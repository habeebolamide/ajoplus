import 'dart:io';
import 'package:ajoplus/models/models.dart';
import 'package:ajoplus/providers/providers.dart';
import 'package:ajoplus/screens/auth/login_screen.dart';
import 'package:ajoplus/screens/auth/signup_screen.dart';
import 'package:ajoplus/screens/contributions/payment_screen.dart';
import 'package:ajoplus/screens/groups/create_group_screen.dart';
import 'package:ajoplus/screens/groups/group_dashboard_screen.dart';
import 'package:ajoplus/screens/main_shell.dart';
import 'package:ajoplus/screens/transactions/transactions_screen.dart';
import 'package:ajoplus/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestNotificationService extends NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<void> show(String title, String body) async {}

  @override
  Future<void> cancelScheduled() async {}

  @override
  Future<void> schedule(
    int id,
    DateTime when,
    String title,
    String message,
  ) async {}
}

class TestPaymentService extends PaymentService {
  @override
  Future<String> simulate({required bool succeed}) async {
    if (!succeed) {
      throw StateError('The simulated payment failed. Please try again.');
    }
    return 'AJO-PAY-TEST';
  }
}

class TestAuthService extends AuthService {
  @override
  Future<AppUser> login(String email, String password) async =>
      AppUser.from(StorageService.users.get('demo'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('ajoplus-widget-');
    Hive.init(directory.path);
    StorageService.users = await Hive.openBox('widget-users');
    StorageService.groups = await Hive.openBox('widget-groups');
    StorageService.members = await Hive.openBox('widget-members');
    StorageService.contributions = await Hive.openBox('widget-contributions');
    StorageService.payouts = await Hive.openBox('widget-payouts');
    StorageService.transactions = await Hive.openBox('widget-transactions');
    StorageService.notifications = await Hive.openBox('widget-notifications');
    SharedPreferences.setMockInitialValues({'seeded': true, 'onboarded': true});
    StorageService.prefs = await SharedPreferences.getInstance();
    final demo = AppUser(
      'demo',
      'Habeeblah Adenubi',
      'demo@ajoplus.local',
      '08012345678',
      DateTime.now(),
    );
    await StorageService.users.put(demo.id, {
      ...demo.toMap(),
      'password': 'password123',
    });
    final group = SavingsGroup(
      id: 'widget-group',
      name: 'Widget Circle',
      description: 'Savings with friends',
      creatorId: demo.id,
      contributionAmountKobo: 2000000,
      frequency: 'Monthly',
      maxMembers: 2,
      startDate: DateTime.now().add(const Duration(days: 2)),
      inviteCode: 'AJO-WIDGET',
      currentCycle: 1,
      createdAt: DateTime.now(),
    );
    await StorageService.groups.put(group.id, group.toMap());
    final member = GroupMember(
      'widget-member',
      group.id,
      demo.id,
      demo.fullName,
      1,
      DateTime.now(),
    );
    await StorageService.members.put(member.id, member.toMap());
    final contribution = Contribution(
      'widget-contribution',
      group.id,
      member.id,
      member.name,
      1,
      2000000,
      'Pending',
      '',
      null,
    );
    await StorageService.contributions.put(
      contribution.id,
      contribution.toMap(),
    );
    final transaction = AppTransaction(
      'widget-transaction',
      group.id,
      member.id,
      member.name,
      group.name,
      'Contribution',
      2000000,
      'Successful',
      'AJO-PAY-WIDGET',
      DateTime.now(),
    );
    await StorageService.transactions.put(transaction.id, transaction.toMap());
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Widget wrap(Widget screen, {AuthService? authService}) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(service: authService)),
      ChangeNotifierProvider(
        create: (_) => AppProvider(
          paymentService: TestPaymentService(),
          notificationService: TestNotificationService(),
        ),
      ),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: MaterialApp(home: screen),
  );

  testWidgets('login validates fields and accepts the demo account', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const LoginScreen(), authService: TestAuthService()),
    );
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'demo@ajoplus.local',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Habeeblah'), findsWidgets);
  });

  testWidgets('registration shows all required fields', (tester) async {
    await tester.pumpWidget(wrap(const SignUpScreen()));
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });

  testWidgets('dashboard exposes group actions', (tester) async {
    await StorageService.prefs.setString('session', 'demo');
    await tester.pumpWidget(wrap(const MainShell()));
    await tester.pump();
    expect(find.text('Create Group'), findsOneWidget);
    expect(find.text('Join Group'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.byTooltip('Notifications'), findsOneWidget);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('create group form rejects missing details', (tester) async {
    await tester.pumpWidget(wrap(const CreateGroupScreen()));
    await tester.ensureVisible(find.text('Create Group'));
    await tester.tap(find.text('Create Group'));
    await tester.pump();
    expect(find.text('Enter a group name'), findsOneWidget);
    expect(find.text('Enter an amount above zero'), findsOneWidget);
  });

  testWidgets('group dashboard calculates balance from contributions', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const GroupDashboardScreen(groupId: 'widget-group')),
    );
    expect(find.text('Widget Circle'), findsOneWidget);
    expect(find.text('₦0 / ₦40,000'), findsOneWidget);
    expect(find.text('Cycle 1 of 2'), findsOneWidget);
  });

  testWidgets('payment screen shows amount and both simulation actions', (
    tester,
  ) async {
    await StorageService.prefs.setString('session', 'demo');
    await tester.pumpWidget(
      wrap(
        const PaymentScreen(
          groupId: 'widget-group',
          contributionId: 'widget-contribution',
        ),
      ),
    );
    expect(find.text('₦20,000'), findsOneWidget);
    expect(find.text('Pay Contribution'), findsOneWidget);
    expect(find.text('Simulate failed payment'), findsOneWidget);
  });

  testWidgets('transaction history shows recorded payment', (tester) async {
    await tester.pumpWidget(wrap(const Scaffold(body: TransactionsTab())));
    expect(find.text('Contribution'), findsWidgets);
    expect(find.text('₦20,000'), findsWidgets);
  });
}
