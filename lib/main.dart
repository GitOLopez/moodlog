import 'package:flutter/material.dart';
import 'login_page.dart';

void main() => runApp(const MoodLog());

class MoodLog extends StatelessWidget {
  const MoodLog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodLog',
      home: LoginPage(),
    );
  }
}