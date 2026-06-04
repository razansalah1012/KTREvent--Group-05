import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/participation_model.dart';
import '../services/participation_service.dart';

class TrackParticipantsScreen extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  
  TrackParticipantsScreen({super.key, required this.eventId, required this.eventTitle});

  final ParticipationService _service = ParticipationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track: $eventTitle', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF241b3d),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF110d27), Color(0xFF1e1533), Color(0xFF2a2147)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<List<ParticipationModel>>(
          stream: _service.getParticipantsForEvent(eventId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text('No participants registered yet.', style: GoogleFonts.poppins(color: Colors.white70))
              );
            }

            final participants = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final p = participants[index];
                return Card(
                  color: const Color(0xFF241b3d),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF8257E5),
                      child: Text(p.userName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(p.userName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(p.userEmail, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                    trailing: p.rating != null 
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(p.rating.toString(), style: const TextStyle(color: Colors.white)),
                            ],
                          )
                        : const Text('Registered', style: TextStyle(color: Color(0xFF8257E5), fontWeight: FontWeight.bold)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}