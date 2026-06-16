import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../../../core/localization/app_translations.dart';

class EditEventScreen extends StatefulWidget {
  final EventModel event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _selectedDate;
  bool _isLoading = false;
  PlatformFile? _selectedImageFile;
  String? _currentImageUrl;

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        setState(() {
          _selectedImageFile = result.files.first;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(
      text: widget.event.description,
    );
    _locationController = TextEditingController(text: widget.event.location);
    _selectedDate = widget.event.date;
    _currentImageUrl = widget.event.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _submitEdit(String lang) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _currentImageUrl;
      if (_selectedImageFile != null && _selectedImageFile!.path != null) {
        final file = File(_selectedImageFile!.path!);
        final fileName =
            'event_posters/${DateTime.now().millisecondsSinceEpoch}_${_selectedImageFile!.name}';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(file);
        imageUrl = await ref.getDownloadURL();
      }

      final updatedEvent = EventModel(
        id: widget.event.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        location: _locationController.text.trim(),
        organizerId: widget.event.organizerId,
        organizerName: widget.event.organizerName,
        crewSlots: widget.event.crewSlots,
        crewDeadline: widget.event.crewDeadline,
        acceptedCrewCount: widget.event.acceptedCrewCount,
        imageUrl: imageUrl,
        registrationFields: widget.event.registrationFields,
        fee: widget.event.fee,
        capacity: widget.event.capacity,
        registeredCount: widget.event.registeredCount,
        startTime: widget.event.startTime,
        endTime: widget.event.endTime,
        registrationDeadline: widget.event.registrationDeadline,
        category: widget.event.category,
        whatToExpect: widget.event.whatToExpect,
      );

      await _eventService.updateEvent(updatedEvent);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.get(lang, 'event_updated_success')),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0820),
        body: Center(
          child: Text('Not logged in', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        final lang = userSnapshot.data?.data()?['language'] ?? 'en';

        return Scaffold(
          appBar: AppBar(
            title: Text(AppTranslations.get(lang, 'edit_event')),
            backgroundColor: const Color(0xFF241b3d),
            elevation: 0,
          ),
          body: Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF110d27),
                  Color(0xFF1e1533),
                  Color(0xFF2a2147),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF241b3d),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _titleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: AppTranslations.get(
                                  lang,
                                  'event_title',
                                ),
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white70),
                                ),
                              ),
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter a title'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: AppTranslations.get(
                                  lang,
                                  'description',
                                ),
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white70),
                                ),
                              ),
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter a description'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _locationController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: AppTranslations.get(
                                  lang,
                                  'location',
                                ),
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white70),
                                ),
                              ),
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter a location'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.grey.shade600),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              title: Text(
                                '${_selectedDate.toLocal()}'.split(' ')[0],
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: const Icon(
                                Icons.calendar_today,
                                color: Colors.white70,
                              ),
                              onTap: _pickDate,
                            ),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF261A3D),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child:
                                    _selectedImageFile != null &&
                                        _selectedImageFile!.path != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(_selectedImageFile!.path!),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      )
                                    : _currentImageUrl != null &&
                                          _currentImageUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _currentImageUrl!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.add_photo_alternate_outlined,
                                            color: Color(0xFFB99CFF),
                                            size: 40,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            AppTranslations.get(
                                              lang,
                                              'upload_event_poster',
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: () => _submitEdit(lang),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: const Color(0xFF8257E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                AppTranslations.get(lang, 'save_changes'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
