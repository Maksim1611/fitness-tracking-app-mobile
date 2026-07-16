import 'package:flutter/material.dart';

import '../main.dart';
import '../services/api_client.dart';
import 'measurements_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? me;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadMe();
  }

  Future<void> loadMe() async {
    try {
      final result = await ApiClient.getMe();
      setState(() {
        me = result;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  Future<void> logout() async {
    await ApiClient.logout();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: me == null
          ? Center(child: error.isEmpty ? const CircularProgressIndicator() : Text(error))
          : ListView(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 40,
            child: Text(
              me!['name'].toString().substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            me!['name'],
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '@${me!['username']}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const Divider(),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeMode,
            builder: (context, mode, _) => SwitchListTile(
              title: const Text('Dark mode'),
              secondary: const Icon(Icons.dark_mode_outlined),
              value: mode == ThemeMode.dark,
              onChanged: (isDark) {
                themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Body measurements'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MeasurementsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: logout,
          ),
        ],
      ),
    );
  }
}