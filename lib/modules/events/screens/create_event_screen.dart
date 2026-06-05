import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _slotsController = TextEditingController(text: '10');
  
  DateTime? _selectedDate;
  DateTime? _crewDeadline;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        // Default crew deadline to 3 days before the event
        _crewDeadline = pickedDate.subtract(const Duration(days: 3));
      });
    }
  }

  Future<void> _pickDeadline() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select event date first')),
      );
      return;
    }
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _crewDeadline ?? _selectedDate!.subtract(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: _selectedDate!,
    );
    if (pickedDate != null) {
      setState(() {
        _crewDeadline = pickedDate;
      });
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newEvent = EventModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate!,
        location: _locationController.text.trim(),
        organizerId: '', // Set in service
        crewSlots: int.tryParse(_slotsController.text) ?? 0,
        crewDeadline: _crewDeadline,
      );

      await _eventService.createEvent(newEvent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: const Color(0xFF261A3D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(_titleController, 'Event Title', Icons.title),
                    const SizedBox(height: 16),
                    _buildTextField(_descriptionController, 'Description', Icons.description, maxLines: 3),
                    const SizedBox(height: 16),
                    _buildTextField(_locationController, 'Location', Icons.location_on),
                    const SizedBox(height: 16),
                    _buildTextField(_slotsController, 'Crew Slots', Icons.group, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    
                    _buildPickerTile(
                      label: _selectedDate == null ? 'Select Event Date' : 'Event Date: ${_selectedDate!.toLocal()}'.split(' ')[0],
                      icon: Icons.calendar_today,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),
                    _buildPickerTile(
                      label: _crewDeadline == null ? 'Select Crew Deadline' : 'Crew Deadline: ${_crewDeadline!.toLocal()}'.split(' ')[0],
                      icon: Icons.timer,
                      onTap: _pickDeadline,
                    ),
                    
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submitEvent,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF9B6DFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create Event',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFFB99CFF)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9B6DFF), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF261A3D),
      ),
      validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
    );
  }

  Widget _buildPickerTile({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF261A3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFB99CFF)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
