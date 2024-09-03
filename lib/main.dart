import 'package:flutter/material.dart';
import 'pages/google_map_page.dart';
import 'pages/login_page.dart'; // Import your login page
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Google Maps App',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: const LoginPage(),
  );
}