import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../participation/models/participation_model.dart';
import '../../participation/services/participation_service.dart';
import 'digital_ticket_screen.dart';
import '../widgets/event_ticket_card.dart';
import '../../../core/localization/app_translations.dart';

class BookedEventsScreen extends StatefulWidget {
  const BookedEventsScreen({super.key});

  @override
  State<BookedEventsScreen> createState() => _BookedEventsScreenState();
}

class _BookedEventsScreenState extends State<BookedEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ParticipationService _participationService = ParticipationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

        return Scaffold(
          backgroundColor: const Color(0xFF0B0820),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.get(lang, 'my_bookings'),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppTranslations.get(lang, 'view_manage_bookings'),
                              style: GoogleFonts.quicksand(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0820),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF5B3DE6)),
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTabBar(lang),
                Expanded(
                  child: StreamBuilder<List<ParticipationModel>>(
                    stream: _participationService.getUserParticipations(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6C48FF),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _buildErrorWidget(
                          snapshot.error.toString(),
                          lang,
                        );
                      }

                      final participations = snapshot.data ?? [];

                      if (participations.isEmpty) {
                        return _buildEmptyWidget(lang);
                      }

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildEventList(participations, 'all', lang),
                          _buildEventList(participations, 'upcoming', lang),
                          _buildEventList(participations, 'history', lang),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar(String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF130E26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF5B3DE6),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.grid_view_rounded, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppTranslations.get(lang, 'all'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month_rounded, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppTranslations.get(lang, 'upcoming'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_rounded, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppTranslations.get(lang, 'history'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(
    List<ParticipationModel> participations,
    String category,
    String lang,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: participations.length,
      itemBuilder: (context, index) {
        final p = participations[index];

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('events')
              .doc(p.eventId)
              .get(),
          builder: (context, eventSnapshot) {
            if (eventSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingPlaceholder();
            }

            final eventData =
                eventSnapshot.data?.data() as Map<String, dynamic>?;
            if (eventData == null) return const SizedBox.shrink();

            final dateTs = eventData['date'] as Timestamp?;
            final date = dateTs?.toDate();
            final now = DateTime.now();

            if (category == 'upcoming') {
              if (date != null &&
                  date.isBefore(DateTime(now.year, now.month, now.day)))
                return const SizedBox.shrink();
            } else if (category == 'history') {
              if (date != null &&
                  date.isAfter(DateTime(now.year, now.month, now.day)))
                return const SizedBox.shrink();
            }

            final months = [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec',
            ];
            final formattedDate = date != null
                ? '${date.day} ${months[date.month - 1]} ${date.year}'
                : 'TBD';

            return EventTicketCard(
              title: p.eventTitle,
              date: formattedDate,
              description: '${AppTranslations.get(lang, 'status')}${p.status}',
              imageUrl: eventData['imageUrl'] as String?,
              location: eventData['location'] as String?,
              status: p.status.toUpperCase() == 'REGISTERED'
                  ? 'OPEN'
                  : p.status.toUpperCase(),
              lang: lang,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DigitalTicketScreen(
                      participation: p,
                      eventLocation: eventData['location'] ?? 'TBD',
                      eventImageUrl: eventData['imageUrl'] as String? ?? '',
                      eventDate: formattedDate,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      height: 140,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1E4D).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  Widget _buildErrorWidget(String error, String lang) {
    return Center(
      child: Text(
        AppTranslations.get(lang, 'failed_load_registrations'),
        style: GoogleFonts.quicksand(color: Colors.white38),
      ),
    );
  }

  Widget _buildEmptyWidget(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.confirmation_num_outlined,
            color: Colors.white10,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            AppTranslations.get(lang, 'no_bookings_found'),
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
