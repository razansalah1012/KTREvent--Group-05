import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razakevent/core/constants/app_colors.dart';
import '../../../core/localization/app_translations.dart';
import '../services/equipment_service.dart';
import '../models/equipment_model.dart';
import 'track_equipment_screen.dart';

class RequestEquipmentScreen extends StatefulWidget {
  const RequestEquipmentScreen({super.key});

  @override
  State<RequestEquipmentScreen> createState() => _RequestEquipmentScreenState();
}

class _RequestEquipmentScreenState extends State<RequestEquipmentScreen> {
  final EquipmentService _service = EquipmentService();
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    _fetchLanguage();
  }

  Future<void> _fetchLanguage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _lang = doc.data()?['language'] ?? 'en';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(
            AppTranslations.get(_lang, 'equipment_borrowing'),
            style: GoogleFonts.poppins(color: const Color.fromARGB(255, 247, 247, 247), fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: AppTranslations.get(_lang, 'browse')),
              Tab(text: AppTranslations.get(_lang, 'track')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBrowseTab(),
            const TrackEquipmentScreen(isTab: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            AppTranslations.get(_lang, 'request_items'),
            style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 14),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<EquipmentModel>>(
            stream: _service.getAllEquipment(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              final equipmentList = snapshot.data ?? [];
              // Only show equipment that is actually available to borrow
              final availableEquipment = equipmentList.where((item) => item.availableQuantity > 0).toList();

              if (availableEquipment.isEmpty) {
                return Center(
                  child: Text(
                    AppTranslations.get(_lang, 'no_equipment_found'),
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: availableEquipment.length,
                itemBuilder: (context, index) {
                  final item = availableEquipment[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D0820),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.inventory_2, color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    item.category,
                                    style: GoogleFonts.quicksand(
                                      color: AppColors.secondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${AppTranslations.get(_lang, 'available')}: ${item.availableQuantity} ${AppTranslations.get(_lang, 'units')}",
                              style: GoogleFonts.quicksand(color: Colors.white70),
                            ),
                            ElevatedButton(
                              onPressed: () => _showRequestDialog(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: Text(
                                AppTranslations.get(_lang, 'borrow_now'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  void _showRequestDialog(EquipmentModel item) {
    final qtyController = TextEditingController(text: '1');
    final eventNameController = TextEditingController();
    final reasonController = TextEditingController();
    DateTime borrowedDate = DateTime.now();
    DateTime returnDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF241B3D),
              title: Text(
                AppTranslations.get(_lang, 'borrowing_form'),
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${AppTranslations.get(_lang, 'item')}${item.name}",
                      style: GoogleFonts.quicksand(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "${AppTranslations.get(_lang, 'quantity')} (Max ${item.availableQuantity})",
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    TextField(
                      controller: eventNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: AppTranslations.get(_lang, 'event_workshop_name'),
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    TextField(
                      controller: reasonController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: AppTranslations.get(_lang, 'reason_borrowing'),
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppTranslations.get(_lang, 'borrowing_period'),
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "${AppTranslations.get(_lang, 'borrow_date')}: ${borrowedDate.toLocal().toString().split(' ')[0]}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: borrowedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setStateDialog(() => borrowedDate = date);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "${AppTranslations.get(_lang, 'return_date')}: ${returnDate.toLocal().toString().split(' ')[0]}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: returnDate.isBefore(borrowedDate) ? borrowedDate : returnDate,
                          firstDate: borrowedDate,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setStateDialog(() => returnDate = date);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppTranslations.get(_lang, 'cancel'), style: const TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    int qty = int.tryParse(qtyController.text) ?? 1;
                    if (qty > item.availableQuantity) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppTranslations.get(_lang, 'invalid_quantity'))),
                      );
                      return;
                    }
                    if (eventNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppTranslations.get(_lang, 'enter_event_name'))),
                      );
                      return;
                    }
                    
                    try {
                      await _service.submitRequest(
                        equipmentId: item.id,
                        equipmentName: item.name,
                        quantity: qty,
                        eventName: eventNameController.text.trim(),
                        reason: reasonController.text.trim(),
                        borrowedDate: borrowedDate,
                        returnDate: returnDate,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppTranslations.get(_lang, 'request_success'))),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${AppTranslations.get(_lang, 'error')}$e")),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text(AppTranslations.get(_lang, 'submit_request')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
