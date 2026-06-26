import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razakevent/core/constants/app_colors.dart';
import 'package:razakevent/modules/student/widgets/event_ticket_card.dart';
import 'event_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/localization/app_translations.dart';
import '../../events/models/event_model.dart';

class ExploreEventsScreen extends StatefulWidget {
  const ExploreEventsScreen({super.key});

  @override
  State<ExploreEventsScreen> createState() => _ExploreEventsScreenState();
}

class _ExploreEventsScreenState extends State<ExploreEventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return 'Date TBD';
    DateTime? date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is DateTime) {
      date = rawDate;
    }
    if (date != null) {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
    return 'Date TBD';
  }

  void _showFilterBottomSheet(String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.get(lang, 'filter_by_status'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 10,
                    children: ['All', 'OPEN', 'CLOSED', 'ONGOING'].map((
                      status,
                    ) {
                      final isSelected = _selectedStatus == status;
                      String displayStatus = status;
                      if (status == 'All')
                        displayStatus = AppTranslations.get(lang, 'all');
                      if (status == 'OPEN')
                        displayStatus = AppTranslations.get(lang, 'open');
                      if (status == 'CLOSED')
                        displayStatus = AppTranslations.get(lang, 'closed');
                      if (status == 'ONGOING')
                        displayStatus = AppTranslations.get(lang, 'ongoing');

                      return ChoiceChip(
                        label: Text(
                          displayStatus,
                          style: GoogleFonts.quicksand(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.background,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedStatus = status;
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        AppTranslations.get(lang, 'apply_filters'),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Center(
        child: Text('Not signed in', style: TextStyle(color: Colors.white)),
      );

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final lang = data['language'] ?? 'en';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'KTR',
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: 'Event',
                              style: GoogleFonts.poppins(
                                color: Colors.redAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.get(lang, 'explore_events'),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppTranslations.get(lang, 'discover_events'),
                        style: GoogleFonts.quicksand(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.quicksand(color: Colors.white),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: AppTranslations.get(
                                lang,
                                'search_events',
                              ),
                              hintStyle: GoogleFonts.quicksand(
                                color: Colors.white54,
                              ),
                              border: InputBorder.none,
                              icon: const Icon(
                                Icons.search,
                                color: Colors.white54,
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.white54,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: () => _showFilterBottomSheet(lang),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.tune,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppTranslations.get(lang, 'filter'),
                                style: GoogleFonts.poppins(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
                  child: Text(
                    AppTranslations.get(lang, 'upcoming_events'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('events')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Something went wrong',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            AppTranslations.get(lang, 'no_events_found'),
                            style: GoogleFonts.quicksand(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      final events = snapshot.data!.docs
                          .map((doc) {
                            return EventModel.fromFirestore(doc);
                          })
                          .where((event) {
                            String status = 'OPEN';
                            final registeredCount = event.registeredCount;
                            if (registeredCount >= event.capacity)
                              status = 'FULL';
                            if (_selectedStatus != 'All' &&
                                status != _selectedStatus) {
                              return false;
                            }

                            if (_searchQuery.isNotEmpty) {
                              return event.title.toLowerCase().contains(
                                    _searchQuery,
                                  ) ||
                                  event.location.toLowerCase().contains(
                                    _searchQuery,
                                  ) ||
                                  event.description.toLowerCase().contains(
                                    _searchQuery,
                                  );
                            }

                            return true;
                          })
                          .toList();

                      if (events.isEmpty) {
                        return Center(
                          child: Text(
                            AppTranslations.get(lang, 'no_events_found'),
                            style: GoogleFonts.quicksand(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          await Future.delayed(const Duration(seconds: 1));
                        },
                        color: AppColors.primary,
                        backgroundColor: AppColors.card,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            String status = 'OPEN';
                            if (event.registeredCount >= event.capacity) {
                              status = 'FULL';
                            } else if (event.capacity - event.registeredCount <=
                                5) {
                              status = 'CLOSING SOON';
                            }

                            return EventTicketCard(
                              title: event.title,
                              date: _formatDate(event.date),
                              description: event.description,
                              imageUrl: event.imageUrl,
                              location: event.location,
                              status: status,
                              lang: lang,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EventDetailsScreen(
                                    eventId: event.id!,
                                    title: event.title,
                                    date: _formatDate(event.date),
                                    location: event.location,
                                    description: event.description,
                                    organizerId: event.organizerId,
                                    imageUrl: event.imageUrl,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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
}
