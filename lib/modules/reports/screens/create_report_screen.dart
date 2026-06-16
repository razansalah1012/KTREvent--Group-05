import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../events/models/event_model.dart';
import '../models/report_model.dart';
import '../../../core/localization/app_translations.dart';

class CreateReportScreen extends StatefulWidget {
  final EventModel event;

  const CreateReportScreen({super.key, required this.event});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  PlatformFile? _programReportFile;
  PlatformFile? _financialReportFile;
  bool _isLoading = false;
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _lang = doc.data()?['language'] ?? 'en';
        });
      }
    }
  }

  Future<void> _pickFile(bool isProgramReport) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null) {
        setState(() {
          if (isProgramReport) {
            _programReportFile = result.files.first;
          } else {
            _financialReportFile = result.files.first;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppTranslations.get(_lang, 'error')}$e')),
      );
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

  Future<void> _submitReport() async {
    if (_programReportFile == null || _financialReportFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.get(_lang, 'upload_both_reports')),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      final programRef = FirebaseStorage.instance.ref().child(
        'reports/${widget.event.id}_program_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await programRef.putFile(File(_programReportFile!.path!));
      final programPdfUrl = await programRef.getDownloadURL();

      final financialRef = FirebaseStorage.instance.ref().child(
        'reports/${widget.event.id}_financial_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await financialRef.putFile(File(_financialReportFile!.path!));
      final financialPdfUrl = await financialRef.getDownloadURL();

      final newReport = ReportModel(
        id: '',
        eventId: widget.event.id!,
        eventTitle: widget.event.title,
        type: 'post_event',
        fileName: 'Post_Event_Report_${widget.event.title}.pdf',
        fileUrl: programPdfUrl,
        financialReportUrl: financialPdfUrl,
        submittedBy: user.uid,
        submittedByEmail: user.email ?? '',
        submittedAt: DateTime.now(),
        status: 'submitted',
        expiresAt: DateTime.now().add(const Duration(days: 365)),
      );

      await FirebaseFirestore.instance
          .collection('reports')
          .add(newReport.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.get(_lang, 'reports_submitted_success'),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppTranslations.get(_lang, 'failed_submit_report')}$e',
          ),
        ),
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
        title: Text(AppTranslations.get(_lang, 'submit_post_event_report')),
        backgroundColor: const Color(0xFF261A3D),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                              AppTranslations.get(_lang, 'official_templates'),
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
                            _lang,
                            'ensure_official_templates',
                          ),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _downloadTemplate(
                            'assets/reports/TEMPLATE LAPORAN PROGRAM (KELAB).docx.pdf',
                            'TEMPLATE_LAPORAN_PROGRAM.pdf',
                          ),
                          icon: const Icon(Icons.download, size: 18),
                          label: Text(
                            AppTranslations.get(
                              _lang,
                              'download_program_report_template',
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF9B6DFF),
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _downloadTemplate(
                            'assets/reports/LAPORAN KEWANGAN .docx.pdf',
                            'LAPORAN_KEWANGAN.pdf',
                          ),
                          icon: const Icon(Icons.download, size: 18),
                          label: Text(
                            AppTranslations.get(
                              _lang,
                              'download_financial_report_template',
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

                  const SizedBox(height: 32),
                  Text(
                    AppTranslations.get(_lang, 'program_report_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildUploadBox(
                    label: AppTranslations.get(
                      _lang,
                      'upload_program_report_pdf',
                    ),
                    file: _programReportFile,
                    onTap: () => _pickFile(true),
                  ),

                  const SizedBox(height: 32),
                  Text(
                    AppTranslations.get(_lang, 'financial_report_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildUploadBox(
                    label: AppTranslations.get(
                      _lang,
                      'upload_financial_report_pdf',
                    ),
                    file: _financialReportFile,
                    onTap: () => _pickFile(false),
                  ),

                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _submitReport,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF9B6DFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppTranslations.get(_lang, 'submit_reports'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUploadBox({
    required String label,
    required PlatformFile? file,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF261A3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null ? Colors.green : Colors.white24,
            width: file != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              file != null ? Icons.check_circle : Icons.upload_file,
              color: file != null ? Colors.green : Colors.redAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file?.name ?? label,
                style: TextStyle(
                  color: file != null ? Colors.white : Colors.white70,
                  fontWeight: file != null
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
    );
  }
}
