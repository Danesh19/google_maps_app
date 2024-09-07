import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../student_form.dart'; // Go up one level, then find student_form.dart
import '../student_model.dart';  // The student model
import 'google_map_page.dart'; // For booking page

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Student> students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    final url = 'http://10.0.2.2:8000/api/my_students/'; // Replace with your API URL
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        students = data.map((student) => Student.fromJson(student)).toList();
      });
    } else {
      // Handle error
      print('Error fetching students');
    }
  }

  Future<void> _deleteStudent(int studentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    final url = 'http://10.0.2.2:8000/api/parent/delete-student/$studentId/';
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        students.removeWhere((student) => student.id == studentId);
      });
    } else {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GoogleMapPage()),
              );
            },
          ),
        ],
      ),
      body: students.isEmpty
          ? const Center(child: Text('No students found'))
          : ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return ListTile(
            title: Text(student.name),
            subtitle: Text('ID: ${student.idNumber}, School: ${student.schoolName}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentForm(
                          student: student,
                          onSave: (updatedStudent) {
                            setState(() {
                              students[index] = updatedStudent;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteStudent(student.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentForm(
                onSave: (newStudent) {
                  setState(() {
                    students.add(newStudent);
                  });
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
