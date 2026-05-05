import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/screens/login_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  double _dragX = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 850),
        pageBuilder: (_, animation, __) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.85, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragX += details.delta.dx;
      _dragX = _dragX.clamp(0, 120);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragX > 80) {
      _goToLogin();
    } else {
      setState(() => _dragX = 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D0820),
              Color(0xFF17102E),
              Color(0xFF281A46),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _SpacePainter())),
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final h = constraints.maxHeight;
                      final isSmall = h < 720;
                      final isVerySmall = h < 650;

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 20 : 24,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: isVerySmall ? 28 : isSmall ? 42 : 70),

                            SizedBox(
                              width: isVerySmall ? 95 : isSmall ? 110 : 130,
                              height: isVerySmall ? 95 : isSmall ? 110 : 130,
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),

                            SizedBox(height: isVerySmall ? 18 : isSmall ? 22 : 30),

                            Text(
                              'KTR Event',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.goldman(
                                fontSize: isVerySmall ? 29 : isSmall ? 32 : 38,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                letterSpacing: 0.7,
                              ),
                            ),

                            SizedBox(height: isVerySmall ? 24 : isSmall ? 28 : 38),

                            _PurpleTicketParagraph(
                              isSmall: isSmall,
                              isVerySmall: isVerySmall,
                            ),

                            SizedBox(height: isVerySmall ? 24 : isSmall ? 28 : 38),

                            Text(
                              'Swipe to Start',
                              style: GoogleFonts.quicksand(
                                color: Colors.white.withOpacity(0.88),
                                fontSize: isSmall ? 14 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 14),

                            _SwipeButton(
                              dragX: _dragX,
                              isSmall: isSmall,
                              onDragUpdate: _onDragUpdate,
                              onDragEnd: _onDragEnd,
                            ),

                            const Spacer(),
                          ],
                        ),
                      );
                    },
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

class _SwipeButton extends StatelessWidget {
  final double dragX;
  final bool isSmall;
  final Function(DragUpdateDetails) onDragUpdate;
  final Function(DragEndDetails) onDragEnd;

  const _SwipeButton({
    required this.dragX,
    required this.isSmall,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final width = isSmall ? 170.0 : 190.0;
    final maxDrag = width - 58;

    return Container(
      width: width,
      height: 58,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.30)),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Icon(
              Icons.keyboard_double_arrow_right_rounded,
              color: Colors.white.withOpacity(0.35),
              size: 30,
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            left: dragX.clamp(0, maxDrag),
            top: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: onDragUpdate,
              onHorizontalDragEnd: onDragEnd,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.16),
                  border: Border.all(color: Colors.white.withOpacity(0.45)),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurpleTicketParagraph extends StatelessWidget {
  final bool isSmall;
  final bool isVerySmall;

  const _PurpleTicketParagraph({
    required this.isSmall,
    required this.isVerySmall,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TicketClipper(),
      child: Container(
        width: double.infinity,
        height: isVerySmall ? 128 : isSmall ? 138 : 155,
        decoration: BoxDecoration(
          color: const Color(0xFF6F45C9).withOpacity(0.94),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _TicketDetailsPainter(),
              ),
            ),
            Positioned(
              left: isSmall ? 26 : 30,
              right: isSmall ? 82 : 96,
              top: isVerySmall ? 18 : isSmall ? 23 : 31,
              bottom: isVerySmall ? 18 : isSmall ? 23 : 30,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: isSmall ? 220 : 255,
                    child: Text(
                      'Manage student events, club activities, registrations, equipment, '
                          'and approvals in one secure mobile platform built for KTR community users.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.bodoniModa(
                        color: Colors.white,
                        fontSize: isVerySmall ? 12.2 : isSmall ? 13 : 14.3,
                        height: 1.42,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: isSmall ? 22 : 26,
              top: isVerySmall ? 22 : 26,
              bottom: isVerySmall ? 22 : 26,
              child: CustomPaint(
                size: Size(isSmall ? 34 : 42, isSmall ? 86 : 98),
                painter: _BarcodePainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketDetailsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFBFA8FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.58)
      ..strokeWidth = 1.2;

    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(14, 14, size.width - 28, size.height - 28),
      const Radius.circular(18),
    );

    canvas.drawRRect(innerRect, borderPaint);

    final lineX = size.width - 82;
    for (double y = 21; y < size.height - 21; y += 8) {
      canvas.drawLine(Offset(lineX, y), Offset(lineX, y + 4), dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final widths = [2.0, 1.0, 3.0, 1.0, 2.5, 1.0, 1.8, 3.0, 1.0, 2.0];
    double x = 0;

    for (final w in widths) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..strokeWidth = w;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += w + 3;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const r = 22.0;
    const sideNotch = 18.0;
    const smallCut = 10.0;

    final path = Path();

    path.moveTo(r, 0);
    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(
      size.width - smallCut,
      0,
      size.width - smallCut,
      smallCut,
    );
    path.lineTo(size.width - smallCut, r);
    path.quadraticBezierTo(size.width, r, size.width, r + smallCut);

    path.lineTo(size.width, size.height / 2 - sideNotch);
    path.arcToPoint(
      Offset(size.width, size.height / 2 + sideNotch),
      radius: const Radius.circular(sideNotch),
      clockwise: false,
    );

    path.lineTo(size.width, size.height - r - smallCut);
    path.quadraticBezierTo(
      size.width,
      size.height - r,
      size.width - smallCut,
      size.height - r,
    );
    path.lineTo(size.width - smallCut, size.height - smallCut);
    path.quadraticBezierTo(
      size.width - smallCut,
      size.height,
      size.width - r,
      size.height,
    );

    path.lineTo(r, size.height);
    path.quadraticBezierTo(
      smallCut,
      size.height,
      smallCut,
      size.height - smallCut,
    );
    path.lineTo(smallCut, size.height - r);
    path.quadraticBezierTo(0, size.height - r, 0, size.height - r - smallCut);

    path.lineTo(0, size.height / 2 + sideNotch);
    path.arcToPoint(
      Offset(0, size.height / 2 - sideNotch),
      radius: const Radius.circular(sideNotch),
      clockwise: false,
    );

    path.lineTo(0, r + smallCut);
    path.quadraticBezierTo(0, r, smallCut, r);
    path.lineTo(smallCut, smallCut);
    path.quadraticBezierTo(smallCut, 0, r, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SpacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(7);

    for (int i = 0; i < 95; i++) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(random.nextDouble() * 0.45);

      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() * 1.5 + 0.4,
        paint,
      );
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8C5CFF).withOpacity(0.26),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.85),
          radius: 260,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.85),
      260,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}