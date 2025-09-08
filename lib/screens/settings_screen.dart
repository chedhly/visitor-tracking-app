import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.color_lens),
              title: Text('Appearance'),
              subtitle: Text('Customize the look of the app'),
            ),
          ),
          Consumer<SettingsService>(
            builder: (context, settings, child) {
              return Card(
                child: SwitchListTile(
                  title: Text('Dark Mode'),
                  value: settings.isDarkMode,
                  onChanged: settings.toggleDarkMode,
                  secondary: Icon(settings.isDarkMode
                      ? Icons.nightlight_round
                      : Icons.wb_sunny),
                ),
              );
            },
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              subtitle: Text('Configure alert settings'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.security),
              title: Text('Privacy & Security'),
              subtitle: Text('Manage data and permissions'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.help),
              title: Text('Help & Support'),
              subtitle: Text('Get help and contact support'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              subtitle: Text('App version and information'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Visitor Tracking',
                  applicationVersion: '1.0.0',
                  applicationIcon: CircleAvatar(
                    backgroundColor: Color(0xFF2196F3),
                    child: Icon(Icons.directions_car, color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}