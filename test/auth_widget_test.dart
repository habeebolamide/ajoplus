import 'dart:convert';

import 'package:ajoplus/providers/providers.dart';
import 'package:ajoplus/screens/auth/login_screen.dart';
import 'package:ajoplus/services/api_client.dart';
import 'package:ajoplus/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_integration_test.dart' show MemoryCredentials;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign in loads the real API dashboard without demo content', (tester) async {
    SharedPreferences.setMockInitialValues({'reminders': false});
    StorageService.prefs = await SharedPreferences.getInstance();
    final api = ApiClient(baseUri: Uri.parse('https://example.com/api/v1/'),
      credentials: MemoryCredentials(),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('auth/login')) {
          expect(jsonDecode(request.body)['email'], 'ada@example.com');
          return http.Response(jsonEncode({'user': {
            'id': 7, 'name': 'Ada Okafor', 'email': 'ada@example.com',
            'phone': '08012345678', 'created_at': '2026-09-30T12:00:00Z',
          }, 'token': 'access', 'refresh_token': 'refresh'}), 200);
        }
        return http.Response(jsonEncode({'data': [], 'last_page': 1}), 200);
      }));
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(api: api)),
      ChangeNotifierProvider(create: (_) => AppProvider(api: api)),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ], child: const MaterialApp(home: LoginScreen())));
    expect(find.text('Demo login'), findsNothing);
    await tester.enterText(find.byType(TextFormField).at(0), 'ada@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ada'), findsWidgets);
    expect(find.text('No groups yet'), findsWidgets);
  });
}
