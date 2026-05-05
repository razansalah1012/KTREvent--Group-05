import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A custom ticket‑style card used for displaying event information in the
/// student dashboard. The card has notches on both the left and right
/// edges and an inner border with a vertical dashed line to separate
/// content areas. You can customise the colours or content by passing
/// appropriate parameters. The default colours follow the dark purple
/// palette used throughout the application.
class EventTicketCard extends StatelessWidget {
  /// Title of the event.
  final String title;

  /// Date of the event (already formatted as a string).
  final String date;

  /// A brief description of the event.
  final String description;

  /// Optional tap callback for navigating to a detail page.
  final VoidCallback? onTap;

  const EventTicketCard({
    super.key,
    required this.title,
    required this.date,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: _TicketClipper(),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2040),
          ),
          height: 140,
          child: Stack(
            children: [
              // Draw ticket details: border and dashed line
              Positioned.fill(
                child: CustomPaint(
                  painter: _TicketBorderPainter(),
                ),
              ),
              // Event information
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: GoogleFonts.quicksand(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: GoogleFonts.quicksand(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Icon area on the right side of the ticket
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7E57C2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom clipper for the ticket shape. Creates rounded corners with
/// semi‑circular notches on the left and right edges.
class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const notchRadius = 20.0;
    const borderRadius = 16.0;
    final path = Path();
    path.moveTo(borderRadius, 0);
    // Top edge
    path.lineTo(size.width - borderRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, borderRadius);
    // Right side notch
    path.lineTo(size.width, size.height / 2 - notchRadius);
    path.arcToPoint(
      Offset(size.width, size.height / 2 + notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    // Right bottom corner
    path.lineTo(size.width, size.height - borderRadius);
    path.quadraticBezierTo(size.width, size.height, size.width - borderRadius, size.height);
    // Bottom edge
    path.lineTo(borderRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - borderRadius);
    // Left notch
    path.lineTo(0, size.height / 2 + notchRadius);
    path.arcToPoint(
      Offset(0, size.height / 2 - notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    // Left top corner
    path.lineTo(0, borderRadius);
    path.quadraticBezierTo(0, 0, borderRadius, 0);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Painter for drawing the inner border and vertical dashed line on the
/// ticket. This painter draws a rectangle inset from the edges and
/// paints a dashed line down the right side for visual separation.
class _TicketBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFBFA8FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      const Radius.circular(14),
    );
    canvas.drawRRect(innerRect, borderPaint);

    // Draw vertical dashed line near the right side
    final lineX = size.width - 70;
    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 16;
    while (startY < size.height - 16) {
      canvas.drawLine(
        Offset(lineX, startY),
        Offset(lineX, startY + dashHeight),
        dashPaint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}