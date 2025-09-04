import 'package:flutter/material.dart';
import 'package:visitor_tracking_app/services/mysql_database.dart';
import 'package:visitor_tracking_app/services/notification_service.dart';
import 'package:visitor_tracking_app/services/openalpr_service.dart';

class ManualEntryDialog extends StatefulWidget {
  const ManualEntryDialog({Key? key}) : super(key: key);

  @override
  State<ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<ManualEntryDialog> {
  final TextEditingController _plateController = TextEditingController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit, color: Colors.orange),
          SizedBox(width: 8),
          Text('Manual Vehicle Entry'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter the license plate number manually:'),
          SizedBox(height: 16),
          TextField(
            controller: _plateController,
            decoration: InputDecoration(
              labelText: 'License Plate',
              hintText: 'e.g., 1234 تونس 567',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.directions_car),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          SizedBox(height: 12),
          Text(
            'Supported formats:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text('• 1234 تونس 567 (Arabic)', style: TextStyle(fontSize: 12)),
          Text('• 1234 TUNIS 567 (Latin)', style: TextStyle(fontSize: 12)),
          Text('• تونس 1234 (Old format)', style: TextStyle(fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processEntry,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text('Process Entry'),
        ),
      ],
    );
  }

  Future<void> _processEntry() async {
    if (_plateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a license plate number')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      String plateNumber = _plateController.text.trim();

      // Validate Tunisian plate format
      if (!OpenALPRService.isValidTunisianPlate(plateNumber)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid Tunisian license plate format')),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

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
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle $plateNumber exited successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Process entry
        DateTime now = DateTime.now();
        await MySQLDatabaseHelper.insertCar({
          'plate_number': plateNumber,
          'entry_time': now.toIso8601String(),
          'status': 'inside',
          'detection_method': 'manual',
          'confidence_score': 100.0,
        });

        NotificationService.showEntryNotification(plateNumber);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle $plateNumber entered successfully'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Manual entry error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing entry: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }
}