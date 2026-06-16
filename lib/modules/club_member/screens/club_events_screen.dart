import 'package:flutter/material.dart';
import 'package:razakevent/core/constants/app_colors.dart';

import '../../events/screens/manage_events_screen.dart';
import 'crew_applications_screen.dart';

class ClubEventsScreen extends StatelessWidget {
  const ClubEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text(
            'Event Management',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'My Events'),
              Tab(text: 'Crew Apps'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ManageEventsScreen(isTab: true),
            CrewApplicationsScreen(isTab: true),
          ],
        ),
      ),
    );
  }
}
