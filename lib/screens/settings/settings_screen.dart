import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Notification reminders'),
            subtitle: const Text('Show local savings reminders'),
            value: settings.reminders,
            onChanged: (enabled) {
              settings.setReminders(enabled);
              final user = context.read<AuthProvider>().user;
              if (user != null) {
                context.read<AppProvider>().refreshReminders(user.id);
              }
            },
          ),
          const SectionTitle('Appearance'),
          ...ThemeMode.values.map(
            (mode) => ListTile(
              title: Text(mode.name[0].toUpperCase() + mode.name.substring(1)),
              leading: Icon(
                settings.mode == mode
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              onTap: () => settings.setMode(mode),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
