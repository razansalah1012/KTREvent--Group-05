import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminProposalScreen extends StatefulWidget {
  const AdminProposalScreen({super.key});

  @override
  State<AdminProposalScreen> createState() => _AdminProposalScreenState();
}

class _AdminProposalScreenState extends State<AdminProposalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0820),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Proposal Approval',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('proposals')
            .orderBy('submittedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No proposals submitted yet.',
                style: TextStyle(color: Colors.white70, fontSize: 17),
              ),
            );
          }

          final proposals = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: proposals.length,
            itemBuilder: (context, index) {
              final proposal = proposals[index];
              final data = proposal.data() as Map<String, dynamic>;

              final programName = data['programName'] ?? 'Untitled Proposal';

              final organizerType = data['organizerType'] ?? '-';

              final venue = data['venue'] ?? '-';

              final status = data['status'] ?? 'pending';

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminProposalDetailsScreen(
                        proposalId: proposal.id,
                        proposalData: data,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B1D44),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFB99CFF).withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        programName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Organizer Type: $organizerType',
                        style: const TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Venue: $venue',
                        style: const TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 12),

                      _statusBadge(status),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AdminProposalDetailsScreen extends StatefulWidget {
  final String proposalId;
  final Map<String, dynamic> proposalData;

  const AdminProposalDetailsScreen({
    super.key,
    required this.proposalId,
    required this.proposalData,
  });

  @override
  State<AdminProposalDetailsScreen> createState() =>
      _AdminProposalDetailsScreenState();
}

class _AdminProposalDetailsScreenState
    extends State<AdminProposalDetailsScreen> {
  final TextEditingController commentController = TextEditingController();

  bool isUpdating = false;

  Future<void> openPdf(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();

    commentController.text = widget.proposalData['adminComment'] ?? '';
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> updateProposalStatus(String newStatus) async {
    setState(() {
      isUpdating = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('proposals')
          .doc(widget.proposalId)
          .update({
            'status': newStatus,
            'adminComment': commentController.text.trim(),
            'reviewedBy': currentUser?.uid ?? '',
            'reviewedByEmail': currentUser?.email ?? '',
            'reviewedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proposal $newStatus successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating proposal: $e')));
    }

    if (mounted) {
      setState(() {
        isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.proposalData;
    final status = data['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0820),
        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text(
          'Review Proposal',
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
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                data['programName'] ?? 'Untitled Proposal',

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _statusBadge(status),

              const SizedBox(height: 24),

              _detailItem('Description', data['description']),

              _detailItem('Objectives', data['objectives']),

              _detailItem('Venue', data['venue']),

              _detailItem('Budget', 'RM ${data['budget'] ?? '-'}'),

              _detailItem('Organizer Type', data['organizerType']),

              _detailItem('Submitted By', data['submittedByEmail']),

              _detailItem('PDF File', data['pdfName']),

              if (data['pdfUrl'] != null &&
                  data['pdfUrl'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),

                  child: SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      onPressed: () {
                        openPdf(data['pdfUrl']);
                      },

                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                      ),

                      label: const Text(
                        'Open Proposal PDF',
                        style: TextStyle(color: Colors.white),
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

              const SizedBox(height: 18),

              TextField(
                controller: commentController,
                maxLines: 4,

                style: const TextStyle(color: Colors.white),

                decoration: InputDecoration(
                  labelText: 'Admin Comment',

                  labelStyle: const TextStyle(color: Colors.white70),

                  hintText: 'Add remarks or reason for approval/rejection',

                  hintStyle: const TextStyle(color: Colors.white38),

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
                ),
              ),

              const SizedBox(height: 26),

              if (status == 'pending') ...[
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: isUpdating
                        ? null
                        : () => updateProposalStatus('approved'),

                    icon: const Icon(Icons.check, color: Colors.white),

                    label: const Text(
                      'Approve Proposal',
                      style: TextStyle(color: Colors.white),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,

                      padding: const EdgeInsets.symmetric(vertical: 15),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: isUpdating
                        ? null
                        : () => updateProposalStatus('rejected'),

                    icon: const Icon(Icons.close, color: Colors.white),

                    label: const Text(
                      'Reject Proposal',
                      style: TextStyle(color: Colors.white),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,

                      padding: const EdgeInsets.symmetric(vertical: 15),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ] else
                const Text(
                  'This proposal has already been reviewed.',
                  style: TextStyle(color: Colors.white70),
                ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),

      decoration: BoxDecoration(
        color: color.withOpacity(0.2),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: color),
      ),

      child: Text(
        status.toUpperCase(),

        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
