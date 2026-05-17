import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// Use package imports to avoid relative path resolution issues.
import 'package:razakevent/modules/student/widgets/event_ticket_card.dart';

/// ExploreEventsScreen shows a list of all approved/upcoming events
/// in a ticket‑style format. Events are fetched from the `events`
/// collection in Firestore. Adjust the query to match your own
/// schema (e.g. filter by `status == 'approved'`).
class ExploreEventsScreen extends StatelessWidget {
  const ExploreEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Remove gradient background so the parent ticket container is visible. Simply return
    // the StreamBuilder with a ListView of event tickets.
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('events')
      // Adjust ordering or filters here to match your data model
          .orderBy('date', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
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
            final data = docs[index].data();
            final title = data['title'] ?? 'Untitled Event';
            final timestamp = data['date'] as Timestamp?;
            final DateTime? date =
            timestamp != null ? timestamp.toDate() : null;
            final formattedDate = date != null
                ? '${date.day}/${date.month}/${date.year}'
                : 'Date TBD';
            final description = data['description'] ?? 'No description.';
            return EventTicketCard(
              title: title,
              date: formattedDate,
              description: description,
              onTap: () {
                // TODO: Navigate to event details page if you implement one
              },
            );
          },
        );
      },
    );
  }
}