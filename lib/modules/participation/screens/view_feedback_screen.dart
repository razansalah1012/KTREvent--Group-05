import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/participation_service.dart';

class ViewFeedbackScreen extends StatelessWidget {
  final String eventId;
  final String eventTitle;

  const ViewFeedbackScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    final ParticipationService participationService = ParticipationService();

    return Scaffold(
      backgroundColor: const Color(0xFF110D27),
      appBar: AppBar(
        title: Text(
          'Feedback: $eventTitle',
          style: const TextStyle(fontSize: 18),
        ),
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
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: participationService.getFeedbackForEvent(eventId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final feedbacks = snapshot.data ?? [];

            if (feedbacks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.rate_review_outlined,
                      color: Colors.white24,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No feedback submitted yet.',
                      style: GoogleFonts.quicksand(color: Colors.white70),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: feedbacks.length,
              itemBuilder: (context, index) {
                final f = feedbacks[index];
                final rating = (f['rating'] ?? 0.0).toDouble();

                return Card(
                  color: const Color(0xFF241B3D),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(
                      color: Color(0xFFBFA8FF),
                      width: 0.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              f['userName'] ?? 'Anonymous',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          f['comment'] ?? '',
                          style: GoogleFonts.quicksand(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            _formatDate(f['submittedAt']),
                            style: GoogleFonts.quicksand(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    return 'Recently';
  }
}
