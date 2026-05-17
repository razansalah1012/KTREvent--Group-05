import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import the login screen so we can navigate back to it on logout.
import '../../auth/screens/login_screen.dart';

/// A simple dashboard for admin users. Currently this screen just
/// displays a heading and provides a logout button in the app bar.
/// You can extend this screen with real administrative functionality
/// such as user management, event approval flows and analytics.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  /// Signs out the current user and navigates back to the login
  /// screen, clearing the navigation stack.
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF241b3d),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF110d27), Color(0xFF1e1533), Color(0xFF2a2147)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            'Admin Dashboard',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}