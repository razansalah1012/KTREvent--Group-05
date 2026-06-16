import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../../../core/localization/app_translations.dart';

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
  final TextEditingController _slotsController = TextEditingController(
    text: '10',
  );

  DateTime? _selectedDate;
  DateTime? _crewDeadline;
  bool _isLoading = false;
  PlatformFile? _selectedImageFile;
  PlatformFile? _paperworkFile;

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

  Future<void> _pickPaperwork() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null) {
        setState(() {
          _paperworkFile = result.files.first;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking paperwork: $e')));
    }
  }

  Future<void> _downloadTemplate(String assetPath, String fileName) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Template: $fileName');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download template: $e')),
      );
    }
  }

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
      initialDate:
          _crewDeadline ?? _selectedDate!.subtract(const Duration(days: 3)),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_selectedImageFile != null && _selectedImageFile!.path != null) {
        final file = File(_selectedImageFile!.path!);
        final fileName =
            'event_posters/${DateTime.now().millisecondsSinceEpoch}_${_selectedImageFile!.name}';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(file);
        imageUrl = await ref.getDownloadURL();
      }

      String? paperworkUrl;
      if (_paperworkFile != null && _paperworkFile!.path != null) {
        final file = File(_paperworkFile!.path!);
        final fileName =
            'event_paperwork/${DateTime.now().millisecondsSinceEpoch}_${_paperworkFile!.name}';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(file);
        paperworkUrl = await ref.getDownloadURL();
      }

      final newEvent = EventModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate!,
        location: _locationController.text.trim(),
        organizerId: '',
        crewSlots: int.tryParse(_slotsController.text) ?? 0,
        crewDeadline: _crewDeadline,
        imageUrl: imageUrl,
        paperworkUrl: paperworkUrl,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0820),
        body: Center(child: Text('Not signed in')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final lang = data['language'] ?? 'en';

        return Scaffold(
          backgroundColor: const Color(0xFF0D0820),
          appBar: AppBar(
            title: Text(AppTranslations.get(lang, 'create_event')),
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
                        _buildTextField(
                          _titleController,
                          AppTranslations.get(lang, 'event_title'),
                          Icons.title,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _descriptionController,
                          AppTranslations.get(lang, 'description'),
                          Icons.description,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _locationController,
                          AppTranslations.get(lang, 'location'),
                          Icons.location_on,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _slotsController,
                          AppTranslations.get(lang, 'crew_slots'),
                          Icons.group,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        _buildPickerTile(
                          label: _selectedDate == null
                              ? AppTranslations.get(lang, 'select_event_date')
                              : '${AppTranslations.get(lang, 'event_date')}: ${_selectedDate!.toLocal()}'
                                    .split(' ')[0],
                          icon: Icons.calendar_today,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 16),
                        _buildPickerTile(
                          label: _crewDeadline == null
                              ? AppTranslations.get(
                                  lang,
                                  'select_crew_deadline',
                                )
                              : '${AppTranslations.get(lang, 'crew_deadline')}: ${_crewDeadline!.toLocal()}'
                                    .split(' ')[0],
                          icon: Icons.timer,
                          onTap: _pickDeadline,
                        ),

                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF261A3D),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF9B6DFF).withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF9B6DFF),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppTranslations.get(
                                      lang,
                                      'official_template',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppTranslations.get(
                                  lang,
                                  'please_download_template',
                                ),
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () => _downloadTemplate(
                                  'assets/reports/TEMPLATE KERTAS KERJA JKP 2025_2026.docx.pdf',
                                  'TEMPLATE_KERTAS_KERJA.pdf',
                                ),
                                icon: const Icon(Icons.download, size: 18),
                                label: Text(
                                  AppTranslations.get(
                                    lang,
                                    'download_paperwork',
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF9B6DFF),
                                  alignment: Alignment.centerLeft,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _pickPaperwork,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF261A3D),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _paperworkFile != null
                                    ? Colors.green
                                    : Colors.white24,
                                width: _paperworkFile != null ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _paperworkFile != null
                                      ? Icons.check_circle
                                      : Icons.upload_file,
                                  color: _paperworkFile != null
                                      ? Colors.green
                                      : Colors.redAccent,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _paperworkFile?.name ??
                                        AppTranslations.get(
                                          lang,
                                          'upload_completed_paperwork',
                                        ),
                                    style: TextStyle(
                                      color: _paperworkFile != null
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: _paperworkFile != null
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                          onPressed: _submitEvent,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF9B6DFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppTranslations.get(lang, 'create_event'),
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
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
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

  Widget _buildPickerTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
