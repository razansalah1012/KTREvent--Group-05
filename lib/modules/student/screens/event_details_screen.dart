import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../events/models/event_model.dart';
import '../../participation/models/participation_model.dart';
import '../../participation/services/participation_service.dart';
import 'event_registration_screen.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/services/local_notification_service.dart';
import 'apply_as_crew_screen.dart';
import 'package:share_plus/share_plus.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  final String title;
  final String date;
  final String location;
  final String description;
  final String organizerId;
  final String? imageUrl;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    required this.organizerId,
    this.imageUrl,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final ParticipationService _participationService = ParticipationService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0820),
        body: Center(
          child: Text('Not signed in', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        final lang = userSnapshot.data?.data()?['language'] ?? 'en';

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                backgroundColor: Color(0xFF0B0820),
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.data!.exists) {
              return Scaffold(
                backgroundColor: const Color(0xFF0B0820),
                body: Center(
                  child: Text(
                    AppTranslations.get(lang, 'event_not_found'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }

            final event = EventModel.fromFirestore(snapshot.data!);
            final seatsLeft = event.capacity - event.registeredCount;
            final deadline = event.registrationDeadline != null
                ? '${event.registrationDeadline!.day}/${event.registrationDeadline!.month}/${event.registrationDeadline!.year}'
                : null;

            return Scaffold(
              backgroundColor: const Color(0xFF0B0820),
              body: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(event, lang),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildInfoRow(
                            Icons.calendar_today_rounded,
                            '${event.date.day}/${event.date.month}/${event.date.year}',
                            event.startTime ?? '9:00 AM - 6:00 PM',
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.location_on_rounded,
                            event.location,
                            '',
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.person_outline_rounded,
                            event.organizerName ?? 'Organizer',
                            AppTranslations.get(lang, 'organizer'),
                          ),

                          const SizedBox(height: 32),
                          _buildStatsSection(event, seatsLeft, deadline, lang),

                          const SizedBox(height: 32),
                          Text(
                            AppTranslations.get(lang, 'about_this_event'),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.description,
                            style: GoogleFonts.quicksand(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),

                          if (event.whatToExpect != null &&
                              event.whatToExpect!.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            Text(
                              AppTranslations.get(lang, 'what_to_expect'),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...event.whatToExpect!.map(
                              (item) => _buildExpectationItem(item),
                            ),
                          ],

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              bottomSheet: _buildBottomBar(lang, event),
            );
          },
        );
      },
    );
  }

  Widget _buildSliverAppBar(EventModel event, String lang) {
    final status = event.getStatus();
    Color badgeColor = Colors.greenAccent;
    String displayStatus = AppTranslations.get(lang, 'open');

    if (status == 'FULL') {
      badgeColor = Colors.redAccent;
      displayStatus = AppTranslations.get(lang, 'full');
    } else if (status == 'CLOSING SOON') {
      badgeColor = Colors.orangeAccent;
      displayStatus = AppTranslations.get(lang, 'closing_soon');
    } else if (status == 'CLOSED') {
      badgeColor = Colors.white38;
      displayStatus = AppTranslations.get(lang, 'closed');
    } else if (status == 'ONGOING') {
      badgeColor = Colors.blueAccent;
      displayStatus = AppTranslations.get(lang, 'ongoing');
    }

    return SliverAppBar(
      expandedHeight: 250,
      backgroundColor: const Color(0xFF0B0820),
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () {
            Share.share(
              'Check out ${event.title} on ${event.date.day}/${event.date.month}/${event.date.year} at ${event.location}!\n\nJoin me by registering on the RazakEvent app.',
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            event.imageUrl != null && event.imageUrl!.isNotEmpty
                ? Image.network(event.imageUrl!, fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFF2A1E4D),
                    child: const Icon(
                      Icons.event,
                      size: 80,
                      color: Colors.white24,
                    ),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    const Color(0xFF0B0820),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: badgeColor.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  displayStatus,
                  style: GoogleFonts.poppins(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String primary, String secondary) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1533),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFB794FF), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primary,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (secondary.isNotEmpty)
                Text(
                  secondary,
                  style: GoogleFonts.quicksand(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(
    EventModel event,
    int seatsLeft,
    String? deadline,
    String lang,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1E4D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _statItem(
              AppTranslations.get(lang, 'fee'),
              event.fee > 0 ? 'RM${event.fee.toInt()}' : 'FREE',
            ),
          ),
          _statDivider(),
          Expanded(
            child: _statItem(
              AppTranslations.get(lang, 'seats_left'),
              '$seatsLeft/${event.capacity}',
            ),
          ),
          if (deadline != null) ...[
            _statDivider(),
            Expanded(
              child: _statItem(
                AppTranslations.get(lang, 'deadline'),
                deadline,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: const Color(0xFFB794FF),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(height: 30, width: 1, color: Colors.white10);
  }

  Widget _buildExpectationItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFFB794FF),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(String lang, EventModel event) {
    final status = event.getStatus();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0820),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: StreamBuilder<ParticipationModel?>(
        stream: _participationService.getUserParticipation(widget.eventId),
        builder: (context, partSnapshot) {
          final isRegistered =
              partSnapshot.hasData && partSnapshot.data != null;

          if (isRegistered) {
            return Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      AppTranslations.get(lang, 'already_registered'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FutureBuilder<bool>(
                  future: LocalNotificationService().hasReminder(widget.eventId),
                  builder: (context, reminderSnapshot) {
                    final hasReminder = reminderSnapshot.data ?? false;
                    return Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: hasReminder ? const Color(0xFF6C48FF) : const Color(0xFF2A1E4D),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: Icon(
                          hasReminder ? Icons.notifications_active : Icons.notifications_none,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          if (hasReminder) {
                            await LocalNotificationService().cancelEventReminder(widget.eventId);
                          } else {
                            final eventDoc = await FirebaseFirestore.instance.collection('events').doc(widget.eventId).get();
                            if (eventDoc.exists) {
                              final event = EventModel.fromFirestore(eventDoc);
                              await LocalNotificationService().scheduleEventReminder(
                                eventId: event.id!,
                                title: event.title,
                                eventDate: event.date,
                                eventTime: event.startTime ?? '',
                              );
                            }
                          }
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
              ],
            );
          }

          if (status == 'CLOSED') {
            return Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                AppTranslations.get(lang, 'closed').toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                ),
              ),
            );
          }

          return Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: status == 'FULL' ? null : () async {
                      final eventDoc = await FirebaseFirestore.instance
                          .collection('events')
                          .doc(widget.eventId)
                          .get();
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventRegistrationScreen(
                              event: EventModel.fromFirestore(eventDoc),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C48FF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      status == 'FULL' 
                        ? AppTranslations.get(lang, 'full').toUpperCase()
                        : AppTranslations.get(lang, 'register_now'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: status == 'FULL' ? Colors.white38 : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              if (event.crewSlots > 0 && status != 'CLOSED') ...[
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ApplyAsCrewScreen(
                              eventId: widget.eventId,
                              eventTitle: event.title,
                              eventOrganizerId: event.organizerId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A1E4D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: Color(0xFFB794FF)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Apply as Crew',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
