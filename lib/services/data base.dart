import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visitor_tracking_app/classes/sidebar.dart';
import 'package:visitor_tracking_app/classes/sections.dart';
import 'package:visitor_tracking_app/services/data base.dart';
import 'package:visitor_tracking_app/services/setting_provider.dart';
import 'package:visitor_tracking_app/services/monitoring.dart';

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
  bool isMonitoring = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startMonitoring();
  }

  @override
  void dispose() {
    MonitoringService.stopMonitoring();
    super.dispose();
  }

  void _startMonitoring() {
    MonitoringService.startMonitoring(context);
    setState(() {
      isMonitoring = MonitoringService.isMonitoring();
    });
  }

  Future<void> _loadData() async {
    try {
      final todayCars = await RemoteDatabaseHelper.getTodayCars();
      final carsInside = await RemoteDatabaseHelper.getCarsInsideNow();
      final settings = await RemoteDatabaseHelper.getSettings();
      final averageDurationResult = await RemoteDatabaseHelper.calculateAverageDuration();
      final overstayCars = await MonitoringService.getOverstayCars();


      setState(() {
        todayCarsCount = todayCars.length;
        insideNowCount = carsInside.length;
        overMaxStayCount = overstayCars.length;
        averageDuration = averageDurationResult;
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

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
                const Text('Visitor Tracking',
                  style: TextStyle(
                    fontFamily: 'Montserrat-Bold',
                    fontSize: 40,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isMonitoring ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMonitoring ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isMonitoring ? 'Monitoring' : 'Offline',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.account_circle, size: 40, color: Colors.black),
                  ],
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
}