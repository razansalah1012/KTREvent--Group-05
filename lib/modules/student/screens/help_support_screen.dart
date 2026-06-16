import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF150F24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1533),
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildFaqItem(
            question: 'How do I book equipment?',
            answer:
                'Navigate to the Equipment tab at the bottom of the screen. Tap on any available equipment, select your dates, and tap Book.',
          ),
          _buildFaqItem(
            question: 'Where can I find my certificates?',
            answer:
                'Go to Profile > My Certificates to view and download any PDF certificates you have earned from past events.',
          ),
          _buildFaqItem(
            question: 'How do I join an event crew?',
            answer:
                'On the Explore tab, tap on an event and look for the "Apply as Crew" button. You can submit your role preference and application letter there.',
          ),

          const SizedBox(height: 32),

          Text(
            'Contact Us',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ListTile(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening email client...')),
              );
            },
            tileColor: const Color(0xFF241B3A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: const Icon(Icons.email_outlined, color: Color(0xFF9B6DFF)),
            title: Text(
              'Email Support',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            ),
            subtitle: Text(
              'support@razakevent.com',
              style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        collapsedBackgroundColor: const Color(0xFF241B3A),
        backgroundColor: const Color(0xFF241B3A),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          question,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: GoogleFonts.quicksand(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
