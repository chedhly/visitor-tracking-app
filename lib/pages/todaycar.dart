import 'package:flutter/material.dart' hide TableCell;
import 'package:visitor_tracking_app/classes/sidebar.dart';
import 'package:visitor_tracking_app/classes/cartable.dart';
import 'package:provider/provider.dart';
import 'package:visitor_tracking_app/services/setting_provider.dart';
import 'package:visitor_tracking_app/services/data base.dart';

class Tcar extends StatefulWidget {
  const Tcar({super.key});

  @override
  State<Tcar> createState() => _TcarState();
}

class _TcarState extends State<Tcar> {
  List<Car> cars = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayCars();
  }

  Future<void> _loadTodayCars() async {
    try {
      final todayCarsData = await RemoteDatabaseHelper.getTodayCars();
      final settings = await RemoteDatabaseHelper.getSettings();
      final maxStayHours = settings['max_stay_hours'] ?? 8;
      final maxStayMinutes = settings['max_stay_minutes'] ?? 0;
      final maxStayDuration = Duration(hours: maxStayHours, minutes: maxStayMinutes);

      setState(() {
        cars = todayCarsData.map((carData) {
          DateTime entryTime = DateTime.parse(carData['entry_time']);
          String exitTimeStr = "--:--";
          String durationStr = "";

          if (carData['exit_time'] != null) {
            DateTime exitTime = DateTime.parse(carData['exit_time']);
            exitTimeStr = "${exitTime.hour.toString().padLeft(2, '0')}:${exitTime.minute.toString().padLeft(2, '0')}";
            Duration duration = exitTime.difference(entryTime);
            durationStr = "${duration.inHours}h${duration.inMinutes.remainder(60)}m";
          } else {
            // Car is still inside
            Duration currentDuration = DateTime.now().difference(entryTime);
            if (currentDuration >= maxStayDuration) {
              durationStr = ">${maxStayHours}h";
            } else {
              durationStr = "${currentDuration.inHours}h${currentDuration.inMinutes.remainder(60)}m";
            }
          }

          return Car(
            id: carData['id'],
            plateNum: carData['plate_number'],
            entryTime: "${entryTime.hour.toString().padLeft(2, '0')}:${entryTime.minute.toString().padLeft(2, '0')}",
            exitTime: exitTimeStr,
            duration: durationStr,
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading today\'s cars: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final maxStayDuration = settingsProvider.maxStayDuration;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color(0xffd9d9d9),
          title: Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Row(
              children: const [
                Text(
                  'visitor tracking',
                  style: TextStyle(
                    fontFamily: 'Montserrat-Bold',
                    fontSize: 28,
                    color: Colors.black,
                  ),
                ),
                Spacer(),
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
              child: sidebarItem(Icons.calendar_today, "", true),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/history'),
              child: sidebarItem(Icons.history, "", false),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/setting'),
              child: sidebarItem(Icons.settings, "", false),
            ),
          ],
        ),
      ),
      Expanded(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Vehicles (${cars.length})',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto-Bold',
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _loadTodayCars,
                    icon: Icon(Icons.refresh, color: Colors.white),
                    label: Text('Refresh', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Table(
                border: TableBorder.all(color: Colors.black26, width: 1),
                columnWidths: const {
                  0: FixedColumnWidth(60),
                  1: FlexColumnWidth(),
                  2: FixedColumnWidth(120),
                  3: FixedColumnWidth(120),
                  4: FixedColumnWidth(120),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade300),
                    children: const [
                      TableHeader("ID"),
                      TableHeader("Plate Number"),
                      TableHeader("Entry Time"),
                      TableHeader("Exit Time"),
                      TableHeader("Duration"),
                    ],
                  ),

                  ...cars.map((car) {
                    final isOverstay = car.duration.contains(">") ||
                        (car.exitTime == "--:--" && car.duration.isEmpty);
                    final rowColor = isOverstay ? Colors.red.shade400 : Colors.grey.shade100;
                    final textColor = isOverstay ? Colors.white : Colors.black;

                    return TableRow(
                      decoration: BoxDecoration(color: rowColor),
                      children: [
                        TableCell(car.id.toString(), textColor),
                        TableCell(car.plateNum, textColor),
                        TableCell(car.entryTime, textColor),
                        TableCell(car.exitTime, textColor),
                        TableCell(car.duration, textColor),
                      ],
                    );
                  })
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    ],
    ),
    );
  }
}