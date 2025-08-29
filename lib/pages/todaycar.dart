import 'package:flutter/material.dart' hide TableCell;
import 'package:visitor_tracking_app/classes/sidebar.dart';
import 'package:visitor_tracking_app/classes/cartable.dart';
import 'package:provider/provider.dart';
import 'package:visitor_tracking_app/services/setting_provider.dart';

class Tcar extends StatefulWidget {
  const Tcar({super.key});

  @override
  State<Tcar> createState() => _TcarState();
}

class _TcarState extends State<Tcar> {
  final List<Car> cars = [
    Car(id: 213, plateNum: "123 tunis 2547", entryTime: "8:45", exitTime: "10:33", duration: "1h48m"),
    Car(id: 214, plateNum: "240 tunis 8571", entryTime: "9:01", exitTime: "--:--", duration: ">8h"),
    Car(id: 215, plateNum: "137 tunis 8727", entryTime: "14:05", exitTime: "--:--", duration: ""),
  ];

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Table(
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
                      TableHeader("id"),
                      TableHeader("plate num"),
                      TableHeader("entry time"),
                      TableHeader("exit time"),
                      TableHeader("duration"),
                    ],
                  ),

                  ...cars.map((car) {
                    final isOverstay = car.duration.contains(">") ||
                        (car.exitTime == "--:--" && car.duration.isEmpty);
                    final rowColor = isOverstay ? Colors.red : Colors.grey.shade200;
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
            ),
          ),
        ],
      ),
    );
  }
}