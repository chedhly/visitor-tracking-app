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
      title: const Text('Manual Vehicle Entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter the license plate number manually:'),
          const SizedBox(height: 16),
          TextField(
            controller: _plateController,
            decoration: const InputDecoration(
              labelText: 'License Plate',
              hintText: 'e.g., 1234 TUNIS 567',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processEntry,
          child: _isProcessing
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Enter'),
        ),
      ],
    );
  }

  Future<void> _processEntry() async {
    if (_plateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a license plate number')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      String plateNumber = _plateController.text.trim().toUpperCase();

      // Validate Tunisian plate format using OpenALPR validation
      if (!OpenALPRService.isValidTunisianPlate(plateNumber)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid Tunisian license plate format (e.g., 1234 TUNIS 567)')),
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
        Navigator.pop(context);
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle $plateNumber entered successfully')),
        );
      }
    } catch (e) {
      print('Manual entry error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error processing entry')),
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