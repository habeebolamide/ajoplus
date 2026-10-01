import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/providers.dart';
import 'services/services.dart';
import 'services/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  final api = ApiClient();
  final app = AppProvider(api: api);
  final auth = AuthProvider(api: api)..onSignedOut = app.clear;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: app),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const AjoPlusApp(),
    ),
  );
}
