import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../participation/models/participation_model.dart';
import '../../participation/services/participation_service.dart';
import 'event_details_screen.dart';
import '../widgets/event_ticket_card.dart';

class BookedEventsScreen extends StatelessWidget {
  const BookedEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ParticipationService participationService = ParticipationService();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF110D27), Color(0xFF1E1533), Color(0xFF2A2147)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: StreamBuilder<List<ParticipationModel>>(
        stream: participationService.getUserParticipations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load your registrations',
                      style: GoogleFonts.quicksand(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          final participations = snapshot.data ?? [];

          if (participations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.confirmation_number_outlined, color: Colors.white24, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'You have not registered for any events yet.',
                    style: GoogleFonts.quicksand(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: participations.length,
            itemBuilder: (context, index) {
              final p = participations[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('events').doc(p.eventId).get(),
                builder: (context, eventSnapshot) {
                  // While loading event data, show a placeholder
                  if (eventSnapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 120,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF241B3D).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                    );
                  }

                  final eventData = eventSnapshot.data?.data() as Map<String, dynamic>?;
                  
                  // Even if event is deleted or missing, we can show the participation info we have
                  final dateTs = eventData?['date'] as Timestamp?;
                  final date = dateTs?.toDate();
                  final formattedDate = date != null ? '${date.day}/${date.month}/${date.year}' : 'TBD';

                  return EventTicketCard(
                    title: p.eventTitle,
                    date: formattedDate,
                    description: 'Status: ${p.status}',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailsScreen(
                            eventId: p.eventId,
                            title: p.eventTitle,
                            date: formattedDate,
                            location: eventData?['location'] ?? 'TBD',
                            description: eventData?['description'] ?? '',
                            organizerId: eventData?['organizerId'] ?? '',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
