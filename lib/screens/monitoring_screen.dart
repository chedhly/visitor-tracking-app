import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/visitor_service.dart';
import '../services/settings_service.dart';
import '../models/visitor.dart';

class MonitoringScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final visitorService = Provider.of<VisitorService>(context);
    final settingsService = Provider.of<SettingsService>(context);
    final threshold = settingsService.overstayThresholdHours;
    
    final insideVehicles = visitorService.visitors
        .where((v) => v.isInside)
        .toList();
    
    final overstayVehicles = insideVehicles
        .where((v) => v.isOverstay(threshold))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Vehicle Monitoring')),
      body: Column(
        children: [
          if (overstayVehicles.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${overstayVehicles.length} vehicle(s) overstaying!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: insideVehicles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.car_rental, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No vehicles inside',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: insideVehicles.length,
                    itemBuilder: (context, index) {
                      final visitor = insideVehicles[index];
                      final isOverstay = visitor.isOverstay(threshold);
                      
                      return Card(
                        color: isOverstay
                            ? Colors.red.shade50
                            : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isOverstay ? Colors.red : Colors.green,
                            child: Icon(
                              isOverstay
                                  ? Icons.warning
                                  : Icons.directions_car,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            visitor.plateNumber,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Entry: ${_formatTime(visitor.entryTime)}\n'
                            'Duration: ${visitor.durationFormatted}',
                          ),
                          trailing: isOverstay
                              ? Chip(
                                  label: Text('OVERSTAY'),
                                  backgroundColor: Colors.red,
                                  labelStyle: TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}';
  }
}
