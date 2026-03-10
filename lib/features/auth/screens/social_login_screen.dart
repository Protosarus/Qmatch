import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/navigation/auth_wrapper.dart';
import 'login_screen.dart';

// Social login screen — Welcome + Apple/Google + email/password + CTA + footer
const Color _loginGold = AppColors.primary; // unified brand gold
const Color _loginDividerText = Color(0xFFB8B8B8);

class SocialLoginScreen extends StatefulWidget {
  const SocialLoginScreen({super.key});

  @override
  State<SocialLoginScreen> createState() => _SocialLoginScreenState();
}

class _SocialLoginScreenState extends State<SocialLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Please try again'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // Title
                  Text(
                    'Welcome',
                    style: GoogleFonts.playfairDisplay(
                      color: _loginGold,
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to QMatch',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Continue with Apple
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        // Social login — Apple
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _loginGold,
                        side: const BorderSide(
                          color: _loginGold,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.apple,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Apple',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Continue with Google
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        // Social login — Google
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _loginGold,
                        side: const BorderSide(
                          color: _loginGold,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _GoogleLogo(size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            // Text style follows theme default; matches original
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider: or continue with email
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: _loginGold.withValues(alpha: 0.4),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with email',
                          style: GoogleFonts.inter(
                            color: _loginDividerText,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: _loginGold.withValues(alpha: 0.4),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(
                          color: _loginGold,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(
                          color: _loginGold,
                          width: 2,
                        ),
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(color: AppColors.error),
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(
                          color: AppColors.error,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(
                          color: _loginGold,
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(
                          color: _loginGold,
                          width: 2,
                        ),
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(color: AppColors.error),
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(
                          color: AppColors.error,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
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
                  const SizedBox(height: 12),

                  // Forgot password?
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Forgot password
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: _loginGold,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot password?',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Primary button: Sign Up (label), same style as Login
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _loginGold,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.background,
                                ),
                              ),
                            )
                          : Text(
                              'Sign Up',
                              style: GoogleFonts.inter(
                                color: AppColors.background,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Footer: Already have an account? Log in
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Already have an account? Log in',
                        style: GoogleFonts.inter(
                          color: _loginGold,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              color: _loginGold,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  final double size;

  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.45
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius * 0.82);

    void arc(Color color, double startDeg, double sweepDeg) {
      stroke.color = color;
      canvas.drawArc(
        rect,
        startDeg * 3.141592653589793 / 180,
        sweepDeg * 3.141592653589793 / 180,
        false,
        stroke,
      );
    }

    arc(_blue, -40, 110);
    arc(_red, 70, 90);
    arc(_yellow, 160, 70);
    arc(_green, 230, 90);

    final barPaint = Paint()
      ..color = _blue
      ..style = PaintingStyle.fill;
    final barHeight = radius * 0.22;
    final barWidth = radius * 0.9;
    final barRect = Rect.fromCenter(
      center: Offset(center.dx + radius * 0.25, center.dy),
      width: barWidth,
      height: barHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, Radius.circular(barHeight / 2)),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



