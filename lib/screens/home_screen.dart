import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/visitor_service.dart';
import '../services/settings_service.dart';
import 'entry_camera_screen.dart';
import 'exit_camera_screen.dart';
import 'monitoring_screen.dart';
import 'admin_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final visitorService = Provider.of<VisitorService>(context, listen: false);
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    await Future.wait([
      visitorService.loadVisitors(),
      settingsService.loadSettings(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final visitorService = Provider.of<VisitorService>(context);
    final stats = visitorService.getTodayStatistics();

    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle Entry System'),
        actions: [
          if (authService.isAdmin)
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminSettingsScreen()),
              ),
            ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authService.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${authService.currentUser?.name ?? "User"}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Today\'s Total',
                      value: stats.todayCount.toString(),
                      icon: Icons.directions_car,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Inside Now',
                      value: stats.insideNow.toString(),
                      icon: Icons.local_parking,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Overstay',
                      value: stats.overStay.toString(),
                      icon: Icons.warning,
                      color: stats.overStay > 0 ? Colors.red : Colors.grey,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Avg Duration',
                      value: stats.averageDuration,
                      icon: Icons.timer,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              Text(
                'Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _ActionButton(
                title: 'Record Vehicle Entry',
                subtitle: 'Scan license plate for entering vehicle',
                icon: Icons.input,
                color: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EntryCameraScreen()),
                ).then((_) => _loadData()),
              ),
              SizedBox(height: 12),
              _ActionButton(
                title: 'Record Vehicle Exit',
                subtitle: 'Scan license plate for exiting vehicle',
                icon: Icons.output,
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ExitCameraScreen()),
                ).then((_) => _loadData()),
              ),
              SizedBox(height: 12),
              _ActionButton(
                title: 'Monitor Vehicles',
                subtitle: 'View all vehicles and alerts',
                icon: Icons.monitor,
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MonitoringScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
