import 'package:flutter/material.dart';
import '../../participation/screens/track_participants_screen.dart';
import '../../participation/screens/view_feedback_screen.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import 'create_event_screen.dart';
import 'edit_event_screen.dart';

class ManageEventsScreen extends StatefulWidget {
  final bool isTab;
  final bool showManagementButtons; 
  final bool isAdminView;

  const ManageEventsScreen({
    super.key,
    this.isTab = false,
    this.showManagementButtons = true,
    this.isAdminView = false,
  });

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  final EventService _eventService = EventService();

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }

  Future<void> _confirmDelete(BuildContext context, String eventId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF241B3D),
          title: const Text('Delete Event', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to delete this event? This action cannot be undone.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _eventService.deleteEvent(eventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting event: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = StreamBuilder<List<EventModel>>(
      stream: widget.isAdminView ? _eventService.getAllEvents() : _eventService.getMyEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No events found.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)));
        }

        final events = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];

            return Card(
              color: const Color(0xFF241B3D),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFB99CFF), width: 0.7),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                    title: Text(event.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('${event.location} • ${_formatDate(event.date)}', style: const TextStyle(color: Colors.white70)),
                    ),
                    trailing: widget.isAdminView ? null : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit event',
                          icon: const Icon(Icons.edit, color: Color(0xFFBE9AF4)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditEventScreen(event: event))),
                        ),
                        IconButton(
                          tooltip: 'Delete event',
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: event.id == null ? null : () => _confirmDelete(context, event.id!),
                        ),
                      ],
                    ),
                  ),
                  
                  if (widget.showManagementButtons) ...[
                    const Divider(color: Colors.white10, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => TrackParticipantsScreen(eventId: event.id!, eventTitle: event.title)));
                            },
                            icon: const Icon(Icons.people_outline, size: 18),
                            label: const Text('Participants'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB99CFF)),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ViewFeedbackScreen(eventId: event.id!, eventTitle: event.title)));
                            },
                            icon: const Icon(Icons.rate_review_outlined, size: 18),
                            label: const Text('Feedback'),
                            style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );

    if (widget.isTab) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Events', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen())),
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFFB99CFF)),
                ),
              ],
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),
      appBar: AppBar(
        title: Text(widget.isAdminView ? 'All College Events' : 'Manage My Events', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF241B3D),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: widget.isAdminView ? null : FloatingActionButton(
        backgroundColor: const Color(0xFF9B6DFF),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF110D27), Color(0xFF1E1533), Color(0xFF2A2147)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: content,
      ),
    );
  }
}
