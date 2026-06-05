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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userRole = data['role'] ?? 'student';
          _postedByName = data['fullname'] ?? data['fullName'] ?? data['name'] ?? 'Organizer';
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', whereIn: [user.uid, 'all'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error loading alerts.', style: GoogleFonts.quicksand(color: Colors.redAccent)),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, color: Colors.white24, size: 64),
                  const SizedBox(height: 16),
                  Text('No notifications yet.', style: GoogleFonts.quicksand(color: Colors.white70)),
                ],
              ),
            );
          }

          // Sort manually in memory to handle combined data without complex indexing
          final notifications = docs.toList();
          notifications.sort((a, b) {
            final aTime = _parseDate((a.data() as Map<String, dynamic>)['createdAt']);
            final bTime = _parseDate((b.data() as Map<String, dynamic>)['createdAt']);
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;
              final isRead = data['isRead'] ?? false;
              final type = data['type']?.toString() ?? '';
              final isAnnouncement = data['userId'] == 'all';

              IconData icon = Icons.notifications_active_outlined;
              Color iconColor = Colors.amberAccent;

              if (isAnnouncement) {
                icon = Icons.campaign_rounded;
                iconColor = Colors.lightBlueAccent;
              } else {
                switch (type) {
                  case 'crew_acceptance':
                    icon = Icons.check_circle_outline;
                    iconColor = Colors.greenAccent;
                    break;
                  case 'crew_rejection':
                    icon = Icons.cancel_outlined;
                    iconColor = Colors.redAccent;
                    break;
                  case 'new_crew_application':
                    icon = Icons.person_add_alt_1_outlined;
                    iconColor = Colors.blueAccent;
                    break;
                  case 'crew_application_submitted':
                    icon = Icons.assignment_turned_in_outlined;
                    iconColor = Colors.tealAccent;
                    break;
                }
              }

              return GestureDetector(
                onTap: () {
                  if (!isAnnouncement && !isRead) {
                    FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({'isRead': true});
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isAnnouncement || isRead) ? const Color(0xFF1E1533) : const Color(0xFF2B2040),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (isAnnouncement || isRead) ? Colors.white10 : const Color(0xFFBFA8FF),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: iconColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['title'] ?? 'Notification',
                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (isAnnouncement)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.lightBlueAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('ANNOUNCEMENT', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(data['message'] ?? '', style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(_formatTimestamp(data['createdAt']), style: GoogleFonts.quicksand(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (!isAnnouncement && !isRead)
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF9B6DFF), shape: BoxShape.circle)),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
        title: Text('Broadcast Announcement', style: GoogleFonts.poppins(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Message', labelStyle: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('notifications').add({
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9B6DFF)),
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
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
