import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../participation/screens/track_participants_screen.dart';
import '../../participation/screens/view_feedback_screen.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import 'create_event_screen.dart';
import '../../reports/screens/create_report_screen.dart';
import 'edit_event_screen.dart';
import '../../community/services/community_service.dart';
import '../../community/screens/manage_members_screen.dart';
import '../../../core/localization/app_translations.dart';

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

  Future<void> _confirmDelete(
    BuildContext context,
    String eventId,
    String lang,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF241B3D),
          title: Text(
            AppTranslations.get(lang, 'delete_event'),
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            AppTranslations.get(lang, 'delete_event_confirm'),
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                AppTranslations.get(lang, 'cancel'),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                AppTranslations.get(lang, 'delete'),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _eventService.deleteEvent(eventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.get(lang, 'event_deleted_success')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0820),
        body: Center(
          child: Text('Not logged in', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        final lang = userSnapshot.data?.data()?['language'] ?? 'en';

        Widget content = StreamBuilder<List<EventModel>>(
          stream: widget.isAdminView
              ? _eventService.getAllEvents()
              : _eventService.getMyEvents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  AppTranslations.get(lang, 'no_events_found'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              );
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
                    side: const BorderSide(
                      color: Color(0xFFB99CFF),
                      width: 0.7,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                        title: Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${event.location} • ${_formatDate(event.date)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        trailing: widget.isAdminView
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: AppTranslations.get(
                                      lang,
                                      'edit_event',
                                    ),
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color(0xFFBE9AF4),
                                    ),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EditEventScreen(event: event),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: AppTranslations.get(
                                      lang,
                                      'delete_event',
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: event.id == null
                                        ? null
                                        : () => _confirmDelete(
                                            context,
                                            event.id!,
                                            lang,
                                          ),
                                  ),
                                ],
                              ),
                      ),

                      if (widget.showManagementButtons) ...[
                        const Divider(color: Colors.white10, height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TrackParticipantsScreen(
                                        eventId: event.id!,
                                        eventTitle: event.title,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.people_outline,
                                  size: 18,
                                ),
                                label: Text(
                                  AppTranslations.get(lang, 'participants'),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFB99CFF),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ViewFeedbackScreen(
                                        eventId: event.id!,
                                        eventTitle: event.title,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.rate_review_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  AppTranslations.get(lang, 'feedback'),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.orangeAccent,
                                ),
                              ),
                              if (!widget.isAdminView)
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CreateReportScreen(event: event),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.upload_file, size: 18),
                                  label: Text(
                                    AppTranslations.get(lang, 'submit_report'),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.greenAccent,
                                  ),
                                ),
                              if (!widget.isAdminView)
                                TextButton.icon(
                                  onPressed: () async {
                                    final user =
                                        FirebaseAuth.instance.currentUser;
                                    if (user == null || event.id == null)
                                      return;

                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (c) => const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFB99CFF),
                                        ),
                                      ),
                                    );

                                    try {
                                      final commService = CommunityService();
                                      final comm = await commService
                                          .getOrCreateCommunity(
                                            event.id!,
                                            event.title,
                                            user.uid,
                                            user.displayName ??
                                                user.email ??
                                                'Leader',
                                          );

                                      if (mounted) {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ManageMembersScreen(
                                              community: comm,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.group_add, size: 18),
                                  label: Text(
                                    AppTranslations.get(lang, 'community'),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF9B6DFF),
                                  ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.get(lang, 'my_events'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateEventScreen(),
                        ),
                      ),
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFFB99CFF),
                      ),
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
            title: Text(
              widget.isAdminView
                  ? AppTranslations.get(lang, 'all_college_events')
                  : AppTranslations.get(lang, 'manage_my_events'),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF241B3D),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          floatingActionButton: widget.isAdminView
              ? null
              : FloatingActionButton(
                  backgroundColor: const Color(0xFF9B6DFF),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateEventScreen(),
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF110D27),
                  Color(0xFF1E1533),
                  Color(0xFF2A2147),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: content,
          ),
        );
      },
    );
  }
}
