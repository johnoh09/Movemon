import 'package:flutter/material.dart';
import 'package:flutter_diet_app/api/api_client.dart';
import 'package:flutter_diet_app/auth_repo.dart';

class SettingsScreen extends StatelessWidget {
  final ApiClient api;
  const SettingsScreen({super.key, required this.api});
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('logout')),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthRepo(api).logout(); // 토큰/세션 클리어 (api.auth.clear())

    if (context.mounted) {
      // 현재 스택 제거하고 로그인으로
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      // 메시지(optional)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have successfully logged out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'), // Settings
      ),
      body: ListView(
        children: [
          // Account Settings
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Account Settings'),
            subtitle: Text('Update profile info, change password'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: null, // Navigate to account settings
          ),
          const Divider(),
          // Notification Settings
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Workout Reminders'),
            subtitle: const Text('Receive workout reminders at scheduled times'),
            value: true, // This should be managed by a state provider
            onChanged: (bool value) {
              // Handle notification setting change
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.celebration_outlined),
            title: const Text('Badge/Character Alerts'),
            value: true,
            onChanged: (bool value) {
              // Handle badge/character notification setting change
            },
          ),
          const Divider(),
          // Other Menus
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Privacy Policy & Terms'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: null, // Navigate to privacy policy
          ),
          const ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('Help / FAQ'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: null, // Navigate to FAQ
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            subtitle: Text('Version 1.0.0'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: null, // Show app info dialog
          ),
           const Divider(),
           ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log out', style: TextStyle(color: Colors.red)),
            onTap: () {
                _logout(context);
            },
          ),
        ],
      ),
    );
  }
}

