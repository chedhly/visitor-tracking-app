import 'package:flutter/material.dart';

class Car {
  final int id;
  final String plateNum;
  final String entryTime;
  final String exitTime;
  String? date;
  final String duration;

  Car({
    required this.id,
    required this.plateNum,
    required this.entryTime,
    required this.exitTime,
    this.date,
    required this.duration,
  });
}

class TableHeader extends StatelessWidget {
  final String text;
  const TableHeader(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontFamily: 'Roboto-Bold',
            fontSize: 20
        ),
      ),
    );
  }
}

class TableCell extends StatelessWidget {
  final String text;
  final Color textColor;
  const TableCell(this.text, this.textColor, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: textColor,
            fontFamily: 'Roboto-Regular',
            fontSize: 16
        ),
      ),
    );
  }
}