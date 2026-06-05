import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/participation_model.dart';
import '../services/participation_service.dart';

class TrackParticipantsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const TrackParticipantsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<TrackParticipantsScreen> createState() => _TrackParticipantsScreenState();
}

class _TrackParticipantsScreenState extends State<TrackParticipantsScreen> {
  final ParticipationService _participationService = ParticipationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF110D27),
      appBar: AppBar(
        title: Text('Participants: ${widget.eventTitle}', style: const TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF241B3D),
        foregroundColor: Colors.white,
      ),
      body: Container(
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
          stream: _participationService.getParticipantsForEvent(widget.eventId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
            }

            final participants = snapshot.data ?? [];

            if (participants.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline, color: Colors.white24, size: 64),
                    const SizedBox(height: 16),
                    Text('No participants registered yet.', style: GoogleFonts.quicksand(color: Colors.white70)),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Color(0xFFBFA8FF)),
                      const SizedBox(width: 8),
                      Text(
                        'Total Participants: ${participants.length}',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final p = participants[index];
                      return _buildParticipantCard(p);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildParticipantCard(ParticipationModel p) {
    return Card(
      color: const Color(0xFF241B3D),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFBFA8FF), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.userName,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(p.userEmail, style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
                _buildStatusBadge(p.status),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reg: ${p.registeredAt.day}/${p.registeredAt.month}/${p.registeredAt.year}',
                  style: GoogleFonts.quicksand(color: Colors.white38, fontSize: 12),
                ),
                PopupMenuButton<String>(
                  onSelected: (status) => _updateStatus(p.id!, status),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Registered', child: Text('Registered')),
                    const PopupMenuItem(value: 'Attended', child: Text('Attended')),
                    const PopupMenuItem(value: 'Cancelled', child: Text('Cancelled / Absent')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B6DFF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF9B6DFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Mark Status', style: TextStyle(color: Color(0xFFBFA8FF), fontSize: 12)),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFFBFA8FF), size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.blue;
    if (status == 'Attended') color = Colors.green;
    if (status == 'Cancelled') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _updateStatus(String participationId, String status) async {
    try {
      await _participationService.updateParticipationStatus(participationId, status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
