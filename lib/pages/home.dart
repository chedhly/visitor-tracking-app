import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visitor_tracking_app/classes/sidebar.dart';
import 'package:visitor_tracking_app/classes/sections.dart';
import 'package:visitor_tracking_app/services/mysql_database.dart';
import 'package:visitor_tracking_app/services/setting_provider.dart';
import 'package:visitor_tracking_app/services/monitoring.dart';
import 'package:visitor_tracking_app/services/enhanced_entrance.dart';
import 'package:visitor_tracking_app/services/manual_entry_dialog.dart';
import 'package:visitor_tracking_app/services/pc_camera_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int todayCarsCount = 0;
  int insideNowCount = 0;
  int overMaxStayCount = 0;
  String averageDuration = '0h0m';

  @override
  void initState() {
    super.initState();
    _loadData();
    // Start monitoring service
    MonitoringService.startMonitoring(context);
  }

  @override
  void dispose() {
    MonitoringService.stopMonitoring();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final todayCars = await MySQLDatabaseHelper.getTodayCars();
      final allCars = await MySQLDatabaseHelper.getCars();
      final settings = await MySQLDatabaseHelper.getSettings();
      final averageDurationResult = await MySQLDatabaseHelper.calculateAverageDuration();

      final maxStayHours = settings['max_stay_hours'] ?? 8;
      final maxStayMinutes = settings['max_stay_minutes'] ?? 0;
      final maxStayDuration = Duration(hours: maxStayHours, minutes: maxStayMinutes);

      setState(() {
        todayCarsCount = todayCars.length;
        insideNowCount = allCars.where((car) => car['exit_time'] == null).length;

        overMaxStayCount = allCars.where((car) {
          if (car['exit_time'] != null) return false;
          DateTime entryTime = DateTime.parse(car['entry_time']);
          Duration duration = DateTime.now().difference(entryTime);
          return duration.inHours >= maxStayDuration.inHours;
        }).length;

        averageDuration = averageDurationResult;
      });
    } catch (e) {
      print('Error loading data: $e');
      // Handle error (show message, etc.)
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xffd9d9d9),
          title: Padding(
            padding: EdgeInsets.only(left: 50),
            child: Row(
              children: [
                Text('Visitor Tracking',
                  style: TextStyle(
                      fontFamily: 'Montserrat-Bold',
                      fontSize: 40
                  ),
                ),
                Spacer(),
                Icon(Icons.account_circle, size: 40),
                SizedBox(width: 16),
                // Manual entry button for testing
                ElevatedButton.icon(
                  onPressed: () => _showCameraDetection(),
                  icon: Icon(Icons.camera_alt, color: Colors.white),
                  label: Text('Camera Detection', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showManualEntryDialog(),
                  icon: Icon(Icons.edit, color: Colors.white),
                  label: Text('Manual Entry', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          Container(
            width: 200,
            color: const Color(0xffffffff),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/home'),
                  child: sidebarItem(Icons.home, "Home", true),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/today'),
                  child: sidebarItem(Icons.calendar_today, "Today's cars", false),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/history'),
                  child: sidebarItem(Icons.history, "History", false),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/setting'),
                  child: sidebarItem(Icons.settings, "Setting", false),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    dashboardCard(
                      "Today's Cars",
                      todayCarsCount.toString(),
                      width: 400,
                      height: 250,
                      button: "Details",
                      routeName: '/today',
                      context: context,
                    ),
                    dashboardCard(
                      'History',
                      '',
                      width: 400,
                      height: 250,
                      button: "Open",
                      routeName: '/history',
                      context: context,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    dashboardCard(
                      'inside now',
                      insideNowCount.toString(),
                      width: 250,
                      height: 150,
                    ),
                    dashboardCard(
                      'over ${settingsProvider.maxStayHours}h${settingsProvider.maxStayMinutes > 0 ? settingsProvider.maxStayMinutes.toString() + 'm' : ''}',
                      overMaxStayCount.toString(),
                      width: 250,
                      height: 150,
                    ),
                    dashboardCard(
                      'average duration',
                      averageDuration,
                      width: 250,
                      height: 150,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => const ManualEntryDialog(),
    ).then((_) {
      // Refresh data after manual entry
      _loadData();
    });
  }

  void _showCameraDetection() async {
    try {
      await EnhancedEntranceService.processCarEntranceWithCamera(context);
      // Refresh data after camera entry
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera detection failed: $e')),
      );
    }
  }
}