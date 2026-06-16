import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/localization/app_translations.dart';

class AdminCertificateDialog extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String organizerId;
  final Function(bool includeOrganizers, Map<String, String> studentCustomRoles)
  onConfirm;

  const AdminCertificateDialog({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.organizerId,
    required this.onConfirm,
  });

  @override
  State<AdminCertificateDialog> createState() => _AdminCertificateDialogState();
}

class _AdminCertificateDialogState extends State<AdminCertificateDialog> {
  bool _includeOrganizers = true;
  bool _includeStudents = true;
  bool _isLoadingStudents = true;
  String _lang = 'en';

  List<Map<String, dynamic>> _attendedStudents = [];
  final Map<String, bool> _studentSelection = {};
  final Map<String, TextEditingController> _studentRoleControllers = {};

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
    _fetchAttendedStudents();
  }

  Future<void> _fetchAttendedStudents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('participations')
          .where('eventId', isEqualTo: widget.eventId)
          .where('status', isEqualTo: 'Attended')
          .get();

      setState(() {
        _attendedStudents = snapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'userId': doc.data()['userId'],
                'userName':
                    doc.data()['userName'] ??
                    AppTranslations.get(_lang, 'participant'),
              },
            )
            .toList();

        for (var student in _attendedStudents) {
          final userId = student['userId'] as String;
          _studentSelection[userId] = true;
          _studentRoleControllers[userId] = TextEditingController(
            text: AppTranslations.get(_lang, 'participant'),
          );
        }
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _studentRoleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF261A3D),
      title: Text(
        AppTranslations.get(_lang, 'generate_certificates'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text(
                AppTranslations.get(_lang, 'include_organizing_team'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                AppTranslations.get(_lang, 'issues_certs_to_director_crew'),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: _includeOrganizers,
              activeThumbColor: const Color(0xFF9B6DFF),
              onChanged: (val) => setState(() => _includeOrganizers = val),
            ),
            const Divider(color: Colors.white24),
            SwitchListTile(
              title: Text(
                AppTranslations.get(_lang, 'include_attended_students'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                AppTranslations.get(_lang, 'customize_titles_winners'),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: _includeStudents,
              activeThumbColor: const Color(0xFF9B6DFF),
              onChanged: (val) => setState(() => _includeStudents = val),
            ),

            if (_includeStudents) ...[
              const SizedBox(height: 10),
              Text(
                AppTranslations.get(_lang, 'attended_students_list'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              if (_isLoadingStudents)
                const Center(child: CircularProgressIndicator())
              else if (_attendedStudents.isEmpty)
                Text(
                  AppTranslations.get(_lang, 'no_students_marked_attended'),
                  style: const TextStyle(color: Colors.white54),
                )
              else
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1533),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _attendedStudents.length,
                      separatorBuilder: (_, _) =>
                          const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, index) {
                        final student = _attendedStudents[index];
                        final userId = student['userId'] as String;
                        final userName = student['userName'] as String;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          leading: Checkbox(
                            value: _studentSelection[userId],
                            activeColor: const Color(0xFF9B6DFF),
                            onChanged: (val) {
                              setState(() {
                                _studentSelection[userId] = val ?? false;
                              });
                            },
                          ),
                          title: Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: _studentSelection[userId] == true
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: TextField(
                                    controller: _studentRoleControllers[userId],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: AppTranslations.get(
                                        _lang,
                                        'custom_title_eg',
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                      isDense: true,
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Colors.white24,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFF9B6DFF),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  AppTranslations.get(_lang, 'excluded'),
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppTranslations.get(_lang, 'cancel'),
            style: const TextStyle(color: Colors.white54),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9B6DFF),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Map<String, String> finalStudentRoles = {};
            if (_includeStudents) {
              for (var student in _attendedStudents) {
                final userId = student['userId'] as String;
                if (_studentSelection[userId] == true) {
                  finalStudentRoles[userId] =
                      _studentRoleControllers[userId]?.text.trim() ??
                      AppTranslations.get(_lang, 'participant');
                  if (finalStudentRoles[userId]!.isEmpty) {
                    finalStudentRoles[userId] = AppTranslations.get(
                      _lang,
                      'participant',
                    );
                  }
                }
              }
            }

            widget.onConfirm(_includeOrganizers, finalStudentRoles);
          },
          child: Text(AppTranslations.get(_lang, 'confirm_generate')),
        ),
      ],
    );
  }
}
