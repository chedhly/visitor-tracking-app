import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visitor_tracking_app/classes/sidebar.dart';
import 'package:visitor_tracking_app/classes/sections.dart';
import 'package:visitor_tracking_app/services/mysql_database.dart';
import 'package:visitor_tracking_app/services/setting_provider.dart';
import 'package:visitor_tracking_app/services/monitoring.dart' hide ManualEntryDialog;
import 'package:visitor_tracking_app/services/enhanced_entrance.dart';
import 'package:visitor_tracking_app/widgets/manual_entry_dialog.dart';
import 'package:visitor_tracking_app/services/pc_camera_service.dart';
import 'package:visitor_tracking_app/services/openalpr_service.dart';
import 'package:visitor_tracking_app/services/camera_openalpr_dialog.dart';
import 'package:visitor_tracking_app/services/notification_service.dart';

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

  void _showOpenALPRDetection() async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => CameraOpenALPRDialog(),
      );

      if (result == true) {
        // Refresh data after successful detection
        _loadData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera entry failed: $e')),
      );
    }
  }

  void _showManualEntryDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) => ManualEntryDialog(),
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

  Future<void> _handleDetectedPlates(List<PlateResult> results) async {
    try {
      if (results.length == 1) {
        // Single plate detected, process directly
        PlateResult result = results.first;
        if (result.confidence >= 80.0) {
          await _processPlateEntry(result.plateNumber);
        } else {
          _showConfirmationDialog(result);
        }
      } else {
        // Multiple plates detected, let user choose
        _showPlateSelectionDialog(results);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing plates: $e')),
      );
    }
  }

  void _showPlateSelectionDialog(List<PlateResult> results) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Multiple Plates Detected'),
        content: Container(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              PlateResult result = results[index];
              return Card(
                child: ListTile(
                  title: Text(result.plateNumber),
                  subtitle: Text('Confidence: ${result.confidence.toStringAsFixed(1)}%'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _processPlateEntry(result.plateNumber);
                      _loadData();
                    },
                    child: Text('Select'),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(PlateResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Plate Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Detected: ${result.plateNumber}'),
            Text('Confidence: ${result.confidence.toStringAsFixed(1)}%'),
            SizedBox(height: 16),
            Text('Confidence is below 80%. Proceed anyway?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _processPlateEntry(result.plateNumber);
              _loadData();
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPlateEntry(String plateNumber) async {
    try {
      // Check if car is already inside
      final existingCars = await MySQLDatabaseHelper.getCarsByPlate(plateNumber);
      final carInside = existingCars.any((car) => car['status'] == 'inside');

      if (carInside) {
        // Process exit
        final carData = existingCars.firstWhere((car) => car['status'] == 'inside');
        DateTime exitTime = DateTime.now();
        DateTime entryTime = DateTime.parse(carData['entry_time']);
        Duration duration = exitTime.difference(entryTime);
        String durationStr = '${duration.inHours}h${duration.inMinutes.remainder(60)}m';

        await MySQLDatabaseHelper.updateCarExit(
          carData['id'],
          exitTime.toIso8601String(),
          durationStr,
        );

        NotificationService.showExitNotification(plateNumber, durationStr);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle $plateNumber exited successfully')),
        );
      } else {
        // Process entry
        DateTime now = DateTime.now();
        await MySQLDatabaseHelper.insertCar({
          'plate_number': plateNumber,
          'entry_time': now.toIso8601String(),
          'status': 'inside',
        });

        NotificationService.showEntryNotification(plateNumber);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle $plateNumber entered successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing entry: $e')),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  Future<void> _processWithOpenALPR(File imageFile) async {
    try {
      // Show processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing with OpenALPR...'),
            ],
          ),
        ),
      );

      // Process with OpenALPR
      List<PlateResult> results = await OpenALPRService.recognizePlate(imageFile);

      // Close processing dialog
      Navigator.of(context).pop();

      if (results.isEmpty) {
        _showErrorDialog('No license plates detected. Please try again with a clearer image.');
        return;
      }

      // Show results dialog
      _showResultsDialog(results, imageFile);
    } catch (e) {
      // Close processing dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      _showErrorDialog('OpenALPR processing failed: $e');
    }
  }

  void _showResultsDialog(List<PlateResult> results, File imageFile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('License Plate Recognition Results'),
        content: Container(
          width: 400,
          height: 300,
          child: Column(
            children: [
              Text('Found ${results.length} plate(s):'),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    PlateResult result = results[index];
                    return Card(
                      child: ListTile(
                        title: Text(result.plateNumber),
                        subtitle: Text('Confidence: ${result.confidence.toStringAsFixed(1)}%'),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _processPlateEntryWithImage(result.plateNumber, imageFile);
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Vehicle ${result.plateNumber} processed successfully')),
                            );
                          },
                          child: Text('Select'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPlateEntryWithImage(String plateNumber, File imageFile) async {
    try {
      // Check if car is already inside
      final existingCars = await MySQLDatabaseHelper.getCarsByPlate(plateNumber);
      final carInside = existingCars.any((car) => car['status'] == 'inside');

      if (carInside) {
        // Process exit
        final carData = existingCars.firstWhere((car) => car['status'] == 'inside');
        DateTime exitTime = DateTime.now();
        DateTime entryTime = DateTime.parse(carData['entry_time']);
        Duration duration = exitTime.difference(entryTime);
        String durationStr = '${duration.inHours}h${duration.inMinutes.remainder(60)}m';

        await MySQLDatabaseHelper.updateCarExit(
          carData['id'],
          exitTime.toIso8601String(),
          durationStr,
        );

        NotificationService.showExitNotification(plateNumber, durationStr);
      } else {
        // Process entry
        DateTime now = DateTime.now();
        await MySQLDatabaseHelper.insertCar({
          'plate_number': plateNumber,
          'entry_time': now.toIso8601String(),
          'image_path': imageFile.path,
          'status': 'inside',
        });

        NotificationService.showEntryNotification(plateNumber);
      }
    } catch (e) {
      print('Error processing plate entry: $e');
      throw Exception('Failed to process plate entry: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    bool isCameraAvailable = PCCameraService.isInitialized;

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
                Icon(
                  isCameraAvailable ? Icons.videocam : Icons.videocam_off,
                  color: isCameraAvailable ? Colors.green : Colors.red,
                  size: 24,
                ),
                SizedBox(width: 8),
                Icon(Icons.account_circle, size: 40),
                SizedBox(width: 16),
                // Manual entry button for testing
                ElevatedButton.icon(
                  onPressed: _showOpenALPRDetection,
                  icon: Icon(Icons.camera_alt, color: Colors.white),
                  label: Text('Camera Entry', style: TextStyle(color: Colors.white)),
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
}