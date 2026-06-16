import 'package:flutter/material.dart';
import 'package:razakevent/core/constants/app_colors.dart';

import '../../equipment/screens/manage_equipment_screen.dart';
import '../../equipment/screens/approve_equipment_screen.dart';

class ClubEquipmentScreen extends StatelessWidget {
  const ClubEquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text(
            'Equipment Management',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Inventory'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ManageEquipmentScreen(isTab: true),
            ApproveEquipmentScreen(isTab: true),
          ],
        ),
      ),
    );
  }
}
