import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class PostEventReportScreen extends StatefulWidget {
  final String proposalId;
  final Map<String, dynamic> proposalData;

  const PostEventReportScreen({
    super.key,
    required this.proposalId,
    required this.proposalData,
  });

  @override
  State<PostEventReportScreen> createState() => _PostEventReportScreenState();
}

class _PostEventReportScreenState extends State<PostEventReportScreen> {
  PlatformFile? programReportFile;
  PlatformFile? financialReportFile;
  bool isSubmitting = false;

  Future<void> pickProgramReport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        programReportFile = result.files.single;
      });
    }
  }

  Future<void> pickFinancialReport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        financialReportFile = result.files.single;
      });
    }
  }

  Future<void> submitReports() async {
    if (programReportFile == null || financialReportFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both program and financial reports'),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      String programUrl = '';
      String financialUrl = '';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (programReportFile!.path != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'reports/${timestamp}_${programReportFile!.name}',
        );
        final task = await ref.putFile(File(programReportFile!.path!));
        programUrl = await task.ref.getDownloadURL();
      }

      if (financialReportFile!.path != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'reports/${timestamp}_${financialReportFile!.name}',
        );
        final task = await ref.putFile(File(financialReportFile!.path!));
        financialUrl = await task.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('proposals')
          .doc(widget.proposalId)
          .update({
            'programReportName': programReportFile!.name,
            'financialReportName': financialReportFile!.name,

            'programReportUrl': programUrl,
            'financialReportUrl': financialUrl,

            'reportStatus': 'submitted',

            'submittedReportAt': FieldValue.serverTimestamp(),

            'reportExpiresAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 14)),
            ),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post-event reports submitted')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting reports: $e')));
    }

    if (mounted) {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final programName = widget.proposalData['programName'] ?? 'Event';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0820),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Post-Event Reports',
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
          child: Column(
            children: [
              const Icon(
                Icons.assignment_turned_in_outlined,
                color: Color(0xFFB99CFF),
                size: 60,
              ),

              const SizedBox(height: 14),

              Text(
                programName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Upload the required post-event documents after the program ends.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),

              const SizedBox(height: 25),

              _reportUploadCard(
                title: 'Program Report',
                subtitle: programReportFile?.name ?? 'No file selected',
                icon: Icons.description_outlined,
                onPressed: pickProgramReport,
              ),

              const SizedBox(height: 16),

              _reportUploadCard(
                title: 'Financial Report',
                subtitle: financialReportFile?.name ?? 'No file selected',
                icon: Icons.receipt_long_outlined,
                onPressed: pickFinancialReport,
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitReports,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B6DFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Reports',
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
    );
  }

  Widget _reportUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A285A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB99CFF).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFB99CFF), size: 38),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB99CFF),
              side: const BorderSide(color: Color(0xFFB99CFF)),
            ),
          ),
        ],
      ),
    );
  }
}
