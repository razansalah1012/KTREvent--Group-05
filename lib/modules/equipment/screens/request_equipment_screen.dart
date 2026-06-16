import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razakevent/core/constants/app_colors.dart';
import '../services/equipment_service.dart';
import '../models/equipment_model.dart';
import '../models/equipment_request_model.dart';
import '../../../core/localization/app_translations.dart';

class RequestEquipmentScreen extends StatefulWidget {
  const RequestEquipmentScreen({super.key});

  @override
  State<RequestEquipmentScreen> createState() => _RequestEquipmentScreenState();
}

class _RequestEquipmentScreenState extends State<RequestEquipmentScreen> {
  final EquipmentService _service = EquipmentService();
  String selectedTab = 'Browse';
  String selectedCategory = 'All';
  final List<String> categories = [
    'All',
    'Electronics',
    'Audio',
    'Visual',
    'Furniture',
  ];
  final List<String> tabs = ['Browse', 'Track', 'History'];

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
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.get(lang, 'equipment_borrowing'),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              AppTranslations.get(lang, 'request_items'),
                              style: GoogleFonts.quicksand(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildNotificationIcon(),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1835),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildNavTab(
                          'Browse',
                          AppTranslations.get(lang, 'browse'),
                          Icons.grid_view_rounded,
                        ),
                        _buildNavTab(
                          'Track',
                          AppTranslations.get(lang, 'track'),
                          Icons.swap_vert_rounded,
                        ),
                        _buildNavTab(
                          'History',
                          AppTranslations.get(lang, 'history'),
                          Icons.history_rounded,
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1835),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                                color: Colors.white54,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  style: GoogleFonts.quicksand(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: AppTranslations.get(
                                      lang,
                                      'search_equipment',
                                    ),
                                    hintStyle: GoogleFonts.quicksand(
                                      color: Colors.white54,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1835),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = selectedCategory == cat;
                      String displayCat = cat;
                      if (cat == 'All')
                        displayCat = AppTranslations.get(lang, 'all');
                      if (cat == 'Electronics')
                        displayCat = AppTranslations.get(lang, 'electronics');
                      if (cat == 'Audio')
                        displayCat = AppTranslations.get(lang, 'audio');
                      if (cat == 'Visual')
                        displayCat = AppTranslations.get(lang, 'visual');
                      if (cat == 'Furniture')
                        displayCat = AppTranslations.get(lang, 'furniture');

                      return GestureDetector(
                        onTap: () => setState(() => selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF1E1835),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (cat != 'All') ...[
                                Icon(
                                  _getCategoryIcon(cat),
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white54,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                displayCat,
                                style: GoogleFonts.poppins(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white54,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 15),

                Expanded(child: _buildMainContent(lang)),

                _buildSummaryDashboard(lang),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1835),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavTab(String key, String title, IconData icon) {
    final isSelected = selectedTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white54,
                size: 14,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(String lang) {
    if (selectedTab == 'Browse') {
      return StreamBuilder<List<EquipmentModel>>(
        stream: _service.getAllEquipment(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final items = snapshot.data ?? [];
          final filteredItems = selectedCategory == 'All'
              ? items
              : items.where((i) => i.category == selectedCategory).toList();

          if (filteredItems.isEmpty) {
            return Center(
              child: Text(
                AppTranslations.get(lang, 'no_equipment_found'),
                style: GoogleFonts.quicksand(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              return _buildEquipmentCard(filteredItems[index], lang);
            },
          );
        },
      );
    } else {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      return StreamBuilder<List<EquipmentRequestModel>>(
        stream: _service.getRequests(userId: userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final requests = snapshot.data ?? [];
          final filteredRequests = selectedTab == 'Track'
              ? requests
                    .where(
                      (r) => r.status == 'pending' || r.status == 'approved',
                    )
                    .toList()
              : requests
                    .where(
                      (r) => r.status == 'rejected' || r.status == 'returned',
                    )
                    .toList();

          if (filteredRequests.isEmpty) {
            return Center(
              child: Text(
                AppTranslations.get(lang, 'no_records'),
                style: GoogleFonts.quicksand(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              return _buildRequestStatusCard(filteredRequests[index], lang);
            },
          );
        },
      );
    }
  }

  Widget _buildEquipmentCard(EquipmentModel item, String lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1835),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF241B3A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? Image.network(item.imageUrl!, fit: BoxFit.contain)
                          : Icon(
                              _getCategoryIcon(item.category),
                              color: Colors.white.withOpacity(0.08),
                              size: 36,
                            ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161225).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category,
                            style: GoogleFonts.quicksand(
                              color: Colors.white70,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                            item.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildConditionBadge(item.condition),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 10,
                                color: Colors.white38,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  AppTranslations.get(lang, 'available'),
                                  style: GoogleFonts.quicksand(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.availableQuantity}/${item.totalQuantity}',
                          style: GoogleFonts.poppins(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildSegmentedProgressBar(
                      item.availableQuantity,
                      item.totalQuantity,
                    ),
                    const SizedBox(height: 10),
                    _buildCardInfoRow(
                      Icons.access_time_rounded,
                      AppTranslations.get(lang, 'period'),
                      '${item.borrowPeriod} ${AppTranslations.get(lang, 'days')}',
                    ),
                    _buildCardInfoRow(
                      Icons.verified_user_outlined,
                      AppTranslations.get(lang, 'deposit'),
                      'RM${item.deposit.toInt()}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: item.availableQuantity > 0
                ? () => _showBorrowDialog(item, lang)
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: item.availableQuantity > 0
                    ? AppColors.primary
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 32),
                  Text(
                    AppTranslations.get(lang, 'borrow_now'),
                    style: GoogleFonts.poppins(
                      color: item.availableQuantity > 0
                          ? Colors.white
                          : Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: item.availableQuantity > 0
                        ? Colors.white
                        : Colors.white24,
                    size: 12,
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionBadge(String condition) {
    Color color = Colors.greenAccent;
    if (condition.toLowerCase() == 'good') color = Colors.orangeAccent;
    if (condition.toLowerCase() == 'fair') color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            condition.toUpperCase(),
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedProgressBar(int available, int total) {
    return Row(
      children: List.generate(6, (index) {
        bool filled =
            total > 0 && (index + 1) <= (available / total * 6).ceil();
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: index == 5 ? 0 : 3),
            decoration: BoxDecoration(
              color: filled
                  ? Colors.greenAccent
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCardInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 10, color: Colors.white38),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.quicksand(color: Colors.white54, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestStatusCard(EquipmentRequestModel r, String lang) {
    Color statusColor = Colors.orangeAccent;
    if (r.status == 'approved') statusColor = Colors.greenAccent;
    if (r.status == 'rejected') statusColor = Colors.redAccent;
    if (r.status == 'returned') statusColor = Colors.blueAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1835),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  r.equipmentName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  r.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCardInfoRow(
            Icons.confirmation_number_outlined,
            AppTranslations.get(lang, 'quantity'),
            '${r.quantity} ${AppTranslations.get(lang, 'units')}',
          ),
          _buildCardInfoRow(
            Icons.event_outlined,
            AppTranslations.get(lang, 'event'),
            r.eventName,
          ),
          _buildCardInfoRow(
            Icons.calendar_today_outlined,
            AppTranslations.get(lang, 'return_by'),
            '${r.returnDate.day}/${r.returnDate.month}/${r.returnDate.year}',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDashboard(String lang) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<List<EquipmentRequestModel>>(
      stream: _service.getRequests(userId: userId),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];
        final borrowed = requests
            .where((r) => r.status == 'approved')
            .length
            .toString();
        final pending = requests
            .where((r) => r.status == 'pending')
            .length
            .toString();
        final returned = requests
            .where((r) => r.status == 'returned')
            .length
            .toString();
        final overdue = requests
            .where(
              (r) =>
                  r.status == 'approved' &&
                  r.returnDate.isBefore(DateTime.now()),
            )
            .length
            .toString();

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          decoration: const BoxDecoration(
            color: Color(0xFF161225),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  AppTranslations.get(lang, 'equipment_summary'),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildSummaryIconItem(
                      Icons.shopping_bag_outlined,
                      borrowed,
                      AppTranslations.get(lang, 'borrowed'),
                      const Color(0xFFB794FF),
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryIconItem(
                      Icons.access_time_rounded,
                      pending,
                      AppTranslations.get(lang, 'pending'),
                      Colors.orangeAccent,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryIconItem(
                      Icons.check_circle_outline_rounded,
                      returned,
                      AppTranslations.get(lang, 'returned'),
                      Colors.greenAccent,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryIconItem(
                      Icons.calendar_today_outlined,
                      overdue,
                      AppTranslations.get(lang, 'overdue'),
                      Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryIconItem(
    IconData icon,
    String count,
    String label,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                count,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.quicksand(
            color: AppColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.memory_rounded;
      case 'audio':
        return Icons.volume_up_rounded;
      case 'visual':
        return Icons.desktop_windows_rounded;
      case 'furniture':
        return Icons.chair_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _showBorrowDialog(EquipmentModel item, String lang) {
    final quantityController = TextEditingController(text: '1');
    final eventController = TextEditingController();
    final reasonController = TextEditingController();
    DateTime borrowDate = DateTime.now().add(const Duration(days: 1));
    DateTime returnDate = DateTime.now().add(
      Duration(days: 1 + item.borrowPeriod),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1533),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            AppTranslations.get(lang, 'borrowing_form'),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppTranslations.get(lang, 'item')}${item.name}',
                  style: GoogleFonts.quicksand(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                _buildFormInput(
                  '${AppTranslations.get(lang, 'quantity_max')}${item.availableQuantity})',
                  quantityController,
                  keyboardType: TextInputType.number,
                ),
                _buildFormInput(
                  AppTranslations.get(lang, 'event_workshop_name'),
                  eventController,
                ),
                _buildFormInput(
                  AppTranslations.get(lang, 'reason_borrowing'),
                  reasonController,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                Text(
                  AppTranslations.get(lang, 'borrowing_period'),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(color: Colors.white12, height: 20),
                _buildDateSelector(
                  AppTranslations.get(lang, 'borrow_date'),
                  borrowDate,
                  (date) {
                    setState(() {
                      borrowDate = date;
                      if (returnDate.isBefore(borrowDate)) {
                        returnDate = borrowDate.add(
                          Duration(days: item.borrowPeriod),
                        );
                      }
                    });
                  },
                  firstDate: DateTime.now(),
                ),
                _buildDateSelector(
                  AppTranslations.get(lang, 'return_date'),
                  returnDate,
                  (date) => setState(() => returnDate = date),
                  firstDate: borrowDate,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppTranslations.get(lang, 'cancel'),
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                int qty = int.tryParse(quantityController.text) ?? 0;
                if (qty <= 0 || qty > item.availableQuantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppTranslations.get(lang, 'invalid_quantity'),
                      ),
                    ),
                  );
                  return;
                }
                if (eventController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppTranslations.get(lang, 'enter_event_name'),
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await _service.submitRequest(
                    equipmentId: item.id,
                    equipmentName: item.name,
                    quantity: qty,
                    eventName: eventController.text,
                    reason: reasonController.text,
                    borrowedDate: borrowDate,
                    returnDate: returnDate,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppTranslations.get(lang, 'request_success'),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppTranslations.get(lang, 'error')}$e'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                AppTranslations.get(lang, 'submit_request'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(
    String label,
    DateTime date,
    Function(DateTime) onPicked, {
    required DateTime firstDate,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 13),
      ),
      subtitle: Text(
        '${date.day}/${date.month}/${date.year}',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.calendar_today_rounded,
        color: AppColors.primary,
        size: 18,
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date.isBefore(firstDate) ? firstDate : date,
          firstDate: firstDate,
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  Widget _buildFormInput(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.quicksand(
            color: Colors.white38,
            fontSize: 13,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white12),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
