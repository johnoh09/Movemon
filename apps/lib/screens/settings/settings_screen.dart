import 'package:flutter/material.dart';
import 'package:flutter_diet_app/api/api_client.dart';
import 'package:flutter_diet_app/auth_repo.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_diet_app/notifications/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final ApiClient api;
  const SettingsScreen({super.key, required this.api});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Persist simple settings with secure storage (already in project)
  static const _kWorkoutReminders = 'pref_workout_reminders';
  static const _kBadgeAlerts = 'pref_badge_alerts';
  static const _kReminderTime = 'pref_workout_time'; // 'HH:mm'
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _workoutReminders = true;
  bool _badgeAlerts = true;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final wr = await _storage.read(key: _kWorkoutReminders);
      final ba = await _storage.read(key: _kBadgeAlerts);
      final tm = await _storage.read(key: _kReminderTime);
      if (tm != null && tm.contains(':')) {
        final parts = tm.split(':');
        final h = int.tryParse(parts[0]) ?? 9;
        final m = int.tryParse(parts[1]) ?? 0;
        _reminderTime = TimeOfDay(hour: h, minute: m);
      }
      if (!mounted) return;
      setState(() {
        _workoutReminders = wr == null ? true : (wr == '1');
        _badgeAlerts = ba == null ? true : (ba == '1');
        _loadingPrefs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPrefs = false;
      });
    }
  }

  Future<void> _setWorkoutReminders(bool v) async {
    setState(() => _workoutReminders = v);
    await _storage.write(key: _kWorkoutReminders, value: v ? '1' : '0');
    await _applyReminderSchedule();
  }

  Future<void> _setBadgeAlerts(bool v) async {
    setState(() => _badgeAlerts = v);
    await _storage.write(key: _kBadgeAlerts, value: v ? '1' : '0');
    // TODO: route to in-app notification preferences if needed
  }

  Future<void> _applyReminderSchedule() async {
    // Ensure notifications are initialized (safe to call multiple times)
    await NotificationService().init();
    if (_workoutReminders) {
      await NotificationService().scheduleDailyReminder(_reminderTime);
    } else {
      await NotificationService().cancelDailyReminder();
    }
  }
  
  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked == null) return;
    setState(() => _reminderTime = picked);
    await _storage.write(
      key: _kReminderTime,
      value: '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
    );
    if (_workoutReminders) {
      await _applyReminderSchedule();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder time updated')),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthRepo(widget.api).logout(); // clears token/session

    if (!mounted) return;
    // Navigate to login and clear stack
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have successfully logged out')),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _loadingPrefs
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Account Settings
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Account Settings'),
                  subtitle: const Text('Update profile info, change password'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Replace with your route when ready
                    _comingSoon(context);
                    // Navigator.pushNamed(context, '/settings/account');
                  },
                ),
                const Divider(),
                // Notification Settings
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Workout Reminders'),
                  subtitle: const Text('Receive workout reminders at scheduled times'),
                  value: _workoutReminders,
                  onChanged: (bool value) => _setWorkoutReminders(value),
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Reminder Time'),
                  subtitle: Text('${_reminderTime.format(context)} (daily)'),
                  trailing: const Icon(Icons.edit_outlined, size: 18),
                  onTap: _workoutReminders ? _pickReminderTime : null,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.celebration_outlined),
                  title: const Text('Badge/Character Alerts'),
                  value: _badgeAlerts,
                  onChanged: (bool value) => _setBadgeAlerts(value),
                ),
                const Divider(),
                // Other Menus
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Privacy Policy & Terms'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _comingSoon(context);
                    // Navigator.pushNamed(context, '/settings/privacy');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help / FAQ'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _comingSoon(context);
                    // Navigator.pushNamed(context, '/settings/help');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('Version 1.0.0'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _comingSoon(context);
                    // showAboutDialog(context: context, applicationVersion: '1.0.0', applicationName: 'Movemon');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notification_important_outlined),
                  title: const Text('Send test notification'),
                  onTap: () async {
                    await NotificationService().init();
                    await NotificationService().showTestNotification();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Log out', style: TextStyle(color: Colors.red)),
                  onTap: () => _logout(context),
                ),
              ],
            ),
    );
  }
}
