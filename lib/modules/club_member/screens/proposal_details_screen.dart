import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_proposal_screen.dart';
import 'post_event_report_screen.dart';
import '../../../core/localization/app_translations.dart';

class ProposalDetailsScreen extends StatefulWidget {
  final String proposalId;
  final Map<String, dynamic> proposalData;

  const ProposalDetailsScreen({
    super.key,
    required this.proposalId,
    required this.proposalData,
  });

  @override
  State<ProposalDetailsScreen> createState() => _ProposalDetailsScreenState();
}

class _ProposalDetailsScreenState extends State<ProposalDetailsScreen> {
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

  Future<void> openPdf(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.proposalData['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0820),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          AppTranslations.get(_lang, 'proposal_details'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                widget.proposalData['programName'] ??
                    AppTranslations.get(_lang, 'untitled_proposal'),

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _statusBadge(status),

              const SizedBox(height: 24),

              _detailItem(
                AppTranslations.get(_lang, 'description'),
                widget.proposalData['description'],
              ),

              _detailItem(
                AppTranslations.get(_lang, 'objectives'),
                widget.proposalData['objectives'],
              ),

              _detailItem(
                AppTranslations.get(_lang, 'venue'),
                widget.proposalData['venue'],
              ),

              _detailItem(
                AppTranslations.get(_lang, 'budget'),
                'RM ${widget.proposalData['budget'] ?? '-'}',
              ),

              _detailItem(
                AppTranslations.get(_lang, 'organizer_type'),
                widget.proposalData['organizerType'],
              ),

              _detailItem(
                AppTranslations.get(_lang, 'pdf_file'),
                widget.proposalData['pdfName'],
              ),

              if (widget.proposalData['pdfUrl'] != null &&
                  widget.proposalData['pdfUrl'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),

                  child: SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      onPressed: () {
                        openPdf(widget.proposalData['pdfUrl']);
                      },

                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                      ),

                      label: Text(
                        AppTranslations.get(_lang, 'open_proposal_pdf'),
                        style: const TextStyle(color: Colors.white),
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,

                        padding: const EdgeInsets.symmetric(vertical: 14),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ),

              _detailItem(
                AppTranslations.get(_lang, 'admin_comment'),
                widget.proposalData['adminComment'] == null ||
                        widget.proposalData['adminComment'].toString().isEmpty
                    ? AppTranslations.get(_lang, 'no_comment_yet')
                    : widget.proposalData['adminComment'],
              ),

              const SizedBox(height: 25),

              if (status == 'pending')
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => EditProposalScreen(
                            proposalId: widget.proposalId,
                            proposalData: widget.proposalData,
                          ),
                        ),
                      );
                    },

                    icon: const Icon(Icons.edit, color: Colors.white),

                    label: Text(
                      AppTranslations.get(_lang, 'edit_proposal'),
                      style: const TextStyle(color: Colors.white),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B6DFF),

                      padding: const EdgeInsets.symmetric(vertical: 15),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),

              if (status == 'approved') ...[
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => PostEventReportScreen(
                            proposalId: widget.proposalId,
                            proposalData: widget.proposalData,
                          ),
                        ),
                      );
                    },

                    icon: const Icon(
                      Icons.assignment_outlined,
                      color: Colors.white,
                    ),

                    label: Text(
                      AppTranslations.get(
                        _lang,
                        'submit_post_event_reports_btn',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B6DFF),

                      padding: const EdgeInsets.symmetric(vertical: 15),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style: const TextStyle(
              color: Color(0xFFB99CFF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value?.toString() ?? '-',

            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.greenAccent;
        break;

      case 'rejected':
        color = Colors.redAccent;
        break;

      default:
        color = Colors.orangeAccent;
    }

    String translatedStatus = AppTranslations.get(_lang, status.toLowerCase());
    if (translatedStatus == status.toLowerCase()) {
      translatedStatus = status.toUpperCase();
    } else {
      translatedStatus = translatedStatus.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),

      decoration: BoxDecoration(
        color: color.withOpacity(0.2),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: color),
      ),

      child: Text(
        translatedStatus,

        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
