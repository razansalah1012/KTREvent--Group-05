import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';
import '../../../core/localization/app_translations.dart';

class ManageMembersScreen extends StatefulWidget {
  final EventCommunityModel community;

  const ManageMembersScreen({super.key, required this.community});

  @override
  State<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  final _emailController = TextEditingController();
  final _commService = CommunityService();
  bool _isSearching = false;
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _lang = doc.data()?['language'] ?? 'en';
        });
      }
    }
  }

  Future<void> _addMemberByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (userSnap.docs.isEmpty) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppTranslations.get(_lang, 'user_not_found')),
            ),
          );
        return;
      }

      final userData = userSnap.docs.first.data();
      final userId = userSnap.docs.first.id;
      final userName = userData['name'] ?? userData['fullName'] ?? 'User';

      await _commService.addMember(
        communityId: widget.community.id!,
        eventId: widget.community.eventId,
        userId: userId,
        userName: userName,
        role: AppTranslations.get(_lang, 'organizer'),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$userName${AppTranslations.get(_lang, 'added_as_organizer')}',
            ),
          ),
        );
        _emailController.clear();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppTranslations.get(_lang, 'error')}$e')),
        );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),
      appBar: AppBar(
        title: Text(
          AppTranslations.get(_lang, 'manage_organizers'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF241B3D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF241B3D),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: AppTranslations.get(
                        _lang,
                        'enter_user_email_add',
                      ),
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF110D27),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSearching ? null : _addMemberByEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B6DFF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(AppTranslations.get(_lang, 'add')),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<CommunityMemberModel>>(
              stream: _commService.getMembers(widget.community.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFB99CFF)),
                  );
                }

                final members = snapshot.data ?? [];

                if (members.isEmpty) {
                  return Center(
                    child: Text(
                      AppTranslations.get(_lang, 'no_organizers_added_yet'),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isLeader =
                        member.role == AppTranslations.get(_lang, 'leader') ||
                        member.role == 'Leader';

                    return Card(
                      color: const Color(0xFF2B1D44),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLeader
                              ? Colors.amber.withOpacity(0.2)
                              : const Color(0xFF9B6DFF).withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            color: isLeader
                                ? Colors.amber
                                : const Color(0xFFB99CFF),
                          ),
                        ),
                        title: Text(
                          member.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          member.role,
                          style: TextStyle(
                            color: isLeader
                                ? Colors.amberAccent
                                : Colors.white70,
                          ),
                        ),
                        trailing: isLeader
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      backgroundColor: const Color(0xFF241B3D),
                                      title: Text(
                                        AppTranslations.get(
                                          _lang,
                                          'remove_organizer_q',
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      content: Text(
                                        '${AppTranslations.get(_lang, 'are_you_sure_remove')}${member.userName}?',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, false),
                                          child: Text(
                                            AppTranslations.get(
                                              _lang,
                                              'cancel',
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, true),
                                          child: Text(
                                            AppTranslations.get(
                                              _lang,
                                              'remove',
                                            ),
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _commService.removeMember(
                                      widget.community.id!,
                                      member.userId,
                                    );
                                  }
                                },
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
