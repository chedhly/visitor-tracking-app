import 'package:flutter/material.dart';

Widget sidebarItem(IconData icon, String title, bool selected) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    color: selected ? Colors.grey[200] : Colors.transparent,
    child: Row(
      children: [
        Icon(icon, color: selected ? Colors.blue : Colors.black),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            color: selected ? Colors.blue : Colors.black,
            fontFamily: selected ? 'Roboto-Regular' : 'Roboto-Light',
          ),
        ),
      ],
    ),
  );
}