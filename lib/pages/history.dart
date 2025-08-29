import 'package:flutter/material.dart' hide TableCell;
import 'package:visitor_tracking_app/classes/sidebar.dart';
import 'package:visitor_tracking_app/classes/cartable.dart';
import 'package:visitor_tracking_app/services/data base.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<Car> cars = [];
  List<Car> allCars = [];
  bool isLoading = true;

  String searchQuery = "";
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    try {
      final carsData = await RemoteDatabaseHelper.getCars();

      setState(() {
        allCars = carsData.map((carData) {
          DateTime entryTime = DateTime.parse(carData['entry_time']);
          String exitTimeStr = "--:--";
          String durationStr = "";
          String dateStr = "${entryTime.day}/${entryTime.month}/${entryTime.year}";

          if (carData['exit_time'] != null) {
            DateTime exitTime = DateTime.parse(carData['exit_time']);
            exitTimeStr = "${exitTime.hour.toString().padLeft(2, '0')}:${exitTime.minute.toString().padLeft(2, '0')}";
            Duration duration = exitTime.difference(entryTime);
            durationStr = "${duration.inHours}h${duration.inMinutes.remainder(60)}m";
          }

          return Car(
            id: carData['id'],
            plateNum: carData['plate_number'],
            entryTime: "${entryTime.hour.toString().padLeft(2, '0')}:${entryTime.minute.toString().padLeft(2, '0')}",
            exitTime: exitTimeStr,
            date: dateStr,
            duration: durationStr,
          );
        }).toList();

        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      cars = allCars.where((car) {
        bool matchesSearch = car.plateNum.toLowerCase().contains(searchQuery.toLowerCase());
        bool matchesDate = true;

        if (selectedDate != null) {
          // Parse car date and compare
          List<String> dateParts = car.date!.split('/');
          DateTime carDate = DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
          );
          matchesDate = carDate.year == selectedDate!.year &&
              carDate.month == selectedDate!.month &&
              carDate.day == selectedDate!.day;
        }

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  'Visitor Tracking',
                  style: TextStyle(
                    fontFamily: 'Montserrat-Bold',
                    fontSize: 40,
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
                  child: sidebarItem(Icons.calendar_today, "", false),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/history'),
                  child: sidebarItem(Icons.history, "", true),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/setting'),
                  child: sidebarItem(Icons.settings, "", false),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Search by plate number",
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 16),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // TODO: hook to backend for export
                        },
                        child: const Text("Export", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (selectedDate != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        "Showing data for: ${selectedDate!.toString().split(' ')[0]}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Table(
                        border: TableBorder.all(color: Colors.black26, width: 1),
                        columnWidths: const {
                          0: FixedColumnWidth(60),
                          1: FlexColumnWidth(),
                          2: FixedColumnWidth(120),
                          3: FixedColumnWidth(120),
                          4: FixedColumnWidth(120),
                          5: FixedColumnWidth(120),
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Color(0xffe0e0e0)),
                            children: [
                              TableHeader("ID"),
                              TableHeader("Plate Number"),
                              TableHeader("Entry Time"),
                              TableHeader("Exit Time"),
                              TableHeader("Date"),
                              TableHeader("Duration"),
                            ],
                          ),

                          ...filteredCars.map((car) {
                            return TableRow(
                              decoration: BoxDecoration(color: Colors.grey.shade100),
                              children: [
                                TableCell(car.id.toString(), Colors.black),
                                TableCell(car.plateNum, Colors.black),
                                TableCell(car.entryTime, Colors.black),
                                TableCell(car.exitTime, Colors.black),
                                TableCell(car.date ?? "N/A", Colors.black),
                                TableCell(car.duration, Colors.black),
                              ],
                            );
                          })
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    // Simple export functionality - in production you'd implement CSV/PDF export
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Export Data'),
        content: Text('Export functionality will be implemented based on your requirements.\n\nCurrent data: ${cars.length} records'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK'),
          )
        ],
      ),
    );
  }
}