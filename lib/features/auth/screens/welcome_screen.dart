import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_screen.dart';
import 'login_screen.dart';
import '../../../core/theme/app_colors.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoOpacity;
  late Animation<double> _taglineOpacity;
  late Animation<double> _taglineSlide;
  late Animation<double> _textBlockOpacity;
  late Animation<double> _buttonsOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.5, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _textBlockOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.55, curve: Curves.easeOut),
      ),
    );

    _buttonsOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // QMatch Logo — fade in
              FadeTransition(
                opacity: _logoOpacity,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/logo_white.png',
                    width: 313,
                    height: 215,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Tagline — slide up + fade
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _taglineSlide.value),
                    child: Opacity(
                      opacity: _taglineOpacity.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Match minds.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Not just faces.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle + hint — fade in
              FadeTransition(
                opacity: _textBlockOpacity,
                child: Column(
                  children: [
                    Text(
                      'Discover people who share your frequency.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFC8C8C8),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your match might already be here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFA8A8A8),
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.35,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Buttons — fade in after text
              FadeTransition(
                opacity: _buttonsOpacity,
                child: Column(
                  children: [
                    // Sign Up Button (Primary — flat gold)
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Login Button (Secondary — outline only)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.primary, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
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
                            'Login',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
