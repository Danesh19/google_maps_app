import 'package:flutter/material.dart';
import 'booking_model.dart';

class BookingForm extends StatefulWidget {
  final Booking? booking;
  final Function(Booking) onSave;

  const BookingForm({Key? key, this.booking, required this.onSave}) : super(key: key);

  @override
  _BookingFormState createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pickUpLocationController;
  late TextEditingController _dropOffLocationController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _pickUpLocationController = TextEditingController(text: widget.booking?.pickUpLocationName ?? '');
    _dropOffLocationController = TextEditingController(text: widget.booking?.dropOffLocationName ?? '');
    _selectedDate = widget.booking?.pickupDate ?? DateTime.now();
    _selectedTime = widget.booking?.pickUpTime ?? TimeOfDay.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.booking == null ? 'New Booking' : 'Edit Booking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _pickUpLocationController,
                decoration: const InputDecoration(labelText: 'Pick Up Location'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a pick-up location';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dropOffLocationController,
                decoration: const InputDecoration(labelText: 'Drop Off Location'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a drop-off location';
                  }
                  return null;
                },
              ),
              ListTile(
                title: Text("Pick Up Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                title: Text("Pick Up Time: ${_selectedTime!.format(context)}"),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final updatedBooking = Booking(
                      id: widget.booking?.id,
                      studentName: widget.booking?.studentName ?? '',
                      pickUpLocationName: _pickUpLocationController.text,
                      dropOffLocationName: _dropOffLocationController.text,
                      pickupDate: _selectedDate!,
                      pickUpTime: _selectedTime!,
                    );

                    widget.onSave(updatedBooking);  // Trigger save with updated data
                    Navigator.pop(context);  // Close the form after saving
                  }
                },
                child: const Text('Save Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }
}
