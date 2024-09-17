import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../booking_form.dart';
import '../booking_model.dart';

class BookingDashboardPage extends StatefulWidget {
  const BookingDashboardPage({Key? key}) : super(key: key);

  @override
  _BookingDashboardPageState createState() => _BookingDashboardPageState();
}

class _BookingDashboardPageState extends State<BookingDashboardPage> {
  List<Booking> bookings = [];
  bool _isLoading = true;
  Set<int> _deletingBookings = {};  // Track which bookings are being deleted
  String? _token;

  @override
  void initState() {
    super.initState();
    _fetchTokenAndBookings();
  }

  Future<void> _fetchTokenAndBookings() async {
    await _getToken();
    if (_token != null) {
      _fetchBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No access token found. Please log in again.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('access_token');
    });
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
    });

    final url = 'http://10.0.2.2:8000/api/bookings/parent-bookings/';
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
        bookings = data.map((booking) => Booking.fromJson(booking)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching bookings.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteBooking(int bookingId, int index) async {
    setState(() {
      _deletingBookings.add(bookingId);  // Show loading indicator for the booking being deleted
    });

    final url = 'http://10.0.2.2:8000/api/bookings/$bookingId/delete-booking/';
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        bookings.removeAt(index);  // Remove the booking from the list in the UI
        _deletingBookings.remove(bookingId);  // Remove from the deleting list
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking deleted successfully.')),
      );
    } else {
      setState(() {
        _deletingBookings.remove(bookingId);  // Remove the loading state for the booking
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete booking.')),
      );
    }
  }

  Future<void> _updateBookingInBackend(Booking updatedBooking, int index) async {
    final url = 'http://10.0.2.2:8000/api/bookings/${updatedBooking.id}/edit-booking/';
    final body = json.encode(updatedBooking.toJson());

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
      body: body,  // Send the updated booking data
    );

    if (response.statusCode == 200) {
      setState(() {
        bookings[index] = updatedBooking;  // Update the booking in the list
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking updated successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update booking.')),
      );
    }
  }

  Future<void> _navigateToBookingForm(Booking booking, int index) async {
    final updatedBooking = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingForm(
          booking: booking,
          onSave: (updatedBooking) {
            Navigator.pop(context, updatedBooking);  // Return the updated booking from the form
          },
        ),
      ),
    );

    if (updatedBooking != null) {
      await _updateBookingInBackend(updatedBooking, index);  // Update the backend with the edited booking
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking update was cancelled or failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookings.isEmpty
          ? const Center(child: Text('No bookings found'))
          : ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          final isDeleting = _deletingBookings.contains(booking.id);

          return ListTile(
            title: Text('Booking for: ${booking.studentName}'),
            subtitle: Text(
                'Pickup: ${booking.pickUpLocationName} - Dropoff: ${booking.dropOffLocationName}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _navigateToBookingForm(booking, index);
                  },
                ),
                isDeleting
                    ? const CircularProgressIndicator()  // Show loading indicator while deleting
                    : IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    if (booking.id != null) {
                      _deleteBooking(booking.id!, index);  // Call delete method with booking ID and index
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error: Cannot delete a booking without an ID.')),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
