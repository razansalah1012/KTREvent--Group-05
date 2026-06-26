import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/localization/app_translations.dart';

class TrackEquipmentScreen extends StatelessWidget {
  final bool isTab;
  const TrackEquipmentScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
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

        Widget bodyContent = StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('equipment_requests')
              .where('requesterId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  AppTranslations.get(lang, 'no_requests_found').replaceAll(' ', ''), // '0 requests found.' fallback
                  style: const TextStyle(color: Colors.white54),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: snapshot.data!.docs.map((doc) {
                return Card(
                  color: const Color(0xFF241B3A),
                  child: ListTile(
                    title: Text(
                      doc['equipmentName'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      "${AppTranslations.get(lang, 'quantity')} ${doc['quantity']}",
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(doc['status'] ?? 'pending').withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (doc['status'] ?? 'pending').toString().toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(doc['status'] ?? 'pending'),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );

        if (isTab) {
          return bodyContent;
        }

        return Scaffold(
          backgroundColor: const Color(0xFF161225),
          appBar: AppBar(
            backgroundColor: const Color(0xFF161225),
            title: Text(AppTranslations.get(lang, 'track_equipment')),
          ),
          body: bodyContent,
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'returned':
        return Colors.blue;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}
