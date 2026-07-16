import 'package:flutter/material.dart';

import '../main.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
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
        ],
      ),
    );
  }
}