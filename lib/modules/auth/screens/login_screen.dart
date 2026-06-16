import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razakevent/modules/admin/screens/admin_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_translations.dart';

import 'register_screen.dart';
import '../../student/screens/student_dashboard_screen.dart';
import '../../club_member/screens/club_dashboard_screen.dart';

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
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
    setState(() {
      _lang = langCode;
    });
  }

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

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      final User user = credential.user!;

      final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        setState(() {
          _errorMessage = 'User profile not found. Please contact support.';
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

      Widget dashboard;
      if (role == 'admin') {
        dashboard = const AdminDashboardScreen();
      } else if (role == 'club_member') {
        dashboard = const ClubDashboardScreen();
      } else {
        dashboard = const StudentDashboardScreen();
      }
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => dashboard));
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF110d27),
        elevation: 0,
        actions: [
          DropdownButton<String>(
            value: _lang,
            dropdownColor: const Color(0xFF241B3A),
            icon: const Icon(Icons.language, color: Colors.white),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: 'en',
                child: Text('EN', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'ms',
                child: Text('MS', style: TextStyle(color: Colors.white)),
              ),
            ],
            onChanged: (val) {
              if (val != null) _setLanguage(val);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF110d27), Color(0xFF1e1533), Color(0xFF2a2147)],
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
                  Text(
                    AppTranslations.get(_lang, 'welcome_back'),
                    style: GoogleFonts.poppins(
                      fontSize: isSmall ? 26 : 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppTranslations.get(_lang, 'login_to_continue'),
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
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.quicksand(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: AppTranslations.get(_lang, 'email'),
                            prefixIcon: const Icon(Icons.email_outlined),
                            labelStyle: GoogleFonts.quicksand(
                              color: Colors.white70,
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFF9B6CFF),
                                width: 2,
                              ),
                            ),
                            errorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent),
                            ),
                            focusedErrorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.redAccent,
                                width: 2,
                              ),
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
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: GoogleFonts.quicksand(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: AppTranslations.get(_lang, 'password'),
                            prefixIcon: const Icon(Icons.lock_outline),
                            labelStyle: GoogleFonts.quicksand(
                              color: Colors.white70,
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFF9B6CFF),
                                width: 2,
                              ),
                            ),
                            errorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent),
                            ),
                            focusedErrorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.redAccent,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: Text(
                              AppTranslations.get(_lang, 'forgot_password'),
                              style: GoogleFonts.quicksand(
                                color: const Color(0xFFBE9AF4),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
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
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8257E5),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white70,
                              disabledBackgroundColor: const Color(
                                0xFF8257E5,
                              ).withOpacity(0.55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    AppTranslations.get(_lang, 'login'),
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
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4.0,
                    children: [
                      Text(
                        AppTranslations.get(_lang, 'dont_have_account'),
                        style: GoogleFonts.quicksand(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          AppTranslations.get(_lang, 'register_here'),
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
