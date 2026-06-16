import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/screens/login_screen.dart';
import 'admin_proposal_screen.dart';
import '../../events/screens/manage_events_screen.dart';
import '../../reports/screens/admin_reports_screen.dart';
import '../../equipment/screens/approve_equipment_screen.dart';
import '../../equipment/screens/track_equipment_screen.dart';
import '../../../core/localization/app_translations.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0820),
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
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0820),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final data = snapshot.data?.data() ?? {};
        final lang = data['language'] ?? 'en';

        return Scaffold(
          backgroundColor: const Color(0xFF0D0820),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          AppTranslations.get(lang, 'admin_dashboard'),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _logout(context),
                        icon: const Icon(
                          Icons.logout_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _adminFeatureCard(
                    context: context,
                    title: AppTranslations.get(lang, 'proposal_approval'),
                    subtitle: AppTranslations.get(
                      lang,
                      'proposal_approval_desc',
                    ),
                    icon: Icons.assignment_turned_in_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminProposalScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _adminFeatureCard(
                    context: context,
                    title: AppTranslations.get(lang, 'college_events'),
                    subtitle: AppTranslations.get(lang, 'college_events_desc'),
                    icon: Icons.event_available_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageEventsScreen(
                            showManagementButtons: false,
                            isAdminView: true,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _adminFeatureCard(
                    context: context,
                    title: AppTranslations.get(lang, 'event_reports'),
                    subtitle: AppTranslations.get(lang, 'event_reports_desc'),
                    icon: Icons.receipt_long_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminReportsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _adminFeatureCard(
                    context: context,
                    title: AppTranslations.get(lang, 'equipment_requests'),
                    subtitle: AppTranslations.get(
                      lang,
                      'equipment_requests_desc',
                    ),
                    icon: Icons.inventory_2_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ApproveEquipmentScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _adminFeatureCard(
                    context: context,
                    title: AppTranslations.get(lang, 'equipment_usage'),
                    subtitle: AppTranslations.get(lang, 'equipment_usage_desc'),
                    icon: Icons.history_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrackEquipmentScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _adminFeatureCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF2B1D44),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFB99CFF).withOpacity(0.45)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF9B6DFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: const Color(0xFFB99CFF), size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
