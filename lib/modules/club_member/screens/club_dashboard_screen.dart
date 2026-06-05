import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../events/screens/manage_events_screen.dart';
import '../../student/screens/notifications_screen.dart';
import 'submit_proposal_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'proposal_details_screen.dart';
import 'edit_club_profile_screen.dart';
import 'crew_applications_screen.dart';

class ClubDashboardScreen extends StatefulWidget {
  const ClubDashboardScreen({super.key});

  @override
  State<ClubDashboardScreen> createState() => _ClubDashboardScreenState();
}

class _ClubDashboardScreenState extends State<ClubDashboardScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  const Text(
                    'KTR Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B1D44),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFFB99CFF),
                      width: 2,
                    ),
                  ),
                  child: _buildPageContent(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        backgroundColor: const Color(0xFF261A3D),
        selectedItemColor: const Color(0xFF9B6DFF),
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Proposals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            label: 'Team',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildPageContent() {
    if (selectedIndex == 0) return _buildProposalsPage();
    if (selectedIndex == 1) return const ManageEventsScreen(isTab: true);
    if (selectedIndex == 2) return const NotificationsScreen();
    if (selectedIndex == 3) return _buildTeamManagementPage();
    return _buildProfilePage();
  }

  Widget _buildProposalsPage() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('No logged in user found.', style: TextStyle(color: Colors.white70)),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Proposals',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubmitProposalScreen()),
                );
              },
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFFB99CFF)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('proposals')
                .where('submittedBy', isEqualTo: currentUser.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'You have not submitted any proposals yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                );
              }

              final proposals = snapshot.data!.docs;

              return ListView.builder(
                itemCount: proposals.length,
                itemBuilder: (context, index) {
                  final data = proposals[index].data() as Map<String, dynamic>;
                  final programName = data['programName'] ?? 'Untitled Proposal';
                  final status = data['status'] ?? 'pending';
                  final venue = data['venue'] ?? '-';

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProposalDetailsScreen(
                            proposalId: proposals[index].id,
                            proposalData: data,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A285A),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFB99CFF).withOpacity(0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(programName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Venue: $venue', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 10),
                          _buildStatusBadge(status),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orangeAccent;
    if (status.toLowerCase() == 'approved') color = Colors.greenAccent;
    if (status.toLowerCase() == 'rejected') color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildTeamManagementPage() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text('Not logged in', style: TextStyle(color: Colors.white70)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Team Management', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrewApplicationsScreen())),
              icon: const Icon(Icons.assignment_ind_outlined, size: 18, color: Color(0xFFB99CFF)),
              label: const Text('Applications', style: TextStyle(color: Color(0xFFB99CFF), fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).collection('teamMembers').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final members = snapshot.data?.docs ?? [];
              if (members.isEmpty) return const Center(child: Text('No team members added yet.', style: TextStyle(color: Colors.white70)));

              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index].data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A285A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFB99CFF).withOpacity(0.5)),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFF9B6DFF), child: Icon(Icons.person, color: Colors.white)),
                      title: Text(member['name'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(member['position'] ?? '-', style: const TextStyle(color: Color(0xFFB99CFF))),
                      trailing: IconButton(
                        onPressed: () => members[index].reference.delete(),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePage() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return const Center(child: Text('Not logged in', style: TextStyle(color: Colors.white70)));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data?.data() as Map<String, dynamic>?;

        return Column(
          children: [
            const CircleAvatar(radius: 40, backgroundColor: Color(0xFF9B6DFF), child: Icon(Icons.person, color: Colors.white, size: 40)),
            const SizedBox(height: 16),
            Text(data?['fullname'] ?? data?['name'] ?? 'Club Member', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(data?['email'] ?? currentUser.email ?? '', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditClubProfileScreen())),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9B6DFF)),
              child: const Text('Edit Profile'),
            ),
          ],
        );
      },
    );
  }
}
