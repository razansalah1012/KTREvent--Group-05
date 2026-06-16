import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';
import 'community_chat_screen.dart';
import '../../../core/localization/app_translations.dart';

class CommunityListScreen extends StatelessWidget {
  const CommunityListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0820),
        body: Center(
          child: Text('Not logged in', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final commService = CommunityService();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        final lang = userSnapshot.data?.data()?['language'] ?? 'en';

        return Scaffold(
          backgroundColor: const Color(0xFF0D0820),
          appBar: AppBar(
            title: Text(
              AppTranslations.get(lang, 'my_event_communities'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF241B3D),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: StreamBuilder<List<EventCommunityModel>>(
            stream: commService.getMyCommunities(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFB99CFF)),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '${AppTranslations.get(lang, 'error')}${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }

              final communities = snapshot.data ?? [];
              if (communities.isEmpty) {
                return Center(
                  child: Text(
                    AppTranslations.get(lang, 'no_communities_yet'),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: communities.length,
                itemBuilder: (context, index) {
                  final comm = communities[index];
                  final isLeader = comm.leaderId == user.uid;

                  return Card(
                    color: const Color(0xFF2B1D44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: const Color(0xFFB99CFF).withOpacity(0.3),
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: const Color(
                          0xFF9B6DFF,
                        ).withOpacity(0.2),
                        child: const Icon(
                          Icons.groups,
                          color: Color(0xFFB99CFF),
                        ),
                      ),
                      title: Text(
                        comm.eventTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        isLeader
                            ? AppTranslations.get(lang, 'leader')
                            : AppTranslations.get(lang, 'organizer'),
                        style: TextStyle(
                          color: isLeader ? Colors.greenAccent : Colors.white70,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white54,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CommunityChatScreen(community: comm),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
