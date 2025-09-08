import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/visitor_service.dart';
import '../models/visitor.dart';

class TodayCarsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Today's Vehicles"),
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Consumer<VisitorService>(
        builder: (context, visitorService, child) {
          if (visitorService.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          final todayVisitors = visitorService.getTodayVisitors();

          if (todayVisitors.isEmpty) {
            return Center(
              child: Text(
                'No vehicles today',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: todayVisitors.length,
            itemBuilder: (context, index) {
              final visitor = todayVisitors[index];
              return _buildVisitorCard(context, visitor, visitorService);
            },
          );
        },
      ),
    );
  }

  Widget _buildVisitorCard(BuildContext context, Visitor visitor, VisitorService visitorService) {
    final bool isInside = visitor.exitTime == null;
    final duration = isInside
        ? DateTime.now().difference(visitor.entryTime)
        : visitor.exitTime!.difference(visitor.entryTime);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isInside ? Colors.green : Colors.grey,
          child: Icon(Icons.directions_car, color: Colors.white),
        ),
        title: Text(
          visitor.plateNumber,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entry: ${_formatTime(visitor.entryTime)}'),
            if (!isInside) Text('Exit: ${_formatTime(visitor.exitTime!)}'),
            Text('Duration: ${_formatDuration(duration)}'),
            if (isInside && duration.inHours > 8)
              Text(
                'OVERSTAY ALERT!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: isInside
            ? ElevatedButton(
          onPressed: () => _recordExit(context, visitor.plateNumber, visitorService),
          child: Text('Exit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        )
            : null,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Future<void> _recordExit(BuildContext context, String plateNumber, VisitorService visitorService) async {
    try {
      await visitorService.recordExit(plateNumber);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exit recorded for $plateNumber'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}