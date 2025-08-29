import 'package:flutter/material.dart';

Widget dashboardCard(String title, String value, {
  required double width,
  required double height,
  String button = "",
  String routeName = "",
  BuildContext? context,
}) {
  return SizedBox(
    width: width,
    height: height,
    child: Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Roboto-Medium'
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            Text(
              value,
              style: const TextStyle(
                  fontSize: 22,
                  fontFamily: 'Roboto-Bold'
              ),
            ),
            const SizedBox(height: 15),
            if (button.isNotEmpty && context != null && routeName.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, routeName);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text(button,
                  style: TextStyle(
                      fontFamily: 'Inter_24pt-Regular',
                      color: Colors.white
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}