import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razakevent/core/constants/app_colors.dart';
import 'package:razakevent/modules/events/models/event_model.dart';
import 'package:razakevent/modules/participation/services/participation_service.dart';
import 'package:razakevent/modules/student/screens/payment_screen.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/services/local_notification_service.dart';

class EventRegistrationScreen extends StatefulWidget {
  final EventModel event;

  const EventRegistrationScreen({super.key, required this.event});

  @override
  State<EventRegistrationScreen> createState() =>
      _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends State<EventRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _matricController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  final Map<String, dynamic> _customResponses = {};
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    if (widget.event.registrationFields != null) {
      for (var field in widget.event.registrationFields!) {
        _customResponses[field.label] = '';
      }
    }
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _nameController.text = user.displayName ?? '';

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _userRole = doc.data()?['role'];
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _handleConfirmBooking(String lang) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (widget.event.fee > 0 && _userRole != 'club') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              event: widget.event,
              onPaymentComplete: () => _finalizeRegistration(lang),
            ),
          ),
        );
      } else {
        _finalizeRegistration(lang);
      }
    }
  }

  Future<void> _finalizeRegistration(String lang) async {
    final participationService = ParticipationService();
    try {
      final fullResponses = {
        'fullName': _nameController.text,
        'matricNumber': _matricController.text,
        'phoneNumber': _phoneController.text,
        if (_userRole == 'club') ...{
          'paymentDetails': {
            'cardNumber': _cardNumberController.text,
            'expiry': _expiryController.text,
            'cvv': _cvvController.text,
          },
        },
        ..._customResponses,
      };

      final participationId = await participationService.registerForEvent(
        widget.event.id!,
        widget.event.title,
        registrationResponses: fullResponses,
      );

      await LocalNotificationService().scheduleEventReminder(
        eventId: widget.event.id!,
        title: widget.event.title,
        eventDate: widget.event.date,
        eventTime: widget.event.startTime ?? '',
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrationSuccessScreen(
              event: widget.event,
              participationId: participationId,
              lang: lang,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final lang = snapshot.data?.data()?['language'] ?? 'en';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppTranslations.get(lang, 'booking_confirmation'),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildEventHeaderCard(),
                  const SizedBox(height: 30),

                  _buildSectionTitle(
                    AppTranslations.get(lang, 'attendee_information'),
                  ),
                  const SizedBox(height: 15),
                  _buildInfoContainer([
                    _buildInputField(
                      Icons.person_outline,
                      AppTranslations.get(lang, 'full_name'),
                      _nameController,
                      lang: lang,
                    ),
                    _buildDivider(),
                    _buildInputField(
                      Icons.assignment_outlined,
                      AppTranslations.get(lang, 'matric_number'),
                      _matricController,
                      lang: lang,
                    ),
                    _buildDivider(),
                    _buildInputField(
                      Icons.mail_outline,
                      AppTranslations.get(lang, 'email'),
                      _emailController,
                      lang: lang,
                    ),
                    _buildDivider(),
                    _buildInputField(
                      Icons.phone_outlined,
                      AppTranslations.get(lang, 'phone_number'),
                      _phoneController,
                      lang: lang,
                    ),
                  ]),

                  const SizedBox(height: 30),
                  if (widget.event.registrationFields != null &&
                      widget.event.registrationFields!.isNotEmpty) ...[
                    _buildSectionTitle(
                      AppTranslations.get(lang, 'additional_information'),
                    ),
                    const SizedBox(height: 15),
                    _buildInfoContainer(
                      widget.event.registrationFields!.asMap().entries.map((
                        entry,
                      ) {
                        final index = entry.key;
                        final field = entry.value;
                        final isLast =
                            index ==
                            widget.event.registrationFields!.length - 1;

                        return Column(
                          children: [
                            _buildCustomInputField(field, lang),
                            if (!isLast) _buildDivider(),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                  ],

                  if (_userRole == 'club') ...[
                    _buildSectionTitle(
                      AppTranslations.get(lang, 'payment_details'),
                    ),
                    const SizedBox(height: 15),
                    _buildInfoContainer([
                      _buildInputField(
                        Icons.credit_card_outlined,
                        AppTranslations.get(lang, 'card_number'),
                        _cardNumberController,
                        hint: '0000 0000 0000 0000',
                        lang: lang,
                      ),
                      _buildDivider(),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              Icons.calendar_today_outlined,
                              AppTranslations.get(lang, 'expiry'),
                              _expiryController,
                              hint: 'MM/YY',
                              lang: lang,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: Colors.white.withOpacity(0.05),
                          ),
                          Expanded(
                            child: _buildInputField(
                              Icons.lock_outline,
                              AppTranslations.get(lang, 'cvv'),
                              _cvvController,
                              hint: '***',
                              lang: lang,
                            ),
                          ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 30),
                  ],

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () => _handleConfirmBooking(lang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      AppTranslations.get(lang, 'confirm_booking'),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1835),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child:
                widget.event.imageUrl != null &&
                    widget.event.imageUrl!.isNotEmpty
                ? Image.network(
                    widget.event.imageUrl!,
                    width: 90,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 90,
                    height: 100,
                    color: Colors.white10,
                    child: const Icon(
                      Icons.event,
                      color: Colors.white24,
                      size: 40,
                    ),
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Color(0xFFB8B2CB),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.event.date.day} ${_getMonth(widget.event.date.month)} ${widget.event.date.year}',
                      style: GoogleFonts.quicksand(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFFB8B2CB),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.event.location,
                        style: GoogleFonts.quicksand(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
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
    return months[month - 1];
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInfoContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1835),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInputField(
    IconData icon,
    String label,
    TextEditingController controller, {
    String? hint,
    required String lang,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB8B2CB), size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.quicksand(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                TextFormField(
                  controller: controller,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.1),
                      fontSize: 14,
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? AppTranslations.get(lang, 'required')
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomInputField(RegistrationField field, String lang) {
    IconData icon = Icons.edit_note_rounded;
    String label = field.label;
    if (label.toLowerCase().contains('size')) icon = Icons.checkroom_outlined;
    if (label.toLowerCase().contains('food')) icon = Icons.restaurant_outlined;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB8B2CB), size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.quicksand(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (field.type == 'dropdown')
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF1E1835),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white38,
                      size: 20,
                    ),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    items: field.options
                        ?.map(
                          (opt) =>
                              DropdownMenuItem(value: opt, child: Text(opt)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _customResponses[field.label] = val),
                    validator: (val) =>
                        field.isRequired && (val == null || val.isEmpty)
                        ? AppTranslations.get(lang, 'required')
                        : null,
                  )
                else
                  TextFormField(
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => _customResponses[field.label] = val,
                    validator: (val) =>
                        field.isRequired && (val == null || val.isEmpty)
                        ? AppTranslations.get(lang, 'required')
                        : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withOpacity(0.05),
      indent: 50,
    );
  }
}

class RegistrationSuccessScreen extends StatelessWidget {
  final EventModel event;
  final String participationId;
  final String lang;

  const RegistrationSuccessScreen({
    super.key,
    required this.event,
    required this.participationId,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 32),
            Text(
              AppTranslations.get(lang, 'congratulations'),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppTranslations.get(lang, 'successfully_registered')}${event.title}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Text(
              AppTranslations.get(lang, 'booking_id'),
              style: GoogleFonts.quicksand(color: Colors.white38, fontSize: 14),
            ),
            Text(
              'KTR-2026-${participationId.substring(0, 5).toUpperCase()}',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  AppTranslations.get(lang, 'back_to_home'),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
