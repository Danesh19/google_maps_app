import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart'; // Import the geocoding package

class BookingPage extends StatefulWidget {
  final LatLng pickupPosition;
  final LatLng dropOffPosition;

  const BookingPage({
    Key? key,
    required this.pickupPosition,
    required this.dropOffPosition,
  }) : super(key: key);

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  TextEditingController pickupDateController = TextEditingController();
  TextEditingController pickupTimeController = TextEditingController();
  String? selectedStudentId;
  List<Student> students = [];

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      debugPrint('No access token found');
      return;
    }

    final url = Uri.parse('http://10.0.2.2:8000/api/my_students/');
    final response = await http.get(url, headers: {
      'Authorization': 'Token $accessToken',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      debugPrint('Fetched students: ${data.toString()}');
      setState(() {
        students = data.map((student) => Student.fromJson(student)).toList();
      });
    } else {
      debugPrint('Failed to fetch students. Status code: ${response.statusCode}');
    }
  }

  Future<String> getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      return "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
    } catch (e) {
      debugPrint('Error fetching address: $e');
      return "Unknown location";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedStudentId,
              hint: const Text('Select Student'),
              onChanged: (String? newValue) {
                setState(() {
                  selectedStudentId = newValue;
                });
              },
              items: students.map((Student student) {
                return DropdownMenuItem<String>(
                  value: student.id,
                  child: Text(student.name),
                );
              }).toList(),
            ),
            TextField(
              controller: pickupDateController,
              decoration: const InputDecoration(
                labelText: 'Pickup Date',
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  setState(() {
                    pickupDateController.text = pickedDate.toString().split(' ')[0];
                  });
                }
              },
            ),
            TextField(
              controller: pickupTimeController,
              decoration: const InputDecoration(
                labelText: 'Pickup Time',
              ),
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  // Format time to ensure it's in HH:MM:SS (24-hour format)
                  final hour = pickedTime.hour.toString().padLeft(2, '0');
                  final minute = pickedTime.minute.toString().padLeft(2, '0');
                  setState(() {
                    final formattedTime = pickedTime.format(context);
                    pickupTimeController.text = "$hour:$minute:00"; // Always add ":00" for seconds
                  });
                  print('Selected pickup time: ${pickupTimeController.text}');
                }
              },
            ),
            const SizedBox(height: 20),
            Text('Pickup Location: ${widget.pickupPosition.latitude}, ${widget.pickupPosition.longitude}'),
            Text('Drop-off Location: ${widget.dropOffPosition.latitude}, ${widget.dropOffPosition.longitude}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await confirmBooking();
              },
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirmBooking() async {
    if (selectedStudentId != null &&
        pickupDateController.text.isNotEmpty &&
        pickupTimeController.text.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        debugPrint('No access token found');
        return;
      }

      final pickUpAddress = await getAddressFromLatLng(widget.pickupPosition);
      final dropOffAddress = await getAddressFromLatLng(widget.dropOffPosition);

      final url = Uri.parse('http://10.0.2.2:8000/api/bookings/');

      final requestBody = {
        'student_id': selectedStudentId,
        'pickup_date': pickupDateController.text,
        'pick_up_time': pickupTimeController.text,  // Use formatted t  ime from the controller
        'pick_up_lat': widget.pickupPosition.latitude,
        'pick_up_lng': widget.pickupPosition.longitude,
        'dropoff_lat': widget.dropOffPosition.latitude,
        'dropoff_lng': widget.dropOffPosition.longitude,
        'pick_up_location_name': pickUpAddress,  // Use actual address
        'drop_off_location_name': dropOffAddress,  // Use actual address
      };

      print('Sending JSON request: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        debugPrint('Booking confirmed successfully!');
        Navigator.pop(context);
      } else {
        debugPrint('Failed to confirm booking. Status code: ${response.statusCode}');
      }
    } else {
      debugPrint('Please fill in all the required fields');
    }
  }
}

class Student {
  final String id;
  final String name;

  Student({required this.id, required this.name});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'].toString(),  // Ensure that id is correctly parsed
      name: json['name'] ?? 'Unknown',
    );
  }
}
// sdasd