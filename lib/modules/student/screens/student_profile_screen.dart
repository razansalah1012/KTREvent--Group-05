import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import the update profile screen so we can navigate to it from
// the student profile page when the user taps the edit button.
import 'update_profile_screen.dart';
// Import the login screen so we can navigate back to the login page
// after the user signs out.
// Import the login screen via package import to ensure proper resolution.
import 'package:razakevent/modules/auth/screens/login_screen.dart';

/// A simple profile page for students. It fetches the current user's
/// profile information from Firestore and displays their name, email,
/// role and account status. You can extend this page with additional
/// profile editing features or preferences.
class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Text(
          'You are not signed in.',
          style: GoogleFonts.quicksand(color: Colors.white70),
        ),
      );
    }
    // Remove gradient background so the parent ticket container is visible. Directly
    // return a StreamBuilder that shows the user's profile information.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              'Failed to load profile',
              style: GoogleFonts.quicksand(color: Colors.white70),
            ),
          );
        }
        final data = snapshot.data!.data();
        if (data == null) {
          return Center(
            child: Text(
              'Profile data not found.',
              style: GoogleFonts.quicksand(color: Colors.white70),
            ),
          );
        }
        final fullName = data['fullName'] ?? '';
        final email = data['email'] ?? user.email;
        final role = data['role'] ?? 'student';
        final status = data['status'] ?? 'approved';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF7E57C2),
                child: Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : '',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                fullName,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                style: GoogleFonts.quicksand(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _InfoBadge(label: 'Role', value: role),
                  const SizedBox(width: 16),
                  _InfoBadge(label: 'Status', value: status),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'This is your profile page. You can extend this screen to allow users to edit their information, change password or manage their preferences.',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),
              // Action buttons: edit profile and logout
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UpdateProfileScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8257E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Edit Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () async {
                      // Sign out the user and navigate back to the login screen
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                            (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
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
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2F2646),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7E57C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.quicksand(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}