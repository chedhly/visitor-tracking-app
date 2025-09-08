import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/visitor_service.dart';

class ManualEntryScreen extends StatefulWidget {
  @override
  _ManualEntryScreenState createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manual Entry'),
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              Text(
                'Enter License Plate Number',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _plateController,
                decoration: InputDecoration(
                  labelText: 'License Plate',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                  hintText: 'e.g., 123 TUN 456 or TN 123456',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a license plate number';
                  }
                  if (value.length < 4) {
                    return 'Plate number is too short';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Record Entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<VisitorService>().recordEntry(_plateController.text.trim().toUpperCase());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entry recorded successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}