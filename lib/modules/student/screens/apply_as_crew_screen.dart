import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../events/models/event_model.dart';
import '../../events/services/event_service.dart';

class ApplyAsCrewScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String eventOrganizerId;

  const ApplyAsCrewScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.eventOrganizerId,
  });

  @override
  State<ApplyAsCrewScreen> createState() => _ApplyAsCrewScreenState();
}

class _ApplyAsCrewScreenState extends State<ApplyAsCrewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _skillsController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isLoading = false;
  EventModel? _event;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final event = await EventService().getEventById(widget.eventId);
      if (!mounted) return;
      setState(() {
        _event = event;
        _isLoading = false;
      });
      _checkConstraints(event);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Error loading event details.';
        _isLoading = false;
      });
    }
  }

  void _checkConstraints(EventModel event) {
    if (event.crewDeadline != null && DateTime.now().isAfter(event.crewDeadline!)) {
      setState(() => _errorMsg = 'Application deadline has passed.');
    } else if (event.crewSlots > 0 && event.acceptedCrewCount >= event.crewSlots) {
      setState(() => _errorMsg = 'No crew slots available.');
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _skillsController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_errorMsg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMsg)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check for duplicate application
      final existing = await FirebaseFirestore.instance
          .collection('crewApplications')
          .where('eventId', isEqualTo: widget.eventId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (existing.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have already applied for this event.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Fetch user name robustly
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final Map<String, dynamic> userData = (userDoc.data() as Map<String, dynamic>?) ?? {};
      final userName = userData['fullname'] ?? userData['fullName'] ?? userData['name'] ?? user.email ?? 'Student';

      // Ensure we use the most accurate organizer ID
      final String targetOrganizerId = _event?.organizerId ?? widget.eventOrganizerId;

      if (targetOrganizerId.isEmpty) {
        throw Exception('Could not identify event organizer.');
      }

      final batch = FirebaseFirestore.instance.batch();

      // 1. Create Crew Application Record
      final appRef = FirebaseFirestore.instance.collection('crewApplications').doc();
      batch.set(appRef, {
        'eventId': widget.eventId,
        'eventTitle': widget.eventTitle,
        'organizerId': targetOrganizerId,
        'userId': user.uid,
        'userName': userName,
        'reason': _reasonController.text.trim(),
        'skills': _skillsController.text.trim(),
        'contactNo': _contactController.text.trim(),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Notify Organizer
      final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': targetOrganizerId,
        'title': 'New Crew Application',
        'message': '$userName has applied as crew for "${widget.eventTitle}".',
        'type': 'new_crew_application',
        'eventId': widget.eventId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 3. Notify Student (Confirmation)
      final studentNotifRef = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(studentNotifRef, {
        'userId': user.uid,
        'title': 'Application Submitted',
        'message': 'Your crew application for "${widget.eventTitle}" has been received.',
        'type': 'crew_application_submitted',
        'eventId': widget.eventId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF110D27),
      appBar: AppBar(
        title: const Text('Apply as Crew'),
        backgroundColor: const Color(0xFF241B3D),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF110D27), Color(0xFF1E1533), Color(0xFF2A2147)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading && _event == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event: ${widget.eventTitle}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_event != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Available Slots: ${_event!.crewSlots - _event!.acceptedCrewCount} / ${_event!.crewSlots}',
                          style: GoogleFonts.quicksand(color: Colors.white70),
                        ),
                        if (_event!.crewDeadline != null)
                          Text(
                            'Deadline: ${_event!.crewDeadline!.day}/${_event!.crewDeadline!.month}/${_event!.crewDeadline!.year}',
                            style: GoogleFonts.quicksand(color: Colors.white70),
                          ),
                      ],
                      if (_errorMsg.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent),
                          ),
                          child: Text(
                            _errorMsg,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _reasonController,
                        label: 'Reason for applying',
                        hint: 'Why do you want to join?',
                        maxLines: 3,
                        enabled: _errorMsg.isEmpty,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _skillsController,
                        label: 'Skills or Experience',
                        hint: 'e.g. Photography, Event Management...',
                        maxLines: 3,
                        enabled: _errorMsg.isEmpty,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _contactController,
                        label: 'Contact Number',
                        hint: 'e.g. 012-3456789',
                        keyboardType: TextInputType.phone,
                        enabled: _errorMsg.isEmpty,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading || _errorMsg.isNotEmpty ? null : _submitApplication,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9B6DFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Submit Application'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.quicksand(
            color: enabled ? Colors.white70 : Colors.white24,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          enabled: enabled,
          style: TextStyle(color: enabled ? Colors.white : Colors.white24),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF241B3D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFBFA8FF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF9B6DFF), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
          ),
          validator: (value) {
            if (enabled && (value == null || value.trim().isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}
