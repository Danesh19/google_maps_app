import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../student_form.dart';
import '../student_model.dart';
import 'google_map_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Student> students = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _fetchTokenAndStudents();  // Fetch token and students on page load
  }

  Future<void> _fetchTokenAndStudents() async {
    await _getToken();
    if (_token != null) {
      _fetchStudents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No access token found. Please log in again.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper function to get the token
  Future<void> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('access_token');
    });
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;  // Show loading indicator
    });

    final url = 'http://10.0.2.2:8000/api/my_students/';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        students = data.map((student) => Student.fromJson(student)).toList();  // Populate students list
      });
    } else if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
      // Optionally, log out the user or redirect to the login page
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching students.')),
      );
    }

    setState(() {
      _isLoading = false;  // Hide loading indicator
    });
  }

  Future<void> _deleteStudent(int studentId) async {
    // Optimistically update the UI before sending the request
    setState(() {
      students.removeWhere((student) => student.id == studentId);
    });

    final url = 'http://10.0.2.2:8000/api/parent/delete-student/$studentId/';
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student deleted successfully.')),
      );
    } else if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
    } else {
      // Rollback the UI update if deletion fails
      _fetchStudents();  // Re-fetch the students to restore the original list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting student.')),
      );
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())  // Show loading indicator
          : students.isEmpty
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
                          student: student,  // Pass student for editing
                          onSave: (updatedStudent) {
                            setState(() {
                              students[index] = updatedStudent;  // Update the student in the list
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    if (student.id != null) {
                      _deleteStudent(student.id!);  // Ensure student ID is not null
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error: Cannot delete a student without an ID.')),
                      );
                    }
                  },
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
                student: null,  // Pass null for adding a new student
                onSave: (newStudent) {
                  setState(() {
                    students.add(newStudent);  // Add the new student to the list
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
