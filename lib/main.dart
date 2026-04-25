import 'package:flutter/material.dart';
import 'login_page.dart';

void main() => runApp(MoodLog());

class MoodLog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proyecto Final',
      home: LoginPage(), // Inicio en Login
    );
  }
}
