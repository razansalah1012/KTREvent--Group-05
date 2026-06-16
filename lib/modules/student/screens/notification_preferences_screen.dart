import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text('Not signed in.')));

    return Scaffold(
      backgroundColor: const Color(0xFF150F24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1533),
        title: Text(
          'Notification Preferences',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() ?? {};
          final prefs =
              data['notificationPrefs'] as Map<String, dynamic>? ??
              {
                'push_enabled': true,
                'email_enabled': true,
                'marketing_enabled': false,
              };

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Manage Notifications',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose what we get in touch about.',
                style: GoogleFonts.quicksand(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Receive alerts directly on your device.',
                value: prefs['push_enabled'] ?? true,
                onChanged: (val) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set({
                        'notificationPrefs': {'push_enabled': val},
                      }, SetOptions(merge: true));
                },
              ),
              const SizedBox(height: 16),

              _buildSwitchTile(
                title: 'Email Notifications',
                subtitle: 'Receive important updates to your inbox.',
                value: prefs['email_enabled'] ?? true,
                onChanged: (val) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set({
                        'notificationPrefs': {'email_enabled': val},
                      }, SetOptions(merge: true));
                },
              ),
              const SizedBox(height: 16),

              _buildSwitchTile(
                title: 'Marketing & Offers',
                subtitle: 'Receive news about upcoming events.',
                value: prefs['marketing_enabled'] ?? false,
                onChanged: (val) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set({
                        'notificationPrefs': {'marketing_enabled': val},
                      }, SetOptions(merge: true));
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF241B3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 12),
        ),
        value: value,
        activeThumbColor: const Color(0xFF9B6DFF),
        onChanged: onChanged,
      ),
    );
  }
}
