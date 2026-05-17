import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Use package imports to ensure proper resolution across modules.
import 'package:razakevent/modules/student/screens/explore_events_screen.dart';
import 'package:razakevent/modules/student/screens/booked_events_screen.dart';
import 'package:razakevent/modules/student/screens/student_profile_screen.dart';

// Import the login screen via a package import to ensure proper resolution.
import 'package:razakevent/modules/auth/screens/login_screen.dart';

/// The StudentDashboardScreen is the main entry point for students
/// after they log in. It provides a bottom navigation bar to
/// switch between exploring all events, viewing booked events and
/// viewing the user profile. A role check ensures only users with
/// the "student" role can access this page.
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentIndex = 0;

  /// List of widgets for each tab in the bottom navigation.
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      ExploreEventsScreen(),
      BookedEventsScreen(),
      StudentProfileScreen(),
    ];
  }

  /// Performs a check against Firestore to confirm the current
  /// authenticated user has a student role. Returns a Future that
  /// resolves to true if the user is a student, false otherwise.
  Future<bool> _isStudentRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final data = doc.data();
    return data != null && data['role'] == 'student';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isStudentRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == false) {
          // If user is not a student or an error occurs, show error message
          return Scaffold(
            body: Center(
              child: Text(
                'You do not have access to the student dashboard.',
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            backgroundColor: const Color(0xFF110d27),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'KTR Event',
              style: GoogleFonts.goldman(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            // Add a logout button to the app bar so students can
            // sign out from anywhere in the dashboard.
            actions: [
              IconButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  // After signing out, navigate back to login and remove all previous routes.
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipPath(
              clipper: _DashboardTicketClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF2B2040),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DashboardTicketBorderPainter(),
                      ),
                    ),
                    _pages[_currentIndex],
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: const Color(0xFF241B3D),
            selectedItemColor: const Color(0xFF9B6CFF),
            unselectedItemColor: Colors.white70,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.confirmation_num_outlined),
                activeIcon: Icon(Icons.confirmation_num),
                label: 'Booked',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
          backgroundColor: const Color(0xFF110d27),
        );
      },
    );
  }
}

/// Custom clipper to create a large ticket shape for the student dashboard.
class _DashboardTicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double notchRadius = 26.0;
    const double borderRadius = 20.0;
    final Path path = Path();
    path.moveTo(borderRadius, 0);
    // Top edge with rounded corners.
    path.lineTo(size.width - borderRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, borderRadius);
    // Right notch.
    path.lineTo(size.width, size.height / 2 - notchRadius);
    path.arcToPoint(
      Offset(size.width, size.height / 2 + notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    // Bottom right corner and edge.
    path.lineTo(size.width, size.height - borderRadius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - borderRadius,
      size.height,
    );
    // Bottom edge with rounded corner.
    path.lineTo(borderRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - borderRadius);
    // Left notch.
    path.lineTo(0, size.height / 2 + notchRadius);
    path.arcToPoint(
      Offset(0, size.height / 2 - notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    // Top left corner.
    path.lineTo(0, borderRadius);
    path.quadraticBezierTo(0, 0, borderRadius, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Painter to draw the border and a vertical dashed line on the dashboard ticket.
class _DashboardTicketBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFBFA8FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw the inner border as a rounded rectangle.
    final Rect innerRect =
    Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    final RRect innerRRect =
    RRect.fromRectAndRadius(innerRect, const Radius.circular(18));
    canvas.drawRRect(innerRRect, borderPaint);

    // Draw vertical dashed line near the right side to emulate a tear line.
    final double lineX = size.width - 70;
    const double dashHeight = 5.0;
    const double dashSpace = 5.0;
    double startY = 24;
    while (startY < size.height - 24) {
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