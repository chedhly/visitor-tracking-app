import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visitor_tracking_app/classes/sidebar.dart';
import 'package:visitor_tracking_app/classes/sections.dart';
import 'package:visitor_tracking_app/services/data base.dart';
import 'package:visitor_tracking_app/services/setting_provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final RemoteDatabaseHelper dbHelper = RemoteDatabaseHelper();
  int todayCarsCount = 0;
  int insideNowCount = 0;
  int overMaxStayCount = 0;
  String averageDuration = '0h0m';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final todayCars = await RemoteDatabaseHelper.getTodayCars();
      final allCars = await RemoteDatabaseHelper.getCars();
      final settings = await RemoteDatabaseHelper.getSettings();
      final averageDurationResult = await RemoteDatabaseHelper.calculateAverageDuration();

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