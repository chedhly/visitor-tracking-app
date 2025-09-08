import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF2196F3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(
                    Icons.directions_car,
                    color: Color(0xFF2196F3),
                    size: 30,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Visitor Tracking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'License Plate System',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/history');
            },
          ),
          ListTile(
            leading: Icon(Icons.today),
            title: Text("Today's Vehicles"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/today-cars');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          Consumer<SettingsService>(
            builder: (context, settings, child) {
              return SwitchListTile(
                title: Text('Dark Mode'),
                value: settings.isDarkMode,
                onChanged: (value) {
                  settings.toggleDarkMode(value);
                },
                secondary: Icon(settings.isDarkMode
                    ? Icons.nightlight_round
                    : Icons.wb_sunny),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Exit'),
            onTap: () {
              // Close the app
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}