import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProposalScreen extends StatefulWidget {
  final String proposalId;
  final Map<String, dynamic> proposalData;

  const EditProposalScreen({
    super.key,
    required this.proposalId,
    required this.proposalData,
  });

  @override
  State<EditProposalScreen> createState() => _EditProposalScreenState();
}

class _EditProposalScreenState extends State<EditProposalScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController programNameController;
  late TextEditingController descriptionController;
  late TextEditingController objectivesController;
  late TextEditingController venueController;
  late TextEditingController budgetController;

  String organizerType = 'Club';
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();

    programNameController = TextEditingController(
      text: widget.proposalData['programName'] ?? '',
    );
    descriptionController = TextEditingController(
      text: widget.proposalData['description'] ?? '',
    );
    objectivesController = TextEditingController(
      text: widget.proposalData['objectives'] ?? '',
    );
    venueController = TextEditingController(
      text: widget.proposalData['venue'] ?? '',
    );
    budgetController = TextEditingController(
      text: widget.proposalData['budget'] ?? '',
    );

    organizerType = widget.proposalData['organizerType'] ?? 'Club';

    final dateValue = widget.proposalData['programDate'];
    if (dateValue is Timestamp) {
      selectedDate = dateValue.toDate();
    }
  }

  @override
  void dispose() {
    programNameController.dispose();
    descriptionController.dispose();
    objectivesController.dispose();
    venueController.dispose();
    budgetController.dispose();
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
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> updateProposal() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select program date')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('proposals')
          .doc(widget.proposalId)
          .update({
            'programName': programNameController.text.trim(),
            'description': descriptionController.text.trim(),
            'objectives': objectivesController.text.trim(),
            'venue': venueController.text.trim(),
            'budget': budgetController.text.trim(),
            'organizerType': organizerType,
            'programDate': Timestamp.fromDate(selectedDate!),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposal updated successfully')),
      );

      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating proposal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0820),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit Proposal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                  Icons.edit_document,
                  color: Color(0xFFB99CFF),
                  size: 60,
                ),

                const SizedBox(height: 14),

                const Text(
                  'Edit Event Proposal',
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
                  initialValue: organizerType,
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
                    setState(() {
                      organizerType = value!;
                    });
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

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: updateProposal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B6DFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
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
        borderSide: const BorderSide(color: Color(0xFFB99CFF), width: 2),
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
