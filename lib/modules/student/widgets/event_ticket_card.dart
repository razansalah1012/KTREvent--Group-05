import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razakevent/core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';

class EventTicketCard extends StatelessWidget {
  final String title;
  final String date;
  final String description;
  final String? imageUrl;
  final String? location;
  final String status;
  final VoidCallback? onTap;
  final String lang;

  const EventTicketCard({
    super.key,
    required this.title,
    required this.date,
    required this.description,
    this.imageUrl,
    this.location,
    this.status = 'OPEN',
    this.onTap,
    this.lang = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final bool isClosed = status.toUpperCase() == 'CLOSED' || status.toUpperCase() == 'FULL';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF241B3A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    width: 110,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(status, lang),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: GoogleFonts.quicksand(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('|', style: TextStyle(color: Colors.white24)),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location ?? AppTranslations.get(lang, 'location_tbd'),
                        style: GoogleFonts.quicksand(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: GoogleFonts.quicksand(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isClosed ? Colors.white10 : AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 20),
                        Text(
                          AppTranslations.get(lang, 'view_details'),
                          style: GoogleFonts.poppins(
                            color: isClosed ? Colors.white38 : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: isClosed ? Colors.white38 : Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 110,
      height: 150,
      color: const Color(0xFF1E1533),
      child: const Icon(Icons.event_available, color: Colors.white24, size: 40),
    );
  }

  Widget _buildStatusBadge(String status, String lang) {
    Color color = Colors.greenAccent;
    String displayStatus = AppTranslations.get(lang, 'open');

    final upperStatus = status.toUpperCase();

    if (upperStatus == 'FULL') {
      color = Colors.redAccent;
      displayStatus = AppTranslations.get(lang, 'full');
    } else if (upperStatus == 'CLOSING SOON') {
      color = Colors.orangeAccent;
      displayStatus = AppTranslations.get(lang, 'closing_soon');
    } else if (upperStatus == 'CLOSED') {
      color = Colors.white38;
      displayStatus = AppTranslations.get(lang, 'closed');
    } else if (upperStatus == 'ONGOING') {
      color = Colors.blueAccent;
      displayStatus = AppTranslations.get(lang, 'ongoing');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        displayStatus,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
