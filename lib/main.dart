import 'package:flutter/material.dart';
import 'pages/role_selection_page.dart'; // Import the role selection page
import 'pages/parent_login_page.dart'; // Import parent login page
import 'pages/driver_login_page.dart'; // Import driver login page
import 'pages/parent_registration_page.dart'; // Import parent registration page
import 'pages/driver_registration_page.dart'; // Import driver registration page

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Transport App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/role_selection', // Set the initial route to role selection
      routes: {
        '/role_selection': (context) => RoleSelectionPage(), // Role selection page
        '/parent_login': (context) => ParentLoginPage(), // Parent login page
        '/driver_login': (context) => DriverLoginPage(), // Driver login page
        '/parent_register': (context) => ParentRegistrationPage(), // Parent registration page
        '/driver_register': (context) => DriverRegistrationPage(), // Driver registration page
      },
    );
  }
}
