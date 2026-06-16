import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/equipment_service.dart';
import '../models/equipment_request_model.dart';
import '../../../core/localization/app_translations.dart';

class ApproveEquipmentScreen extends StatefulWidget {
  final bool isTab;
  const ApproveEquipmentScreen({super.key, this.isTab = false});

  @override
  State<ApproveEquipmentScreen> createState() => _ApproveEquipmentScreenState();
}

class _ApproveEquipmentScreenState extends State<ApproveEquipmentScreen> {
  final EquipmentService _service = EquipmentService();
  String _selectedStatus = 'pending';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Not signed in', style: TextStyle(color: Colors.white)),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final lang = data['language'] ?? 'en';

        Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.get(lang, 'equipment_requests'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppTranslations.get(lang, 'review_manage_requests'),
                    style: GoogleFonts.quicksand(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusFilter(lang),
            Expanded(
              child: StreamBuilder<List<EquipmentRequestModel>>(
                stream: _service.getRequests(status: _selectedStatus),
                builder: (context, requestSnapshot) {
                  if (requestSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF9B6DFF),
                      ),
                    );
                  }

                  final requests = requestSnapshot.data ?? [];

                  if (requests.isEmpty) {
                    String displayStatus = _selectedStatus;
                    if (_selectedStatus == 'pending')
                      displayStatus = AppTranslations.get(lang, 'pending');
                    if (_selectedStatus == 'approved')
                      displayStatus = AppTranslations.get(lang, 'approved');
                    if (_selectedStatus == 'rejected')
                      displayStatus = AppTranslations.get(lang, 'rejected');
                    if (_selectedStatus == 'returned')
                      displayStatus = AppTranslations.get(lang, 'returned');

                    return Center(
                      child: Text(
                        '${AppTranslations.get(lang, 'no')} $displayStatus${AppTranslations.get(lang, 'no_requests_found')}',
                        style: GoogleFonts.quicksand(color: Colors.white38),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return _buildRequestCard(request, lang);
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
            title: Text(AppTranslations.get(lang, 'approve_requests')),
            backgroundColor: const Color(0xFF261A3D),
            foregroundColor: Colors.white,
          ),
          body: content,
        );
      },
    );
  }

  Widget _buildStatusFilter(String lang) {
    final statuses = ['pending', 'approved', 'rejected', 'returned'];
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final s = statuses[index];
          final isSelected = _selectedStatus == s;

          String displayStatus = s.toUpperCase();
          if (s == 'pending')
            displayStatus = AppTranslations.get(lang, 'pending').toUpperCase();
          if (s == 'approved')
            displayStatus = AppTranslations.get(lang, 'approved').toUpperCase();
          if (s == 'rejected')
            displayStatus = AppTranslations.get(lang, 'rejected').toUpperCase();
          if (s == 'returned')
            displayStatus = AppTranslations.get(lang, 'returned').toUpperCase();

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(displayStatus),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedStatus = s);
              },
              backgroundColor: const Color(0xFF261A3D),
              selectedColor: const Color(0xFF9B6DFF),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(EquipmentRequestModel request, String lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A285A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  request.equipmentName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${AppTranslations.get(lang, 'qty')}${request.quantity}',
                style: const TextStyle(
                  color: Color(0xFFB99CFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          _infoRow(
            Icons.person_outline,
            AppTranslations.get(lang, 'requester'),
            request.requesterName,
          ),
          _infoRow(
            Icons.event_note,
            AppTranslations.get(lang, 'event'),
            request.eventName,
          ),
          _infoRow(
            Icons.calendar_today,
            AppTranslations.get(lang, 'borrowed'),
            '${request.borrowedDate.day}/${request.borrowedDate.month}/${request.borrowedDate.year}',
          ),
          _infoRow(
            Icons.keyboard_return,
            AppTranslations.get(lang, 'return_by'),
            '${request.returnDate.day}/${request.returnDate.month}/${request.returnDate.year}',
          ),

          if (request.status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _service.updateRequestStatus(request.id, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    child: Text(AppTranslations.get(lang, 'reject')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _service.updateRequestStatus(request.id, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(AppTranslations.get(lang, 'approve')),
                  ),
                ),
              ],
            ),
          ] else if (request.status == 'approved') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _service.updateRequestStatus(request.id, 'returned'),
                icon: const Icon(Icons.keyboard_return),
                label: Text(AppTranslations.get(lang, 'mark_returned')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B6DFF),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
