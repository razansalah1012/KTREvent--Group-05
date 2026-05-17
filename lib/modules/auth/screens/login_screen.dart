import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Bring in the register screen so we can navigate to it when the user
// taps the “Register” link. This import uses a relative path because
// both login and register screens live in the same directory under
// `lib/modules/auth/screens/`.
import 'register_screen.dart';

// Import the student dashboard so we can route logged‑in students to
// their home page. Admin and club member dashboards are represented
// by placeholders for now but can be swapped out when available.
import '../../student/screens/student_dashboard_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  /// Sends a password reset email to the address currently entered
  /// in the email field. If the field is empty, an error message is
  /// shown instead. Upon success a snackbar is displayed to confirm
  /// that a reset link has been sent.
  Future<void> _resetPassword() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email first.';
      });
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Please check your inbox.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Failed to send reset email.';
      });
    }
  }

  /// Attempts to sign in with the provided email and password. If
  /// successful, verifies the user’s email, retrieves the role and
  /// status from Firestore, and routes them to the appropriate
  /// dashboard. Failure scenarios update [_errorMessage] so the UI can
  /// display a friendly message. This method also sends a verification
  /// email if the user hasn’t already verified their account.
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final UserCredential credential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final User user = credential.user!;
      // Check if email is verified; if not, send a new verification
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        setState(() {
          _errorMessage =
          'Email not verified. A verification link has been sent.';
          _isLoading = false;
        });
        return;
      }
      // Retrieve user data from Firestore
      final DocumentSnapshot<Map<String, dynamic>> doc =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        setState(() {
          _errorMessage =
          'User profile not found. Please contact support.';
          _isLoading = false;
        });
        return;
      }
      final Map<String, dynamic>? data = doc.data();
      final String role = data?['role'] ?? '';
      final String status = data?['status'] ?? '';
      if (status == 'pending') {
        setState(() {
          _errorMessage =
          'Your account is pending approval. Please wait for admin approval.';
          _isLoading = false;
        });
        return;
      }
      if (status == 'rejected') {
        setState(() {
          _errorMessage =
          'Your registration was rejected. Please contact an administrator.';
          _isLoading = false;
        });
        return;
      }
      // Determine which dashboard to navigate to. Replace the
      // placeholders for admin and club member with real screens
      // when those dashboards are implemented.
      Widget dashboard;
      if (role == 'admin') {
        dashboard = const Placeholder();
      } else if (role == 'club_member') {
        dashboard = const Placeholder();
      } else {
        dashboard = const StudentDashboardScreen();
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => dashboard),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Login failed.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final bool isSmall = height < 720;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF110d27),
              Color(0xFF1e1533),
              Color(0xFF2a2147),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 22 : 32,
              vertical: 24,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: EdgeInsets.all(isSmall ? 22 : 28),
              decoration: BoxDecoration(
                color: const Color(0xFF241b3d),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header showing the app name
                  Text(
                    'KTR Event',
                    style: GoogleFonts.goldman(
                      fontSize: isSmall ? 26 : 30,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 26),
                  // Title and subtitle
                  Text(
                    'Welcome Back',
                    style: GoogleFonts.poppins(
                      fontSize: isSmall ? 26 : 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sign in to continue',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.quicksand(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            labelStyle: GoogleFonts.quicksand(color: Colors.white70),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF9B6CFF), width: 2),
                            ),
                            errorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent),
                            ),
                            focusedErrorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: GoogleFonts.quicksand(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            labelStyle: GoogleFonts.quicksand(color: Colors.white70),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF9B6CFF), width: 2),
                            ),
                            errorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent),
                            ),
                            focusedErrorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.quicksand(
                                color: const Color(0xFFBE9AF4),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // Error message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.quicksand(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8257E5),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white70,
                              disabledBackgroundColor:
                              const Color(0xFF8257E5).withOpacity(0.55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                              'Login',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Register link
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4.0,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: GoogleFonts.quicksand(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          "Register",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFFBE9AF4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}