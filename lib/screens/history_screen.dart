import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/visitor_service.dart';
import '../models/visitor.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTimeRange? _dateRange;
  List<Visitor> _filteredVisitors = [];

  @override
  void initState() {
    super.initState();
    _filteredVisitors = context.read<VisitorService>().visitors;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visit History'),
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Consumer<VisitorService>(
        builder: (context, visitorService, child) {
          if (visitorService.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          final visitors = _dateRange == null
              ? visitorService.visitors
              : visitorService.visitors.where((visitor) {
            return visitor.entryTime.isAfter(_dateRange!.start) &&
                visitor.entryTime.isBefore(_dateRange!.end);
          }).toList();

          if (visitors.isEmpty) {
            return Center(
              child: Text(
                'No visit records found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: visitors.length,
            itemBuilder: (context, index) {
              final visitor = visitors[index];
              return _buildVisitorCard(visitor);
            },
          );
        },
      ),
    );
  }

  Widget _buildVisitorCard(Visitor visitor) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF2196F3),
          child: Icon(Icons.directions_car, color: Colors.white),
        ),
        title: Text(
          visitor.plateNumber,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entry: ${_formatDateTime(visitor.entryTime)}'),
            if (visitor.exitTime != null)
              Text('Exit: ${_formatDateTime(visitor.exitTime!)}'),
            Text('Duration: ${visitor.duration}'),
          ],
        ),
        trailing: visitor.exitTime == null
            ? Chip(
          label: Text('INSIDE', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        )
            : null,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      initialDateRange: _dateRange ?? DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }
}