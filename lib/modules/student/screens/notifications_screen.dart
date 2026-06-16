import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _userRole = 'student';
  String _postedByName = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userRole = data['role'] ?? 'student';
          _postedByName =
              data['fullname'] ??
              data['fullName'] ??
              data['name'] ??
              'Organizer';
        });
      }
    }
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  bool _matchesFilter(Map<String, dynamic> data, String filter) {
    if (filter == 'All') return true;

    final type = data['type']?.toString().toLowerCase() ?? '';
    final title = data['title']?.toString().toLowerCase() ?? '';
    final userId = data['userId']?.toString() ?? '';

    final isAnnouncement = userId == 'all' || type == 'announcement';
    final isRequest =
        type.contains('request') ||
        type.contains('application') ||
        type.contains('crew') ||
        type.contains('accept') ||
        type.contains('reject') ||
        title.contains('request') ||
        title.contains('application');

    if (filter == 'Announcements') {
      return isAnnouncement;
    } else if (filter == 'Requests') {
      return isRequest && !isAnnouncement;
    } else if (filter == 'Chats') {
      return type == 'chat_message';
    } else if (filter == 'System') {
      return !isAnnouncement && !isRequest && type != 'chat_message';
    }
    return true;
  }

  Map<String, List<QueryDocumentSnapshot>> _groupNotifications(
    List<QueryDocumentSnapshot> notifications,
  ) {
    final Map<String, List<QueryDocumentSnapshot>> groups = {
      'Today': [],
      'This Week': [],
      'Earlier': [],
    };

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 7));

    for (final doc in notifications) {
      final data = doc.data() as Map<String, dynamic>;
      final date = _parseDate(data['createdAt']);

      if (date.isAfter(todayStart) || date.isAtSameMomentAs(todayStart)) {
        groups['Today']!.add(doc);
      } else if (date.isAfter(weekStart)) {
        groups['This Week']!.add(doc);
      } else {
        groups['Earlier']!.add(doc);
      }
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _userRole == 'club_member'
          ? FloatingActionButton(
              onPressed: () => _showAnnouncementDialog(context),
              backgroundColor: const Color(0xFF9B6DFF),
              child: const Icon(Icons.add_comment_rounded, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 4.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Alerts',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8A5CFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.filter_list_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 20.0,
              ),
              child: Text(
                'Stay updated with important notifications',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: const Color(0xFFB8AFCB),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF241B3D).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    _buildFilterTab("All"),
                    _buildFilterTab("Requests"),
                    _buildFilterTab("Announcements"),
                    _buildFilterTab("Chats"),
                    _buildFilterTab("System"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', whereIn: [user.uid, 'all'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8A5CFF),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Error loading alerts.',
                          style: GoogleFonts.quicksand(color: Colors.redAccent),
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            color: Colors.white24,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet.',
                            style: GoogleFonts.quicksand(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  }

                  final sortedDocs = docs.toList();
                  sortedDocs.sort((a, b) {
                    final aTime = _parseDate(
                      (a.data() as Map<String, dynamic>)['createdAt'],
                    );
                    final bTime = _parseDate(
                      (b.data() as Map<String, dynamic>)['createdAt'],
                    );
                    return bTime.compareTo(aTime);
                  });

                  final filteredDocs = sortedDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _matchesFilter(data, _selectedFilter);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_off_outlined,
                            color: Colors.white24,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No $_selectedFilter notifications.',
                            style: GoogleFonts.quicksand(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  }

                  final grouped = _groupNotifications(filteredDocs);

                  final List<Widget> listItems = [];

                  if (grouped['Today']!.isNotEmpty) {
                    listItems.add(
                      _buildSectionHeader('Today', grouped['Today']!.length),
                    );
                    for (var doc in grouped['Today']!) {
                      listItems.add(_buildNotificationCard(doc));
                    }
                  }
                  if (grouped['This Week']!.isNotEmpty) {
                    listItems.add(
                      _buildSectionHeader(
                        'This Week',
                        grouped['This Week']!.length,
                      ),
                    );
                    for (var doc in grouped['This Week']!) {
                      listItems.add(_buildNotificationCard(doc));
                    }
                  }
                  if (grouped['Earlier']!.isNotEmpty) {
                    listItems.add(
                      _buildSectionHeader(
                        'Earlier',
                        grouped['Earlier']!.length,
                      ),
                    );
                    for (var doc in grouped['Earlier']!) {
                      listItems.add(_buildNotificationCard(doc));
                    }
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    children: listItems,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String title) {
    final isSelected = _selectedFilter == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8A5CFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFFB8AFCB),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    IconData iconData;
    switch (title) {
      case 'Today':
        iconData = Icons.calendar_today_outlined;
        break;
      case 'This Week':
        iconData = Icons.star_outline_rounded;
        break;
      case 'Earlier':
      default:
        iconData = Icons.access_time_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(iconData, color: const Color(0xFF8A5CFF), size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8A5CFF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: Colors.white10)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF241B3D),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFB8AFCB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final notificationId = doc.id;
    final isRead = data['isRead'] ?? false;
    final type = data['type']?.toString() ?? '';
    final isAnnouncement = data['userId'] == 'all';

    IconData iconData = Icons.notifications_active_outlined;
    Color iconColor = const Color(0xFF8A5CFF);
    Color boxColor = const Color(0xFF8A5CFF).withOpacity(0.15);

    if (isAnnouncement) {
      iconData = Icons.campaign_rounded;
      iconColor = Colors.lightBlueAccent;
      boxColor = Colors.lightBlueAccent.withOpacity(0.15);
    } else {
      switch (type) {
        case 'crew_acceptance':
        case 'crew_application_submitted':
          iconData = Icons.assignment_turned_in_rounded;
          iconColor = const Color(0xFF4CAF50);
          boxColor = const Color(0xFF4CAF50).withOpacity(0.15);
          break;
        case 'crew_rejection':
          iconData = Icons.cancel_outlined;
          iconColor = Colors.redAccent;
          boxColor = Colors.redAccent.withOpacity(0.15);
          break;
        case 'new_crew_application':
          iconData = Icons.person_add_alt_1_outlined;
          iconColor = Colors.blueAccent;
          boxColor = Colors.blueAccent.withOpacity(0.15);
          break;
        case 'chat_message':
          iconData = Icons.chat_bubble_outline_rounded;
          iconColor = const Color(0xFFE040FB);
          boxColor = const Color(0xFFE040FB).withOpacity(0.15);
          break;
        case 'equipment_request_update':
        default:
          iconData = Icons.notifications_active_rounded;
          iconColor = const Color(0xFFFFB300);
          boxColor = const Color(0xFFFFB300).withOpacity(0.15);
          break;
      }
    }

    final showChevron = type != 'crew_application_submitted';

    return GestureDetector(
      onTap: () {
        if (!isAnnouncement && !isRead) {
          FirebaseFirestore.instance
              .collection('notifications')
              .doc(notificationId)
              .update({'isRead': true});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF241B3D),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          data['title'] ?? 'Notification',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isAnnouncement) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.lightBlueAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ANNOUNCEMENT',
                            style: GoogleFonts.poppins(
                              color: Colors.lightBlueAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['message'] ?? '',
                    style: GoogleFonts.quicksand(
                      color: const Color(0xFFB8AFCB),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_outlined,
                        color: Colors.white38,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(data['createdAt']),
                        style: GoogleFonts.quicksand(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB8AFCB),
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241B3D),
        title: Text(
          'Broadcast Announcement',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  messageController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('notifications')
                    .add({
                      'userId': 'all',
                      'title': titleController.text.trim(),
                      'message': messageController.text.trim(),
                      'type': 'announcement',
                      'postedBy': _postedByName,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B6DFF),
            ),
            child: const Text('Broadcast'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    final date = _parseDate(timestamp);
    if (date.year == 2000) return 'Recently';
    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
