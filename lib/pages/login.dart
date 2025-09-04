import 'package:flutter/material.dart';
import 'package:visitor_tracking_app/services/mysql_database.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController mail = TextEditingController();
  final TextEditingController pass = TextEditingController();
  bool obscure = false;

  void _login() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      final user = await MySQLDatabaseHelper.getUser(mail.text.trim());

      // Close loading dialog
      Navigator.pop(context);

      if (user != null && user['password'] == pass.text) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Login Failed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invalid email or password'),
                SizedBox(height: 12),
                Text('Default credentials:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Email: admin@draexlmaier.com'),
                Text('Password: admin123'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('OK'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Login error: $e');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Connection Error'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Could not connect to database.'),
              SizedBox(height: 12),
              Text('Please ensure:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• XAMPP/WAMP is running'),
              Text('• MySQL service is started'),
              Text('• phpMyAdmin is accessible'),
              SizedBox(height: 12),
              Text('The app will work in demo mode.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Continue'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xffd9d9d9),
          title: Text(
              'Visitor Tracking',
              style: TextStyle(
                fontSize: 40,
                fontFamily: 'Montserrat-Bold',
                color: Colors.black,
              )
          ),
          centerTitle: true,
        ),
      ),

      body: Padding(
        padding: EdgeInsets.fromLTRB(350, 150, 350, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Email",
              style: TextStyle(
                fontFamily:'Inter' ,
                fontSize:20 ,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: mail,
              decoration: InputDecoration(
                hintText: "exemple@draexlmaier.com",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Password",
              style: TextStyle(
                fontFamily:'Inter' ,
                fontSize:20 ,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pass,
              obscureText: !obscure,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: obscure,
                  onChanged: (value) {
                    setState(() {
                      obscure = value!;
                    });
                  },
                ),
                const Text('show password',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16
                  ),
                )
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff0000ff),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10)
                ),
                child: Text('log in',
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                      color: Colors.white
                  ),
                ),
                onPressed: _login,
              ),
            )
          ],
        ),
      ),
    );
  }
}