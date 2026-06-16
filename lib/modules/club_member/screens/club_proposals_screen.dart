import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razakevent/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

import 'submit_proposal_screen.dart';
import 'proposal_details_screen.dart';
import '../../../core/localization/app_translations.dart';

class ClubProposalsScreen extends StatefulWidget {
  const ClubProposalsScreen({super.key});

  @override
  State<ClubProposalsScreen> createState() => _ClubProposalsScreenState();
}

class _ClubProposalsScreenState extends State<ClubProposalsScreen> {
  String _lang = 'en';
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _lang = doc.data()?['language'] ?? 'en';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppTranslations.get(_lang, 'my_proposals'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubmitProposalScreen()),
              ).then((_) => _loadLanguage());
            },
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
            ),
            tooltip: AppTranslations.get(_lang, 'submit_new_proposal'),
          ),
        ],
      ),
      body: currentUser == null
          ? Center(
              child: Text(
                AppTranslations.get(_lang, 'not_logged_in'),
                style: const TextStyle(color: Colors.white70),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('proposals')
                  .where('submittedBy', isEqualTo: currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppTranslations.get(_lang, 'no_proposals_yet'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppTranslations.get(
                              _lang,
                              'submit_new_event_proposal',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final proposals = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: proposals.length,
                  itemBuilder: (context, index) {
                    final data =
                        proposals[index].data() as Map<String, dynamic>;
                    final programName =
                        data['programName'] ??
                        AppTranslations.get(_lang, 'untitled_proposal');
                    final status = data['status'] ?? 'pending';
                    final venue = data['venue'] ?? '-';

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProposalDetailsScreen(
                              proposalId: proposals[index].id,
                              proposalData: data,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              programName,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  venue,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildStatusBadge(status),
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

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orangeAccent;
    if (status.toLowerCase() == 'approved') color = Colors.greenAccent;
    if (status.toLowerCase() == 'rejected') color = Colors.redAccent;

    String translatedStatus = AppTranslations.get(_lang, status.toLowerCase());
    if (translatedStatus == status.toLowerCase()) {
      translatedStatus = status.toUpperCase();
    } else {
      translatedStatus = translatedStatus.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        translatedStatus,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
