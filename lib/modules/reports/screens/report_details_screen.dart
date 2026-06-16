import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../../certificates/services/certificate_service.dart';
import '../../certificates/widgets/admin_certificate_dialog.dart'
    as import_dialog;
import '../../../core/localization/app_translations.dart';

class ReportDetailsScreen extends StatefulWidget {
  final ReportModel report;
  const ReportDetailsScreen({super.key, required this.report});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reviewed':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();
    final report = widget.report;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppTranslations.get(_lang, 'report_details'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF241B3D),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0D0820),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2B1D44),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFB99CFF).withOpacity(0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.eventTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.white54,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${AppTranslations.get(_lang, 'submitted_by')}${report.submittedByEmail}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.category_outlined,
                        color: Colors.white54,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${AppTranslations.get(_lang, 'type')}${report.type == 'post_event' ? AppTranslations.get(_lang, 'post_event') : report.type}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(report.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _getStatusColor(report.status)),
                    ),
                    child: Text(
                      report.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(report.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const Divider(color: Colors.white24, height: 32),

                  Text(
                    AppTranslations.get(_lang, 'attached_documents'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final urlStr = report.fileUrl;
                        if (urlStr.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppTranslations.get(
                                  _lang,
                                  'program_report_url_missing',
                                ),
                              ),
                            ),
                          );
                          return;
                        }
                        try {
                          await launchUrl(
                            Uri.parse(urlStr),
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppTranslations.get(
                                  _lang,
                                  'could_not_open_pdf',
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      label: Text(
                        report.type == 'post_event'
                            ? AppTranslations.get(
                                _lang,
                                'view_program_report_pdf',
                              )
                            : report.fileName,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: const Color(0xFFB99CFF),
                        side: const BorderSide(color: Color(0xFFB99CFF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  if (report.type == 'post_event' &&
                      report.financialReportUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final urlStr = report.financialReportUrl;
                          try {
                            await launchUrl(
                              Uri.parse(urlStr),
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppTranslations.get(
                                    _lang,
                                    'could_not_open_pdf',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.receipt_long, size: 20),
                        label: Text(
                          AppTranslations.get(
                            _lang,
                            'view_financial_report_pdf',
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: const Color(0xFFB99CFF),
                          side: const BorderSide(color: Color(0xFFB99CFF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Spacer(),
            if (report.status == 'submitted') ...[
              Text(
                AppTranslations.get(_lang, 'admin_review'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: AppTranslations.get(
                    _lang,
                    'leave_comment_feedback',
                  ),
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF261A3D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF9B6DFF),
                      width: 1.5,
                    ),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              setState(() => _isSubmitting = true);
                              try {
                                await reportService.updateReportStatus(
                                  report.id,
                                  'rejected',
                                  reviewerId: report.submittedBy,
                                  reviewerComment: _commentController.text,
                                );
                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${AppTranslations.get(_lang, 'error')}$e',
                                      ),
                                    ),
                                  );
                                  setState(() => _isSubmitting = false);
                                }
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppTranslations.get(_lang, 'reject'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              if (report.type == 'post_event') {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => import_dialog.AdminCertificateDialog(
                                    eventId: report.eventId,
                                    eventTitle: report.eventTitle,
                                    organizerId: report.submittedBy,
                                    onConfirm: (includeOrganizers, studentRoles) async {
                                      Navigator.pop(ctx);
                                      setState(() => _isSubmitting = true);
                                      try {
                                        await reportService.updateReportStatus(
                                          report.id,
                                          'reviewed',
                                          reviewerId: report.submittedBy,
                                          reviewerComment:
                                              _commentController.text,
                                        );

                                        final certService =
                                            CertificateService();
                                        await certService
                                            .generateAndIssueCertificatesForEvent(
                                              eventId: report.eventId,
                                              eventTitle: report.eventTitle,
                                              organizerId: report.submittedBy,
                                              includeOrganizers:
                                                  includeOrganizers,
                                              studentCustomRoles: studentRoles,
                                            );

                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                AppTranslations.get(
                                                  _lang,
                                                  'report_approved_certs_generated',
                                                ),
                                              ),
                                            ),
                                          );
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${AppTranslations.get(_lang, 'error')}$e',
                                              ),
                                            ),
                                          );
                                          setState(() => _isSubmitting = false);
                                        }
                                      }
                                    },
                                  ),
                                );
                              } else {
                                setState(() => _isSubmitting = true);
                                try {
                                  await reportService.updateReportStatus(
                                    report.id,
                                    'reviewed',
                                    reviewerId: report.submittedBy,
                                    reviewerComment: _commentController.text,
                                  );
                                  if (mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${AppTranslations.get(_lang, 'error')}$e',
                                        ),
                                      ),
                                    );
                                    setState(() => _isSubmitting = false);
                                  }
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              AppTranslations.get(
                                _lang,
                                'approve_generate_certs',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
