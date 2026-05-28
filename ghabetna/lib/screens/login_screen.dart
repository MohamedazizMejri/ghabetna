import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'agent/agent_screen.dart';
import 'supervisor/supervisor_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  // ── Color palette (forest/nature theme matching your app name "Ghabetna") ──
  static const Color _primaryGreen   = Color(0xFF2D6A4F); // deep forest green
  static const Color _accentGreen    = Color(0xFF52B788);  // lighter green for accents
  static const Color _bgColor        = Color(0xFFF8FAF8);  // near-white with green tint
  static const Color _cardColor      = Colors.white;
  static const Color _textPrimary    = Color(0xFF1B1B1B);
  static const Color _textSecondary  = Color(0xFF6B7280);
  static const Color _borderColor    = Color(0xFFD1D5DB);

  void login() async {
    setState(() => isLoading = true);
    try {
      final user = await ApiService.login(
        emailController.text.trim(),
        passwordController.text,
      );
      String role = user["role"];
      if (!mounted) return;

      if (role == "admin") {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => DashboardScreen(user: user)));
      } else if (role == "superviseur") {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => SupervisorScreen(user: user)));
      } else if (role == "agent") {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => AgentScreen(user: user)));
      } else {
        _showError("Unknown role. Please contact your administrator.");
      }
    } catch (e) {
      _showError("Login failed. Check your credentials and try again.");
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(                // handles small screens / keyboard
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: screenHeight
                  - MediaQuery.of(context).padding.top     // status bar
                  - MediaQuery.of(context).padding.bottom, // nav bar / home indicator
              ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // ── TOP SPACER ──────────────────────────────────────────
                  SizedBox(height: screenHeight * 0.08),

                  // ── LOGO ────────────────────────────────────────────────
                  // Positioned in the upper-center — the natural focal point
                  // before the user's eyes travel down to the form.
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: _cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryGreen.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/images/logo.png',  // ← your logo file
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── APP NAME ────────────────────────────────────────────
                  Text(
                    'Ghabetna',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _primaryGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Forest Management System',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.06),

                  // ── CARD FORM ───────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── HEADING ───────────────────────────────────────
                        Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to your account',
                          style: TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── EMAIL FIELD ───────────────────────────────────
                        Text(
                          'Email address',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          style: TextStyle(color: _textPrimary, fontSize: 15),
                          decoration: _inputDecoration(
                            hint: 'you@example.com',
                            icon: Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── PASSWORD FIELD ────────────────────────────────
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          obscureText: _obscurePassword, // ← controlled by state
                          style: TextStyle(color: _textPrimary, fontSize: 15),
                          decoration: _inputDecoration(
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                          ).copyWith(
                            // ── EYE TOGGLE ──────────────────────────────
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── LOGIN BUTTON ──────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryGreen,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  _primaryGreen.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── BOTTOM SPACER ────────────────────────────────────────
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      '© 2025 Ghabetna SMART FOR GREEN. All rights reserved.',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecondary.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared input decoration factory ────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5), fontSize: 14),
      prefixIcon: Icon(icon, color: _textSecondary, size: 20),
      filled: true,
      fillColor: _bgColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _accentGreen, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
      ),
    );
  }
}