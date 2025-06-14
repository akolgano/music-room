// lib/screens/profile/components/date_picker.dart
import 'package:flutter/material.dart';
import './utils.dart';

class DatePicker extends StatefulWidget {
  final String label;
  final Function(DateTime) onDateSelected;
  final String? initDate;

  const DatePicker({
    super.key,
    required this.label,
    required this.onDateSelected,
    required this.initDate,
  });

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime? _selectedDate;
  final TextEditingController _dobController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initDate != null){
        _dobController.text = widget.initDate!;
    }
  }

  Future<void> _selectDate() async {
    DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dobController.text = Utils.formatDate(pickedDate);
      });
      widget.onDateSelected(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _dobController,
      readOnly: true,
      onTap: _selectDate,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Please select a date' : null,
    );
  }
}
