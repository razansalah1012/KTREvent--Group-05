import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import 'report_details_screen.dart';
import '../../../core/localization/app_translations.dart';

class ReportsListScreen extends StatelessWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF110D27),
        body: Center(
          child: Text('Not signed in', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final String userId = user.uid;
    final reportService = ReportService();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        final lang = userSnapshot.data?.data()?['language'] ?? 'en';

        return Scaffold(
          appBar: AppBar(
            title: Text(AppTranslations.get(lang, 'event_reports')),
            backgroundColor: const Color(0xFF241B3D),
            foregroundColor: Colors.white,
          ),
          body: StreamBuilder<List<ReportModel>>(
            stream: reportService.getReportsSubmittedBy(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '${AppTranslations.get(lang, 'error')}${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }
              final reports = snapshot.data ?? [];
              if (reports.isEmpty) {
                return Center(
                  child: Text(
                    AppTranslations.get(lang, 'no_reports_submitted_yet'),
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }
              return ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return ListTile(
                    title: Text(
                      report.eventTitle,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${AppTranslations.get(lang, 'type')}${report.type == 'post_event' ? AppTranslations.get(lang, 'post_event') : report.type}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: Text(
                      report.status,
                      style: TextStyle(
                        color: report.status == 'reviewed'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailsScreen(report: report),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          backgroundColor: const Color(0xFF110D27),
        );
      },
    );
  }
}
