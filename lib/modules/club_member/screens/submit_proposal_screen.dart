import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubmitProposalScreen extends StatefulWidget {
  const SubmitProposalScreen({super.key});

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedPdfName;

  final programNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final venueController = TextEditingController();
  final budgetController = TextEditingController();
  final objectivesController = TextEditingController();

  String organizerType = 'Club';
  DateTime? selectedDate;

  @override
  void dispose() {
    programNameController.dispose();
    descriptionController.dispose();
    venueController.dispose();
    budgetController.dispose();
    objectivesController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: selectedDate ?? DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() => selectedDate = pickedDate);
    }
  }

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        selectedPdfName = result.files.single.name;
      });
    }
  }

  Future<void> submitProposal() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select program date')),
      );
      return;
    }

    if (selectedPdfName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload proposal PDF')),
      );
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No logged in user found')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('proposals').add({
        'programName': programNameController.text.trim(),
        'description': descriptionController.text.trim(),
        'objectives': objectivesController.text.trim(),
        'venue': venueController.text.trim(),
        'budget': budgetController.text.trim(),
        'organizerType': organizerType,
        'programDate': Timestamp.fromDate(selectedDate!),
        'status': 'pending',
        'pdfName': selectedPdfName,
        'pdfUrl': '',
        'submittedBy': currentUser.uid,
        'submittedByEmail': currentUser.email,
        'submittedAt': FieldValue.serverTimestamp(),
        'adminComment': '',
        'reviewedBy': '',
        'reviewedAt': null,
        'reportStatus': 'not_submitted',
        'programReportName': '',
        'programReportUrl': '',
        'financialReportName': '',
        'financialReportUrl': '',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposal submitted successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting proposal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0820),
        elevation: 0,
        title: const Text(
          'Submit Proposal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF2B1D44),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFB99CFF), width: 2),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: Color(0xFFB99CFF),
                  size: 60,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Event Proposal Form',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                _buildTextField(
                  controller: programNameController,
                  label: 'Program Name',
                  icon: Icons.event,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: descriptionController,
                  label: 'Program Description',
                  icon: Icons.notes,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: objectivesController,
                  label: 'Objectives',
                  icon: Icons.flag_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: venueController,
                  label: 'Venue',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: budgetController,
                  label: 'Estimated Budget (RM)',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: organizerType,
                  dropdownColor: const Color(0xFF2B1D44),
                  decoration: _inputDecoration(
                    label: 'Organizer Type',
                    icon: Icons.groups_outlined,
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'Club', child: Text('Club')),
                    DropdownMenuItem(
                      value: 'Community',
                      child: Text('Community'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => organizerType = value!);
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: Color(0xFFB99CFF),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedDate == null
                              ? 'Select Program Date'
                              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: pickPdf,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Proposal PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB99CFF),
                        side: const BorderSide(color: Color(0xFFB99CFF)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (selectedPdfName != null)
                      Text(
                        selectedPdfName!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitProposal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B6DFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Submit Proposal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        return null;
      },
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: const Color(0xFFB99CFF)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.white38),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFB99CFF),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}