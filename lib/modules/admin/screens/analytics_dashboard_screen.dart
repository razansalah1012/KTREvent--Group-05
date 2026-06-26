import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/localization/app_translations.dart';
import '../services/analytics_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  String lang = 'en';

  @override
  void initState() {
    super.initState();
    _fetchUserLang();
  }

  Future<void> _fetchUserLang() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          lang = doc.data()?['language'] ?? 'en';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0820),
        elevation: 0,
        title: Text(
          AppTranslations.get(lang, 'analytics_dashboard'),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(AppTranslations.get(lang, 'event_stats')),
            const SizedBox(height: 16),
            _buildEventStats(),
            const SizedBox(height: 32),
            _buildSectionTitle(AppTranslations.get(lang, 'equipment_stats')),
            const SizedBox(height: 16),
            _buildEquipmentStats(),
            const SizedBox(height: 32),
            _buildSectionTitle(AppTranslations.get(lang, 'user_stats')),
            const SizedBox(height: 16),
            _buildUserStats(),
            const SizedBox(height: 32),
            _buildSectionTitle(AppTranslations.get(lang, 'proposal_stats')),
            const SizedBox(height: 16),
            _buildProposalStats(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: const Color(0xFFB99CFF),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildChartContainer(Widget child) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B1D44),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFB99CFF).withOpacity(0.45)),
      ),
      child: child,
    );
  }

  Widget _buildEventStats() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _analyticsService.getEventStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _loadingIndicator();
        final data = snapshot.data!;
        
        final upcoming = data['upcoming'] as int;
        final past = data['past'] as int;
        final total = data['total'] as int;
        
        if (total == 0) return _noDataText();

        return _buildChartContainer(
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: upcoming.toDouble(),
                  title: '$upcoming\nUpcoming',
                  color: const Color(0xFF9B6DFF),
                  radius: 60,
                  titleStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  value: past.toDouble(),
                  title: '$past\nPast',
                  color: Colors.grey.shade600,
                  radius: 50,
                  titleStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                ),
              ],
              centerSpaceRadius: 40,
              sectionsSpace: 4,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEquipmentStats() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _analyticsService.getEquipmentStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _loadingIndicator();
        final data = snapshot.data!;
        
        final pending = data['pending'] as int;
        final approved = data['approved'] as int;
        final rejected = data['rejected'] as int;
        final total = data['total'] as int;

        if (total == 0) return _noDataText();

        return _buildChartContainer(
          BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: total.toDouble() + 5,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      String text;
                      switch (value.toInt()) {
                        case 0: text = 'Pending'; break;
                        case 1: text = 'Approved'; break;
                        case 2: text = 'Rejected'; break;
                        default: text = '';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 10)),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: pending.toDouble(), color: Colors.orange, width: 22, borderRadius: BorderRadius.circular(4))]),
                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: approved.toDouble(), color: Colors.green, width: 22, borderRadius: BorderRadius.circular(4))]),
                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: rejected.toDouble(), color: Colors.red, width: 22, borderRadius: BorderRadius.circular(4))]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserStats() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _analyticsService.getUserStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _loadingIndicator();
        final data = snapshot.data!;
        
        final students = data['students'] as int;
        final clubMembers = data['clubMembers'] as int;
        final admins = data['admins'] as int;
        final total = data['total'] as int;

        if (total == 0) return _noDataText();

        return _buildChartContainer(
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: students.toDouble(),
                  title: '$students\nStudents',
                  color: Colors.blueAccent,
                  radius: 50,
                  titleStyle: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                ),
                PieChartSectionData(
                  value: clubMembers.toDouble(),
                  title: '$clubMembers\nClubs',
                  color: Colors.tealAccent,
                  radius: 60,
                  titleStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  value: admins.toDouble(),
                  title: '$admins\nAdmins',
                  color: Colors.pinkAccent,
                  radius: 50,
                  titleStyle: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                ),
              ],
              centerSpaceRadius: 40,
              sectionsSpace: 4,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProposalStats() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _analyticsService.getProposalStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _loadingIndicator();
        final data = snapshot.data!;
        
        final pending = data['pending'] as int;
        final approved = data['approved'] as int;
        final rejected = data['rejected'] as int;
        final total = data['total'] as int;

        if (total == 0) return _noDataText();

        return _buildChartContainer(
          BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: total.toDouble() + 5,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      String text;
                      switch (value.toInt()) {
                        case 0: text = 'Pending'; break;
                        case 1: text = 'Approved'; break;
                        case 2: text = 'Rejected'; break;
                        default: text = '';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 10)),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: pending.toDouble(), color: Colors.orangeAccent, width: 22, borderRadius: BorderRadius.circular(4))]),
                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: approved.toDouble(), color: Colors.greenAccent, width: 22, borderRadius: BorderRadius.circular(4))]),
                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: rejected.toDouble(), color: Colors.redAccent, width: 22, borderRadius: BorderRadius.circular(4))]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _loadingIndicator() {
    return const Center(child: CircularProgressIndicator(color: Color(0xFFB99CFF)));
  }

  Widget _noDataText() {
    return Center(
      child: Text(
        'No data available',
        style: GoogleFonts.poppins(color: Colors.white54),
      ),
    );
  }
}
