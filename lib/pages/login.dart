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
      final user = await MySQLDatabaseHelper.getUser(mail.text.trim());

      if (user != null && user['password'] == pass.text) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Login Failed'),
            content: const Text('Invalid email or password'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      print('Login error: $e');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Connection Error'),
          content: const Text('Could not connect to server. Please check your connection.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
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