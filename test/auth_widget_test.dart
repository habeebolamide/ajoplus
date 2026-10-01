import 'dart:async';
import 'dart:convert';

import 'package:ajoplus/providers/providers.dart';
import 'package:ajoplus/screens/auth/login_screen.dart';
import 'package:ajoplus/screens/auth/signup_screen.dart';
import 'package:ajoplus/services/api_client.dart';
import 'package:ajoplus/services/storage_service.dart';
import 'package:ajoplus/widgets/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_integration_test.dart' show MemoryCredentials;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('registration password fields can be shown independently', (
    tester,
  ) async {
    final api = ApiClient(
      baseUri: Uri.parse('https://example.com/api/v1/'),
      credentials: MemoryCredentials(),
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(api: api),
        child: const MaterialApp(home: SignUpScreen()),
      ),
    );

    final passwordField = tester.widget<EditableText>(
      find.byType(EditableText).at(3),
    );
    final confirmationField = tester.widget<EditableText>(
      find.byType(EditableText).at(4),
    );
    expect(passwordField.obscureText, isTrue);
    expect(confirmationField.obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(3)).obscureText,
      isFalse,
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(4)).obscureText,
      isTrue,
    );

    await tester.tap(find.byTooltip('Show password confirmation'));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(4)).obscureText,
      isFalse,
    );
  });

  testWidgets('sign-in errors appear at the top of the form', (tester) async {
    final api = ApiClient(
      baseUri: Uri.parse('https://example.com/api/v1/'),
      credentials: MemoryCredentials(),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'These credentials are incorrect.'}),
          422,
        ),
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(api: api),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'ada@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('These credentials are incorrect.'), findsOneWidget);
    expect(find.byType(InlineFormError), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('error snackbars use the danger color and floating style', (
    tester,
  ) async {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
    );
    late Color errorColor;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              errorColor = Theme.of(context).colorScheme.error;
              return TextButton(
                onPressed: () =>
                    showError(context, const ApiException('Payment failed.')),
                child: const Text('Show error'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show error'));
    await tester.pump();

    final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackbar.backgroundColor, errorColor);
    expect(snackbar.behavior, SnackBarBehavior.floating);
    expect(find.byIcon(Icons.error_rounded), findsOneWidget);
  });

  testWidgets('sign-in button shows progress while the request is pending', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    final api = ApiClient(
      baseUri: Uri.parse('https://example.com/api/v1/'),
      credentials: MemoryCredentials(),
      httpClient: MockClient((_) => response.future),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(api: api),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'ada@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Signing in…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    response.complete(
      http.Response(
        jsonEncode({'message': 'These credentials are incorrect.'}),
        422,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('These credentials are incorrect.'), findsOneWidget);
  });

  testWidgets('sign in loads the real API dashboard without demo content', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'reminders': false});
    StorageService.prefs = await SharedPreferences.getInstance();
    final api = ApiClient(
      baseUri: Uri.parse('https://example.com/api/v1/'),
      credentials: MemoryCredentials(),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('auth/login')) {
          expect(jsonDecode(request.body)['email'], 'ada@example.com');
          return http.Response(
            jsonEncode({
              'user': {
                'id': 7,
                'name': 'Ada Okafor',
                'email': 'ada@example.com',
                'phone': '08012345678',
                'created_at': '2026-09-30T12:00:00Z',
              },
              'token': 'access',
              'refresh_token': 'refresh',
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'data': [], 'last_page': 1}), 200);
      }),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(api: api)),
          ChangeNotifierProvider(create: (_) => AppProvider(api: api)),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    expect(find.text('Demo login'), findsNothing);
    await tester.enterText(find.byType(TextFormField).at(0), 'ada@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ada'), findsWidgets);
    expect(find.text('No groups yet'), findsWidgets);
  });
}
