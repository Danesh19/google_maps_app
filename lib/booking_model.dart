import 'package:flutter/material.dart';

class Booking {
  final int? id;
  final String studentName;
  final String pickUpLocationName;
  final String dropOffLocationName;
  final DateTime pickupDate;  // Use DateTime for date
  final TimeOfDay pickUpTime; // Use TimeOfDay for time

  Booking({
    this.id,
    required this.studentName,
    required this.pickUpLocationName,
    required this.dropOffLocationName,
    required this.pickupDate,
    required this.pickUpTime,
  });

  // Factory constructor to create a Booking object from JSON
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int?,
      studentName: json['student_name'] ?? 'Unknown Student',  // Fallback to 'Unknown Student' if null
      pickUpLocationName: json['pick_up_location_name'] ?? 'Unknown Pickup Location',  // Fallback to default if null
      dropOffLocationName: json['drop_off_location_name'] ?? 'Unknown Dropoff Location',  // Fallback to default if null
      pickupDate: DateTime.parse(json['pickup_date'] ?? DateTime.now().toIso8601String()),  // Ensure date parsing
      pickUpTime: _parseTimeOfDay(json['pick_up_time'] ?? '00:00:00'),  // Parse time with fallback to '00:00:00'
    );
  }

  // Convert a Booking object to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_name': studentName,
      'pick_up_location_name': pickUpLocationName,
      'drop_off_location_name': dropOffLocationName,
      'pickup_date': '${pickupDate.year}-${pickupDate.month.toString().padLeft(2, '0')}-${pickupDate.day.toString().padLeft(2, '0')}',  // Format as YYYY-MM-DD
      'pick_up_time': '${pickUpTime.hour.toString().padLeft(2, '0')}:${pickUpTime.minute.toString().padLeft(2, '0')}:00',  // Format as HH:MM:SS
    };
  }

  // Helper function to parse time string to TimeOfDay
  static TimeOfDay _parseTimeOfDay(String timeString) {
    final timeParts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
  }
}
