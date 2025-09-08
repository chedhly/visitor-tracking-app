import 'package:flutter/material.dart' hide NavigationDrawer;
import 'package:provider/provider.dart';
import '../services/visitor_service.dart';
import '../widgets/navigation_drawer.dart';
import '../widgets/statistics_card.dart';
import 'camera_screen.dart';
import 'manual_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitorService>().loadVisitors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visitor Tracking'),
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt, color: Colors.green),
            onPressed: () => _navigateToCamera(),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.orange),
            onPressed: () => _navigateToManualEntry(),
          ),
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 16),
        ],
      ),
      drawer: NavigationDrawer(),
      body: Consumer<VisitorService>(
        builder: (context, visitorService, child) {
          final stats = visitorService.getTodayStatistics();

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _navigateToCamera,
                        icon: Icon(Icons.camera_alt),
                        label: Text('Camera Entry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _navigateToManualEntry,
                        icon: Icon(Icons.edit),
                        label: Text('Manual Entry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Statistics Grid
                Row(
                  children: [
                    Expanded(
                      child: StatisticsCard(
                        title: "Today's Cars",
                        value: stats.todayCount.toString(),
                        buttonText: 'Details',
                        onPressed: () => _navigateToTodayCars(),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: StatisticsCard(
                        title: 'History',
                        value: '',
                        buttonText: 'Open',
                        onPressed: () => _navigateToHistory(),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Metrics Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard('inside now', stats.insideNow.toString()),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard('over 8h', stats.overStay.toString()),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard('average duration', stats.averageDuration),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Refresh Button
                ElevatedButton.icon(
                  onPressed: () => context.read<VisitorService>().loadVisitors(),
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF2196F3),
                    side: BorderSide(color: Color(0xFF2196F3)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraScreen()),
    );
  }

  void _navigateToManualEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ManualEntryScreen()),
    );
  }

  void _navigateToTodayCars() {
    Navigator.pushNamed(context, '/today-cars');
  }

  void _navigateToHistory() {
    Navigator.pushNamed(context, '/history');
  }
}
