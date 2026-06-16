import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/certificate_model.dart';
import '../services/certificate_service.dart';
import '../../../core/localization/app_translations.dart';

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    final certService = CertificateService();

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
      builder: (context, userSnapshot) {
        final lang = userSnapshot.data?.data()?['language'] ?? 'en';

        return Scaffold(
          backgroundColor: const Color(0xFF0D0820),
          appBar: AppBar(
            title: Text(AppTranslations.get(lang, 'my_certificates')),
            backgroundColor: const Color(0xFF261A3D),
            foregroundColor: Colors.white,
          ),
          body: StreamBuilder<List<CertificateModel>>(
            stream: certService.getMyCertificates(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    AppTranslations.get(lang, 'error_loading_certificates'),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }

              final certs = snapshot.data ?? [];

              if (certs.isEmpty) {
                return Center(
                  child: Text(
                    AppTranslations.get(lang, 'no_certificates_yet'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: certs.length,
                itemBuilder: (context, index) {
                  final cert = certs[index];
                  return Card(
                    color: const Color(0xFF261A3D),
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFF9B6DFF),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(
                        Icons.workspace_premium,
                        color: Colors.amber,
                        size: 40,
                      ),
                      title: Text(
                        cert.eventTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppTranslations.get(lang, 'role')}${cert.role}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              '${AppTranslations.get(lang, 'issued')}${cert.issuedAt.toLocal().toString().split(' ')[0]}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await launchUrl(
                                    Uri.parse(cert.fileUrl),
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppTranslations.get(
                                          lang,
                                          'could_not_open_certificate',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.download),
                              label: Text(
                                AppTranslations.get(lang, 'view_download'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9B6DFF),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
