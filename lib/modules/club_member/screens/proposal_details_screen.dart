import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'edit_proposal_screen.dart';
import 'post_event_report_screen.dart';

class ProposalDetailsScreen extends StatelessWidget {
  final String proposalId;
  final Map<String, dynamic> proposalData;

  const ProposalDetailsScreen({
    super.key,
    required this.proposalId,
    required this.proposalData,
  });

  Future<void> openPdf(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = proposalData['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0820),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Proposal Details',
          style: TextStyle(
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
            border: Border.all(
              color: const Color(0xFFB99CFF),
              width: 2,
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(
                proposalData['programName'] ??
                    'Untitled Proposal',

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
                'Description',
                proposalData['description'],
              ),

              _detailItem(
                'Objectives',
                proposalData['objectives'],
              ),

              _detailItem(
                'Venue',
                proposalData['venue'],
              ),

              _detailItem(
                'Budget',
                'RM ${proposalData['budget'] ?? '-'}',
              ),

              _detailItem(
                'Organizer Type',
                proposalData['organizerType'],
              ),

              _detailItem(
                'PDF File',
                proposalData['pdfName'],
              ),

              if (proposalData['pdfUrl'] != null &&
                  proposalData['pdfUrl']
                      .toString()
                      .isNotEmpty)

                Padding(
                  padding:
                  const EdgeInsets.only(bottom: 20),

                  child: SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      onPressed: () {
                        openPdf(
                          proposalData['pdfUrl'],
                        );
                      },

                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                      ),

                      label: const Text(
                        'Open Proposal PDF',
                        style:
                        TextStyle(color: Colors.white),
                      ),

                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        Colors.redAccent,

                        padding:
                        const EdgeInsets.symmetric(
                          vertical: 14,
                        ),

                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ),

              _detailItem(
                'Admin Comment',
                proposalData['adminComment'] == null ||
                    proposalData['adminComment']
                        .toString()
                        .isEmpty
                    ? 'No comment yet'
                    : proposalData['adminComment'],
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
                          builder: (_) =>
                              EditProposalScreen(
                                proposalId: proposalId,
                                proposalData: proposalData,
                              ),
                        ),
                      );
                    },

                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white,
                    ),

                    label: const Text(
                      'Edit Proposal',
                      style:
                      TextStyle(color: Colors.white),
                    ),

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF9B6DFF),

                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 15,
                      ),

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(18),
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
                          builder: (_) =>
                              PostEventReportScreen(
                                proposalId: proposalId,
                                proposalData: proposalData,
                              ),
                        ),
                      );
                    },

                    icon: const Icon(
                      Icons.assignment_outlined,
                      color: Colors.white,
                    ),

                    label: const Text(
                      'Submit Post-Event Reports',
                      style:
                      TextStyle(color: Colors.white),
                    ),

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF9B6DFF),

                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 15,
                      ),

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(18),
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

  Widget _detailItem(
      String title,
      dynamic value,
      ) {

    return Padding(
      padding:
      const EdgeInsets.only(bottom: 18),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

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

            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(0.2),

        borderRadius:
        BorderRadius.circular(20),

        border: Border.all(color: color),
      ),

      child: Text(
        status.toUpperCase(),

        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}