import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DriverDashboardPage extends StatefulWidget {
  @override
  _DriverDashboardPageState createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  bool _showAcceptedBookings = false; // Toggle between pending and accepted

  @override
  void initState() {
    super.initState();
    _fetchPendingBookings(); // Fetch pending bookings on load
  }

  // Fetch pending bookings
  Future<void> _fetchPendingBookings() async {
    setState(() {
      _isLoading = true;
      _showAcceptedBookings = false;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    const String apiUrl = 'http://10.0.2.2:8000/api/bookings/pending-bookings/';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',  // Attach the token
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _bookings = jsonDecode(response.body);  // Parse the JSON response
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch bookings.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch accepted bookings
  Future<void> _fetchAcceptedBookings() async {
    setState(() {
      _isLoading = true;
      _showAcceptedBookings = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    const String apiUrl = 'http://10.0.2.2:8000/api/bookings/driver-bookings/';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',  // Attach the token
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _bookings = jsonDecode(response.body);  // Parse the JSON response
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch accepted bookings.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Accept booking function
  Future<void> _acceptBooking(int bookingId) async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    final String acceptBookingUrl = 'http://10.0.2.2:8000/api/bookings/$bookingId/accept-booking/';
    try {
      final response = await http.post(
        Uri.parse(acceptBookingUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',  // Attach the token
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking accepted successfully')),
        );
        // Refresh the list of pending bookings after accepting one
        _fetchPendingBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept booking: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.pending_actions),
            onPressed: _fetchPendingBookings, // Fetch pending bookings
          ),
          IconButton(
            icon: Icon(Icons.check_circle),
            onPressed: _fetchAcceptedBookings, // Fetch accepted bookings
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
          ? const Center(child: Text('No bookings available.'))
          : ListView.builder(
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return Card(
            child: ListTile(
              title: Text('Pickup: ${booking['pick_up_location_name']}'),
              subtitle: Text(
                  'Drop-off: ${booking['drop_off_location_name']}\nStudent: ${booking['student_name']}'),
              trailing: _showAcceptedBookings
                  ? const Text('Accepted') // If showing accepted bookings
                  : ElevatedButton(
                onPressed: () => _acceptBooking(booking['id']),
                child: const Text('Accept'),
              ),
            ),
          );
        },
      ),
    );
  }
}
