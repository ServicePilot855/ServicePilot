import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service_pilot/core/theme/app_theme.dart';

/// Screen matching Figma '00 Demo Role Select'.
///
/// Features:
/// - Dark background `#0A0A0A`
/// - Logo & Title: "Choose your role"
/// - Subtitle: "Explore ServicePilot from each user's point of view."
/// - Surface Cards `#17181B` with 16px corner radius and Border `#2A2B31`
/// - Orange IconBoxes `#FF5000` (opacity 12%) with rounded 12px corners
/// - White Title, Secondary Text `#9AA0AA`, and Chevron Right
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Logo & Wordmark ─────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ServicePilot',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Title & Subtitle ───────────────────────────────────────────
              Text(
                'Create an Account',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your role to get started with ServicePilot in Phnom Penh.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // ── Role Cards matching Figma Node 1941 ────────────────────────
              _RoleCard(
                icon: Icons.calendar_today_rounded,
                title: 'Homeowner',
                desc: 'Find, book and track home services',
                onTap: () => context.push('/register/customer'),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                icon: Icons.build_rounded,
                title: 'Service provider',
                desc: 'Accept requests, send quotes, update jobs',
                onTap: () => context.push('/register/technician'),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                icon: Icons.business_center_rounded,
                title: 'Service company',
                desc: 'Assign technicians to customer bookings',
                onTap: () => context.push('/register/company'),
              ),
              const SizedBox(height: 36),

              // ── Switch to Login ───────────────────────────────────────────
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Log in',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Footer ────────────────────────────────────────────────────
              Center(
                child: Text(
                  'Student startup prototype · Phnom Penh · Sample data only',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        splashColor: AppTheme.primary.withValues(alpha: 0.1),
        highlightColor: AppTheme.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.border, width: 1.0),
          ),
          child: Row(
            children: [
              // Icon Box with 12% orange tint
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusIconBox),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              // Title & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
