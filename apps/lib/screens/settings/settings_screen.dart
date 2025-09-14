import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'), // Settings
      ),
      body: ListView(
        children: [
          // Account Settings
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('계정 설정'),
            subtitle: Text('프로필 정보 수정, 비밀번호 변경'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: null, // Navigate to account settings
          ),
          const Divider(),
          // Notification Settings
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('운동 알림'),
            subtitle: const Text('지정한 시간에 운동 알림 받기'),
            value: true, // This should be managed by a state provider
            onChanged: (bool value) {
              // Handle notification setting change
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.celebration_outlined),
            title: const Text('뱃지/캐릭터 변경 알림'),
            value: true,
            onChanged: (bool value) {
              // Handle badge/character notification setting change
            },
          ),
          const Divider(),
          // Other Menus
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('개인 정보 보호 및 약관'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: null, // Navigate to privacy policy
          ),
          const ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('도움말/FAQ'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: null, // Navigate to FAQ
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('앱 정보'),
            subtitle: Text('버전 1.0.0'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: null, // Show app info dialog
          ),
           const Divider(),
           ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
            onTap: () {
              // Handle logout
            },
          ),
        ],
      ),
    );
  }
}

