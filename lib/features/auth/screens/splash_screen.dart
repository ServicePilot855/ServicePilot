import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';

/// Splash screen matching Figma '01 Welcome' dark aesthetics.
///
/// Features:
/// - Background: `#0A0A0A`
/// - ServicePilot logo mark: vibrant orange `#FF5000` with map pin/home
/// - Orbiting home service badges: Plumbing, Electrical, AC, Cleaning
/// - Tagline: "Home services, booked in one place."
/// - Description: "Book trusted plumbers, electricians, AC technicians and cleaners across Phnom Penh."
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    // Check if user session already exists in Firebase
    ref.read(authProvider.notifier).checkAuthStatus();

    // Auto navigate after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState is AuthStateAuthenticated) {
      context.go(authState.user.role.homeRoute);
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // ── Hero Illustration matching Figma Frame 528 ─────────────
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Orbit glow ring
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      // Core logo icon
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.home_repair_service_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                      // Floating category badge: AC
                      Positioned(
                        top: 4,
                        right: 8,
                        child: _categoryBadge(Icons.ac_unit_rounded),
                      ),
                      // Floating category badge: Electrical
                      Positioned(
                        bottom: 6,
                        left: 8,
                        child: _categoryBadge(Icons.bolt_rounded),
                      ),
                      // Floating category badge: Plumbing
                      Positioned(
                        top: 6,
                        left: 8,
                        child: _categoryBadge(Icons.water_drop_rounded),
                      ),
                      // Floating category badge: Cleaning
                      Positioned(
                        bottom: 4,
                        right: 8,
                        child: _categoryBadge(Icons.cleaning_services_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // ── Wordmark & Mark ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.build_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ServicePilot',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Tagline (Figma Copy) ───────────────────────────────────
                  Text(
                    'Home services, booked in one place.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Description (Figma Copy) ───────────────────────────────
                  Text(
                    'Book trusted plumbers, electricians, AC technicians and cleaners across Phnom Penh.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                      height: 1.45,
                    ),
                  ),

                  const Spacer(),

                  // ── Footer Note ───────────────────────────────────────────
                  Text(
                    'Student prototype · Phnom Penh · Sample data only',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryBadge(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border, width: 1.0),
      ),
      child: Icon(
        icon,
        size: 16,
        color: AppTheme.primary,
      ),
    );
  }
}
