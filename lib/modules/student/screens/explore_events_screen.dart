import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:razakevent/modules/student/widgets/event_ticket_card.dart';
import 'event_details_screen.dart';

class ExploreEventsScreen extends StatelessWidget {
  const ExploreEventsScreen({super.key});

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return 'Date TBD';

    if (rawDate is Timestamp) {
      final date = rawDate.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    if (rawDate is String && rawDate.trim().isNotEmpty) {
      final parsedDate = DateTime.tryParse(rawDate);

      if (parsedDate != null) {
        return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
      }

      return rawDate;
    }

    return 'Date TBD';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .orderBy('date', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load events',
              style: GoogleFonts.quicksand(color: Colors.white70),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No events available',
              style: GoogleFonts.quicksand(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final title = data['title'] ?? 'Untitled Event';
            final formattedDate = _formatDate(data['date']);
            final location = data['location'] ?? 'Location TBD';
            final description = data['description'] ?? 'No description.';
            final organizerId = data['organizerId'] ?? '';

            return EventTicketCard(
              title: title,
              date: formattedDate,
              description: description,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventDetailsScreen(
                      eventId: doc.id,
                      title: title,
                      date: formattedDate,
                      location: location,
                      description: description,
                      organizerId: organizerId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}