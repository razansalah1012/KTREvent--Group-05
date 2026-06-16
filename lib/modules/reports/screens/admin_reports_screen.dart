import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';
import 'report_details_screen.dart';
import '../../../core/localization/app_translations.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  Future<void> openPdf(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {}
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Not available';
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return value.toString();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reviewed':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  Future<void> _updateProposalStatus({
    required BuildContext context,
    required String proposalId,
    required String status,
    required String lang,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('proposals')
          .doc(proposalId)
          .update({
            'reportStatus': status,
            'reportReviewedAt': FieldValue.serverTimestamp(),
          });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppTranslations.get(lang, 'proposal_marked_as')}$status',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppTranslations.get(lang, 'error_updating_proposal')}$e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Not signed in', style: TextStyle(color: Colors.white)),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        final lang = userSnapshot.data?.data()?['language'] ?? 'en';

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: const Color(0xFF0D0820),
            appBar: AppBar(
              backgroundColor: const Color(0xFF241B3D),
              foregroundColor: Colors.white,
              title: Text(
                AppTranslations.get(lang, 'admin_reports'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              bottom: TabBar(
                indicatorColor: const Color(0xFFB99CFF),
                labelColor: const Color(0xFFB99CFF),
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: AppTranslations.get(lang, 'pre_event_proposals')),
                  Tab(text: AppTranslations.get(lang, 'post_event_reports')),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildProposalsList(lang),
                _buildPostEventReportsList(lang),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProposalsList(String lang) {
    final now = Timestamp.fromDate(DateTime.now());
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('proposals')
          .where('reportStatus', whereIn: ['submitted', 'reviewed', 'rejected'])
          .where('reportExpiresAt', isGreaterThan: now)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB99CFF)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${AppTranslations.get(lang, 'error')}${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              AppTranslations.get(lang, 'no_submitted_proposals'),
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final programName =
                data['programName'] ??
                AppTranslations.get(lang, 'untitled_event');
            final submittedByEmail = data['submittedByEmail'] ?? '-';
            final reportStatus = data['reportStatus'] ?? 'submitted';
            final programReportName =
                data['programReportName'] ??
                AppTranslations.get(lang, 'no_program_report');
            final financialReportName =
                data['financialReportName'] ??
                AppTranslations.get(lang, 'no_financial_report');
            final programReportUrl = data['programReportUrl'];
            final financialReportUrl = data['financialReportUrl'];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
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
                    programName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppTranslations.get(lang, 'submitted_by')}$submittedByEmail',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '${AppTranslations.get(lang, 'submitted_at')}${_formatDate(data['submittedReportAt'])}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const Divider(color: Colors.white24, height: 28),

                  Text(
                    '${AppTranslations.get(lang, 'program_report')}$programReportName',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (programReportUrl != null &&
                      programReportUrl.toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => openPdf(programReportUrl),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: Text(
                          AppTranslations.get(lang, 'open_program_report'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB99CFF),
                          side: const BorderSide(color: Color(0xFFB99CFF)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text(
                    '${AppTranslations.get(lang, 'financial_report')}$financialReportName',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (financialReportUrl != null &&
                      financialReportUrl.toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => openPdf(financialReportUrl),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: Text(
                          AppTranslations.get(lang, 'open_financial_report'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB99CFF),
                          side: const BorderSide(color: Color(0xFFB99CFF)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(reportStatus).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _statusColor(reportStatus)),
                    ),
                    child: Text(
                      reportStatus.toString().toUpperCase(),
                      style: TextStyle(
                        color: _statusColor(reportStatus),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (reportStatus == 'submitted')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateProposalStatus(
                              context: context,
                              proposalId: doc.id,
                              status: 'rejected',
                              lang: lang,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            child: Text(AppTranslations.get(lang, 'reject')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateProposalStatus(
                              context: context,
                              proposalId: doc.id,
                              status: 'reviewed',
                              lang: lang,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                            ),
                            child: Text(
                              AppTranslations.get(lang, 'mark_reviewed'),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostEventReportsList(String lang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB99CFF)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${AppTranslations.get(lang, 'error')}${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              AppTranslations.get(lang, 'no_post_event_reports'),
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final report = ReportModel.fromMap(doc.id, data);

            return Card(
              color: const Color(0xFF2B1D44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: Text(
                  report.eventTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${AppTranslations.get(lang, 'submitted_by')}${report.submittedByEmail}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportDetailsScreen(report: report),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
