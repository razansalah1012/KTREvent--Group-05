import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Use package import to avoid relative path issues.
import 'package:razakevent/modules/student/widgets/event_ticket_card.dart';

/// Shows events that the currently logged in student has booked or
/// registered for. It listens to a `bookings` collection filtered by
/// the current user ID. Each booking document should contain at
/// least an `eventId` field referencing the event in the `events`
/// collection. When there are no bookings, the screen displays a
/// friendly message. Adjust the collection names to match your
/// database structure.
class BookedEventsScreen extends StatelessWidget {
  const BookedEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Center(
        child: Text(
          'You must be logged in to view your booked events',
          style: GoogleFonts.quicksand(color: Colors.white70),
        ),
      );
    }
    // Remove gradient background so the parent ticket container is visible. Return the
    // StreamBuilder directly. When there are no bookings, a centered message
    // is shown. Otherwise the associated events are fetched and shown in a list.
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load your bookings',
              style: GoogleFonts.quicksand(color: Colors.white70),
            ),
          );
        }
        final bookingDocs = snapshot.data?.docs ?? [];
        if (bookingDocs.isEmpty) {
          return Center(
            child: Text(
              'You have not booked any events yet.',
              style: GoogleFonts.quicksand(color: Colors.white70),
            ),
          );
        }
        // For each booking document, fetch the associated event document.
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookingDocs.length,
          itemBuilder: (context, index) {
            final booking = bookingDocs[index].data();
            final eventId = booking['eventId'];
            if (eventId == null) {
              return const SizedBox.shrink();
            }
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('events')
                  .doc(eventId)
                  .get(),
              builder: (context, eventSnapshot) {
                if (eventSnapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                if (eventSnapshot.hasError || !eventSnapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Failed to load event details',
                      style: GoogleFonts.quicksand(color: Colors.white70),
                    ),
                  );
                }
                final eventData = eventSnapshot.data!.data();
                if (eventData == null) {
                  return const SizedBox.shrink();
                }
                final title = eventData['title'] ?? 'Untitled Event';
                final ts = eventData['date'] as Timestamp?;
                final date = ts != null ? ts.toDate() : null;
                final formattedDate = date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : 'Date TBD';
                final description = eventData['description'] ?? '';
                return EventTicketCard(
                  title: title,
                  date: formattedDate,
                  description: description,
                  onTap: () {
                    // TODO: Navigate to event details
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}