import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visitor_tracking_app/classes/sidebar.dart';
import 'package:visitor_tracking_app/services/setting_provider.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color(0xffd9d9d9),
          title: Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Row(
              children: [
                const Text(
                  'Visitor Tracking',
                  style: TextStyle(
                    fontFamily: 'Montserrat-Bold',
                    fontSize: 40,
                  ),
                ),
                const Spacer(),
                Icon(Icons.account_circle, size: 40, color: Colors.black),
              ],
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          Container(
            width: 80,
            color: const Color(0xffffffff),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/home'),
                  child: sidebarItem(Icons.home, "", false),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/today'),
                  child: sidebarItem(Icons.calendar_today, "", false),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/history'),
                  child: sidebarItem(Icons.history, "", false),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/setting'),
                  child: sidebarItem(Icons.settings, "", true),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('General'),
                    _buildSettingRow(
                      'Language',
                      DropdownButton<String>(
                        value: settingsProvider.selectedLanguage,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            settingsProvider.updateSettings(language: newValue);
                          }
                        },
                        items: <String>['English', 'French', 'Arabic']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    _buildSettingRow(
                      'Theme',
                      Row(
                        children: [
                          _buildThemeOption('light', Icons.light_mode, settingsProvider),
                          const SizedBox(width: 16),
                          _buildThemeOption('dark', Icons.dark_mode, settingsProvider),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    _buildSectionHeader('Alert'),
                    _buildSettingRow(
                      'max stay time',
                      Row(
                        children: [
                          _buildTimeDropdown(
                            value: settingsProvider.maxStayHours,
                            items: List.generate(25, (index) => index),
                            onChanged: (value) {
                              if (value != null) {
                                settingsProvider.updateSettings(maxStayHours: value);
                              }
                            },
                            unit: 'h',
                          ),
                          const SizedBox(width: 16),
                          _buildTimeDropdown(
                            value: settingsProvider.maxStayMinutes,
                            items: [0, 15, 30, 45],
                            onChanged: (value) {
                              if (value != null) {
                                settingsProvider.updateSettings(maxStayMinutes: value);
                              }
                            },
                            unit: 'm',
                          ),
                        ],
                      ),
                    ),
                    _buildSettingRow(
                      'alert method',
                      Row(
                        children: [
                          _buildAlertMethodOption('sound', Icons.volume_up, settingsProvider),
                          const SizedBox(width: 16),
                          _buildAlertMethodOption('vibration', Icons.vibration, settingsProvider),
                          const SizedBox(width: 16),
                          _buildAlertMethodOption('both', Icons.notifications, settingsProvider),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('Data management'),
                    _buildSettingRow(
                      'export DB',
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement export functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          'Export',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('About'),
                    _buildSettingRow('app version', const Text('v1.0.0')),
                    _buildSettingRow('device ID', const Text('00:1A:2B:3C:4D:5E')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto-Bold',
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, Widget controlWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto-Medium',
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(child: controlWidget),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String theme, IconData icon, SettingsProvider settingsProvider) {
    return GestureDetector(
      onTap: () {
        settingsProvider.updateSettings(theme: theme);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: settingsProvider.selectedTheme == theme ? Colors.blue : Color(0xffeeeeee),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: settingsProvider.selectedTheme == theme ? Colors.blue : Color(0xffe0e0e0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: settingsProvider.selectedTheme == theme ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(
              theme,
              style: TextStyle(
                color: settingsProvider.selectedTheme == theme ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDropdown({
    required int value,
    required List<int> items,
    required Function(int?) onChanged,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<int>>((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('$value$unit'),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAlertMethodOption(String method, IconData icon, SettingsProvider settingsProvider) {
    return GestureDetector(
      onTap: () {
        settingsProvider.updateSettings(alertMethod: method);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: settingsProvider.alertMethod == method ? Colors.blue : Color(0xffeeeeee),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: settingsProvider.alertMethod == method ? Colors.blue : Color(0xffe0e0e0),
          ),
        ),
        child: Icon(
          icon,
          color: settingsProvider.alertMethod == method ? Colors.white : Colors.black,
          size: 24,
        ),
      ),
    );
  }

  void _exportDatabase() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Export Database'),
        content: Text('Database export functionality will create a backup file with all visitor data.\n\nThis feature will be implemented based on your specific requirements.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Implement actual export
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Export feature coming soon')),
              );
            },
            child: Text('Export'),
          ),
        ],
      ),
    );
  }
}