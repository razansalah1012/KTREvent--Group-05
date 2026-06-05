import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../participation/models/participation_model.dart';
import '../../participation/services/participation_service.dart';
import 'apply_as_crew_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  final String title;
  final String date;
  final String location;
  final String description;
  final String organizerId;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    required this.organizerId,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final ParticipationService _participationService = ParticipationService();
  bool _isRegistering = false;

  Future<void> _handleRegistration() async {
    setState(() => _isRegistering = true);
    try {
      await _participationService.registerForEvent(widget.eventId, widget.title);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF110D27),
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: const Color(0xFF241B3D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('events').doc(widget.eventId).snapshots(),
        builder: (context, snapshot) {
          int slots = 0;
          int accepted = 0;
          String deadlineStr = 'No deadline set';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            slots = data['crewSlots'] ?? 0;
            accepted = data['acceptedCrewCount'] ?? 0;
            if (data['crewDeadline'] != null) {
              final Timestamp ts = data['crewDeadline'];
              final d = ts.toDate();
              deadlineStr = '${d.day}/${d.month}/${d.year}';
            }
          }

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF241B3D),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFBFA8FF), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7E57C2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 38),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 18),
                    _detailRow(icon: Icons.calendar_month_rounded, label: 'Date', value: widget.date),
                    const SizedBox(height: 12),
                    _detailRow(icon: Icons.location_on_rounded, label: 'Location', value: widget.location),
                    const SizedBox(height: 12),
                    _detailRow(
                      icon: Icons.group_outlined,
                      label: 'Crew Slots',
                      value: slots > 0 ? '${slots - accepted} remaining (out of $slots)' : 'No limit',
                    ),
                    const SizedBox(height: 12),
                    _detailRow(icon: Icons.timer_outlined, label: 'Crew Application Deadline', value: deadlineStr),
                    const SizedBox(height: 24),
                    Text(
                      'Description',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 30),
                    
                    StreamBuilder<ParticipationModel?>(
                      stream: _participationService.getUserParticipation(widget.eventId),
                      builder: (context, partSnapshot) {
                        final isRegistered = partSnapshot.hasData && partSnapshot.data != null;
                        
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isRegistered || _isRegistering ? null : _handleRegistration,
                                icon: isRegistered 
                                  ? const Icon(Icons.check_circle_outline)
                                  : (_isRegistering ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.confirmation_number_rounded)),
                                label: Text(isRegistered ? 'Registered' : 'Register for Event'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isRegistered ? Colors.green.shade700 : const Color(0xFF9B6DFF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            if (isRegistered) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Status: ${partSnapshot.data!.status}',
                                style: GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              if (partSnapshot.data!.status == 'Attended' && !partSnapshot.data!.feedbackSubmitted) ...[
                                const SizedBox(height: 12),
                                _buildFeedbackButton(partSnapshot.data!.id!),
                              ] else if (partSnapshot.data!.feedbackSubmitted) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Feedback submitted. Thank you!',
                                  style: GoogleFonts.quicksand(color: Colors.greenAccent, fontSize: 13),
                                ),
                              ]
                            ],
                          ],
                        );
                      }
                    ),
                    
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ApplyAsCrewScreen(
                                eventId: widget.eventId,
                                eventTitle: widget.title,
                                eventOrganizerId: widget.organizerId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.group_add_rounded),
                        label: const Text('Apply as Crew'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFBFA8FF),
                          side: const BorderSide(color: Color(0xFFBFA8FF)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedbackButton(String participationId) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showFeedbackDialog(participationId),
        icon: const Icon(Icons.rate_review_rounded),
        label: const Text('Submit Feedback'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade800,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  void _showFeedbackDialog(String participationId) {
    final TextEditingController commentController = TextEditingController();
    double rating = 5.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF241B3D),
          title: Text('Event Feedback', style: GoogleFonts.poppins(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How was the event?', style: GoogleFonts.quicksand(color: Colors.white70)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => rating = index + 1.0),
                )),
              ),
              TextField(
                controller: commentController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Share your thoughts...',
                  hintStyle: TextStyle(color: Colors.white30),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                await _participationService.submitFeedback(
                  participationId, 
                  commentController.text, 
                  rating
                );
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9B6DFF)),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1533),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFBFA8FF), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 3),
                Text(value, style: GoogleFonts.quicksand(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
