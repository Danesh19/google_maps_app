import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'student_model.dart';

class StudentForm extends StatefulWidget {
  final Student? student; // If null, we're adding a new student; if not, we're editing
  final Function(Student) onSave; // Callback when the student is saved

  const StudentForm({Key? key, this.student, required this.onSave}) : super(key: key);

  @override
  _StudentFormState createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  bool _isLoading = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    // If we're editing a student, pre-fill the fields
    if (widget.student != null) {
      _nameController.text = widget.student!.name;
      _idNumberController.text = widget.student!.idNumber;
      _schoolNameController.text = widget.student!.schoolName;
    }
    _getToken();  // Get token once when form is initialized
  }

  Future<void> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('access_token');
    });
  }

  Future<void> _saveStudent() async {
    // Basic validation to ensure no empty fields
    if (_nameController.text.trim().isEmpty ||
        _idNumberController.text.trim().isEmpty ||
        _schoolNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Ensure the token is available
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No access token found. Please log in again.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Check if we're editing an existing student
    final studentId = widget.student?.id;

    final studentData = {
      'name': _nameController.text.trim(),
      'id_number': _idNumberController.text.trim(),
      'school_name': _schoolNameController.text.trim(),
    };

    // Determine the API URL for add or edit operation
    final String url = studentId != null
        ? 'http://10.0.2.2:8000/api/parent/student/edit/$studentId/'  // Editing an existing student
        : 'http://10.0.2.2:8000/api/parent/student/add/';  // Adding a new student

    print('Saving student: ${jsonEncode(studentData)}');
    print('URL: $url');

    // Use PUT for editing and POST for creating a new student
    final response = await (studentId != null
        ? http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(studentData),
    )
        : http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(studentData),
    ));

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Call the onSave callback to update the UI
      widget.onSave(Student.fromJson(jsonDecode(response.body)));

      // Show confirmation dialog after saving
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Student saved successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);  // Close the dialog
                Navigator.pop(context);  // Go back to the previous page
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (response.statusCode == 400) {
      // Handle error responses (like "Student with this ID number already exists.")
      Map<String, dynamic> errorResponse = jsonDecode(response.body);
      String errorMessage = errorResponse['message'] is String
          ? errorResponse['message']
          : 'Unknown error occurred';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $errorMessage')),
      );
    } else {
      // Handle other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving student: ${response.body}')),
      );
      print('Error saving student');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student == null ? 'Add Student' : 'Edit Student'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Student Name'),
            ),
            TextField(
              controller: _idNumberController,
              decoration: const InputDecoration(labelText: 'ID Number'),
            ),
            TextField(
              controller: _schoolNameController,
              decoration: const InputDecoration(labelText: 'School Name'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _saveStudent,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
