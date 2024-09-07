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

  @override
  void initState() {
    super.initState();

    // If we're editing a student, pre-fill the fields
    if (widget.student != null) {
      _nameController.text = widget.student!.name;
      _idNumberController.text = widget.student!.idNumber;
      _schoolNameController.text = widget.student!.schoolName;
    }
  }

  Future<void> _saveStudent() async {
    // Basic validation to ensure no empty fields
    if (_nameController.text.trim().isEmpty || _idNumberController.text.trim().isEmpty || _schoolNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Create a student object from the form fields
    final studentData = Student(
      id: widget.student?.id ?? 0,  // If student is being added, id is 0 (new student)
      name: _nameController.text.trim(),
      idNumber: _idNumberController.text.trim(),
      schoolName: _schoolNameController.text.trim(),
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    // Determine the correct API based on whether the student is new or being edited
    final String url;
    if (widget.student != null && widget.student!.id != 0) {
      // If the student exists (id is not 0), use the edit-student API
      url = 'http://10.0.2.2:8000/api/parent/edit-student/${studentData.id}/';
    } else {
      // If the student is new, use the add-student API
      url = 'http://10.0.2.2:8000/api/parent/add-student/';
    }

    print('Saving student: ${jsonEncode(studentData.toJson())}');
    print('URL: $url');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Token $token',  // Ensure correct authorization
        'Content-Type': 'application/json',
      },
      body: jsonEncode(studentData.toJson()),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Call the onSave callback to update the UI
      widget.onSave(studentData);

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
    } else {
      // Show error message if saving fails
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
      appBar: AppBar(title: Text(widget.student == null ? 'Add Student' : 'Edit Student')),
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
