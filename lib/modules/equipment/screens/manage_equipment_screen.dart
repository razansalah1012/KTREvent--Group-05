import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/equipment_service.dart';
import '../models/equipment_model.dart';
import '../../../core/localization/app_translations.dart';

class ManageEquipmentScreen extends StatefulWidget {
  final bool isTab;
  const ManageEquipmentScreen({super.key, this.isTab = false});

  @override
  State<ManageEquipmentScreen> createState() => _ManageEquipmentScreenState();
}

class _ManageEquipmentScreenState extends State<ManageEquipmentScreen> {
  final EquipmentService _service = EquipmentService();

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
      builder: (context, userSnapshot) {
        final lang = userSnapshot.data?.data()?['language'] ?? 'en';

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.get(lang, 'equipment_inventory'),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppTranslations.get(lang, 'manage_available_items'),
                          style: GoogleFonts.quicksand(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showAddEquipmentDialog(lang: lang),
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color(0xFF9B6DFF),
                      size: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<List<EquipmentModel>>(
                  stream: _service.getAllEquipment(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF9B6DFF),
                        ),
                      );
                    }

                    final equipmentList = snapshot.data ?? [];

                    if (equipmentList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppTranslations.get(lang, 'inventory_empty'),
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: equipmentList.length,
                      itemBuilder: (context, index) {
                        final item = equipmentList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A285A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D0820),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.category,
                                  color: Color(0xFF9B6DFF),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      '${AppTranslations.get(lang, 'qty')}${item.availableQuantity} / ${item.totalQuantity}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                onPressed: () => _showAddEquipmentDialog(
                                  item: item,
                                  lang: lang,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _service.deleteEquipment(item.id),
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
          ),
        );
      },
    );
  }

  void _showAddEquipmentDialog({EquipmentModel? item, required String lang}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final categoryController = TextEditingController(
      text: item?.category ?? 'Electronics',
    );
    final quantityController = TextEditingController(
      text: item?.totalQuantity.toString() ?? '1',
    );
    final conditionController = TextEditingController(
      text: item?.condition ?? 'Good',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241B3D),
        title: Text(
          item == null
              ? AppTranslations.get(lang, 'add_equipment')
              : AppTranslations.get(lang, 'edit_equipment'),
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(AppTranslations.get(lang, 'name'), nameController),
              _buildField(
                AppTranslations.get(lang, 'category'),
                categoryController,
              ),
              _buildField(
                AppTranslations.get(lang, 'total_quantity'),
                quantityController,
                keyboardType: TextInputType.number,
              ),
              _buildField(
                AppTranslations.get(lang, 'condition'),
                conditionController,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.get(lang, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              final int qty = int.tryParse(quantityController.text) ?? 1;

              if (item == null) {
                await _service.addEquipment(
                  EquipmentModel(
                    id: '',
                    name: nameController.text,
                    category: categoryController.text,
                    totalQuantity: qty,
                    availableQuantity: qty,
                    condition: conditionController.text,
                    status: 'available',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
              } else {
                await _service.updateEquipment(item.id, {
                  'name': nameController.text,
                  'category': categoryController.text,
                  'totalQuantity': qty,
                  'availableQuantity':
                      qty - (item.totalQuantity - item.availableQuantity),
                  'condition': conditionController.text,
                });
              }
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B6DFF),
            ),
            child: Text(
              item == null
                  ? AppTranslations.get(lang, 'add')
                  : AppTranslations.get(lang, 'update'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}
