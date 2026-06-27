import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:razakevent/modules/student/screens/explore_events_screen.dart';
import 'package:razakevent/modules/student/screens/booked_events_screen.dart';
import 'package:razakevent/modules/student/screens/student_profile_screen.dart';
import 'package:razakevent/modules/student/screens/notifications_screen.dart';
import '../../equipment/screens/request_equipment_screen.dart';
import 'package:razakevent/core/constants/app_colors.dart';

import '../../../core/localization/app_translations.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const ExploreEventsScreen(),
      const BookedEventsScreen(),
      const RequestEquipmentScreen(),
      const NotificationsScreen(),
      const StudentProfileScreen(),
    ];
  }

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
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final data = snapshot.data?.data() ?? {};
        final lang = data['language'] ?? 'en';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: _pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: const Color(0xFF1A162B),
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
                icon: const Icon(Icons.confirmation_num_outlined),
                activeIcon: const Icon(Icons.confirmation_num),
                label: AppTranslations.get(lang, 'explore'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.confirmation_num_outlined),
                activeIcon: const Icon(Icons.confirmation_num),
                label: AppTranslations.get(lang, 'bookings'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.inventory_2_outlined),
                activeIcon: const Icon(Icons.inventory_2),
                label: AppTranslations.get(lang, 'equipment'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.notifications_outlined),
                activeIcon: const Icon(Icons.notifications),
                label: AppTranslations.get(lang, 'alerts'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: AppTranslations.get(lang, 'profile'),
              ),
            ],
          ),
        );
      },
    );
  }
}
