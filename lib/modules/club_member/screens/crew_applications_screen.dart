import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class CrewApplicationsScreen extends StatefulWidget {
  final bool isTab;
  const CrewApplicationsScreen({super.key, this.isTab = false});

  @override
  State<CrewApplicationsScreen> createState() => _CrewApplicationsScreenState();
}

class _CrewApplicationsScreenState extends State<CrewApplicationsScreen> {
  String _selectedStatus = 'Pending';

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

    if (user == null) {
      return Center(
        child: Text(
          'User not logged in',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    Widget content = Column(
      children: [
        _buildFilterChips(user.uid),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('crewApplications')
                .where('organizerId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF9B6DFF)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = (data['status'] ?? '').toString().toLowerCase();
                return status == _selectedStatus.toLowerCase();
              }).toList();

              filteredDocs.sort((a, b) {
                final aTime = _parseDate((a.data() as Map)['createdAt']);
                final bTime = _parseDate((b.data() as Map)['createdAt']);
                return bTime.compareTo(aTime);
              });

              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No applications yet.',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Applications for your events will appear here once students apply.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Text(
                    'No $_selectedStatus applications found.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final app =
                      filteredDocs[index].data() as Map<String, dynamic>;
                  final appId = filteredDocs[index].id;
                  return _buildApplicationCard(appId, app);
                },
              );
            },
          ),
        ),
      ],
    );

    if (widget.isTab) return content;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),
      appBar: AppBar(
        title: const Text('Crew Applications'),
        backgroundColor: const Color(0xFF261A3D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: content,
    );
  }

  Widget _buildFilterChips(String myUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('crewApplications')
          .where('organizerId', isEqualTo: myUid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        int pCount = docs
            .where(
              (d) =>
                  (d.data() as Map)['status']?.toString().toLowerCase() ==
                  'pending',
            )
            .length;
        int aCount = docs
            .where(
              (d) =>
                  (d.data() as Map)['status']?.toString().toLowerCase() ==
                  'accepted',
            )
            .length;
        int rCount = docs
            .where(
              (d) =>
                  (d.data() as Map)['status']?.toString().toLowerCase() ==
                  'rejected',
            )
            .length;

        final statuses = [
          {'label': 'Pending', 'count': pCount},
          {'label': 'Accepted', 'count': aCount},
          {'label': 'Rejected', 'count': rCount},
        ];

        return Container(
          width: double.infinity,
          height: 50,
          margin: const EdgeInsets.only(top: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: statuses.length,
            itemBuilder: (context, index) {
              final label = statuses[index]['label'] as String;
              final count = statuses[index]['count'] as int;
              final isSelected = _selectedStatus == label;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ChoiceChip(
                  label: Text('$label ($count)'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedStatus = label);
                  },
                  backgroundColor: const Color(0xFF261A3D),
                  selectedColor: const Color(0xFF9B6DFF),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildApplicationCard(String appId, Map<String, dynamic> app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B1D44),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB99CFF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  app['userName'] ?? 'Unknown Student',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _statusIndicator(app['status']?.toString() ?? 'Pending'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Event: ${app['eventTitle'] ?? 'Unnamed Event'}',
            style: const TextStyle(
              color: Color(0xFFB99CFF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(color: Colors.white12, height: 24),
          _infoRow(Icons.psychology, 'Skills', app['skills']),
          const SizedBox(height: 8),
          _infoRow(Icons.chat_bubble_outline, 'Reason', app['reason']),
          const SizedBox(height: 8),
          _infoRow(Icons.phone, 'Contact', app['contactNo']),

          if (app['status']?.toString().toLowerCase() == 'rejected' &&
              app['rejectionReason'] != null) ...[
            const SizedBox(height: 8),
            _infoRow(
              Icons.error_outline,
              'Rejection Reason',
              app['rejectionReason'],
              color: Colors.redAccent,
            ),
          ],

          if (app['status']?.toString().toLowerCase() == 'pending') ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReject(appId, app),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAccept(appId, app),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String? value, {
    Color color = Colors.white70,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.6)),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.quicksand(color: color, fontSize: 14),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value ?? '-'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusIndicator(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.redAccent;
        break;
      default:
        color = Colors.orangeAccent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _handleAccept(String appId, Map<String, dynamic> app) async {
    try {
      final eventId = app['eventId'];
      if (eventId == null) throw Exception('Event ID is missing');

      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();

      if (!eventDoc.exists) {
        throw Exception('Event no longer exists.');
      }

      final eventData = eventDoc.data()!;
      final int crewSlots = eventData['crewSlots'] ?? 0;
      final int acceptedCount = eventData['acceptedCrewCount'] ?? 0;

      if (crewSlots > 0 && acceptedCount >= crewSlots) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No more crew slots available for this event.'),
          ),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('crewApplications')
          .doc(appId)
          .update({
            'status': 'Accepted',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance.collection('events').doc(eventId).update(
        {'acceptedCrewCount': FieldValue.increment(1)},
      );

      await FirebaseFirestore.instance.collection('eventCrewMembers').add({
        'applicationId': appId,
        'eventId': eventId,
        'userId': app['userId'],
        'userName': app['userName'],
        'acceptedAt': FieldValue.serverTimestamp(),
        'role': 'Crew',
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': app['userId'],
        'title': 'Crew Application Accepted',
        'message':
            'Congratulations! You have been accepted as crew for "${app['eventTitle'] ?? 'the event'}".',
        'type': 'crew_acceptance',
        'eventId': eventId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Application accepted!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleReject(String appId, Map<String, dynamic> app) async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2B1D44),
        title: const Text(
          'Reject Application',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason (optional)',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final rejectionReason = reasonController.text.trim().isEmpty
            ? 'Not specified'
            : reasonController.text.trim();

        await FirebaseFirestore.instance
            .collection('crewApplications')
            .doc(appId)
            .update({
              'status': 'Rejected',
              'rejectionReason': rejectionReason,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': app['userId'],
          'title': 'Crew Application Rejected',
          'message':
              'Your application for "${app['eventTitle'] ?? 'the event'}" was rejected. Reason: $rejectionReason',
          'type': 'crew_rejection',
          'eventId': app['eventId'],
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Application rejected.')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
