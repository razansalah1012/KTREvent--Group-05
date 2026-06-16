import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razakevent/core/constants/app_colors.dart';
import 'package:razakevent/modules/participation/models/participation_model.dart';
import 'package:razakevent/modules/participation/screens/feedback_screen.dart';
import '../../../../core/localization/app_translations.dart';

class DigitalTicketScreen extends StatelessWidget {
  final ParticipationModel participation;
  final String eventLocation;
  final String eventImageUrl;
  final String eventDate;
  final String? startTime;
  final String? endTime;

  const DigitalTicketScreen({
    super.key,
    required this.participation,
    required this.eventLocation,
    required this.eventImageUrl,
    required this.eventDate,
    this.startTime,
    this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Not signed in', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final lang = snapshot.data?.data()?['language'] ?? 'en';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppTranslations.get(lang, 'digital_ticket'),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.file_download_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1835),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                            child: Image.network(
                              eventImageUrl.isNotEmpty
                                  ? eventImageUrl
                                  : 'https://via.placeholder.com/400x200',
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 220,
                                color: Colors.white10,
                                child: const Icon(
                                  Icons.event,
                                  color: Colors.white24,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                AppTranslations.get(lang, 'open'),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              participation.eventTitle,
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 25),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildDetailItem(
                                    AppTranslations.get(lang, 'date'),
                                    eventDate,
                                  ),
                                ),
                                Expanded(
                                  child: _buildDetailItem(
                                    AppTranslations.get(lang, 'time'),
                                    '${startTime ?? "9:00 AM"} - ${endTime ?? "6:00 PM"}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildDetailItem(
                                    AppTranslations.get(lang, 'location'),
                                    eventLocation,
                                  ),
                                ),
                                Expanded(
                                  child: _buildDetailItem(
                                    AppTranslations.get(lang, 'status'),
                                    participation.status,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 190,
                                  color: Colors.black,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Center(
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.quicksand(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: AppTranslations.get(
                                        lang,
                                        'ticket_id',
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '${participation.eventTitle.replaceAll(" ", "").toUpperCase()}-8X91Z',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                AppTranslations.get(lang, 'show_qr_code'),
                                style: GoogleFonts.quicksand(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            if (!participation.feedbackSubmitted)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (participation.id == null) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FeedbackScreen(
                                          participationId: participation.id!,
                                          eventTitle: participation.eventTitle,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.rate_review_outlined),
                                  label: Text(
                                    AppTranslations.get(lang, 'leave_feedback'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppTranslations.get(
                                        lang,
                                        'feedback_submitted',
                                      ),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(lang),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.quicksand(
            color: const Color(0xFFB8B2CB),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBottomNav(String lang) {
    return BottomNavigationBar(
      currentIndex: 1,
      backgroundColor: const Color(0xFF161225),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.white54,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.explore_outlined),
          label: AppTranslations.get(lang, 'nav_explore'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.confirmation_num_outlined),
          label: AppTranslations.get(lang, 'nav_bookings'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.inventory_2_outlined),
          label: AppTranslations.get(lang, 'nav_equipment'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.notifications_none_outlined),
          label: AppTranslations.get(lang, 'nav_alerts'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          label: AppTranslations.get(lang, 'nav_profile'),
        ),
      ],
    );
  }
}
