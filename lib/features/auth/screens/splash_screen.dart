import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_brand.dart';

/// Launch screen: the mark and name on Pipe Blue while the session is
/// checked. Routes onward after 2.5 seconds.
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
      duration: const Duration(milliseconds: 350),
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
    final l10n = context.l10n;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.primary,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SpLogoMark(size: 88, onBrand: true),
                            const SizedBox(height: 24),
                            Text(
                              l10n.appName,
                              textAlign: TextAlign.center,
                              style: AppTheme.display(
                                size: 40,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.splashTagline,
                              textAlign: TextAlign.center,
                              style: AppTheme.text(
                                size: 16.5,
                                weight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    l10n.splashFootnote,
                    textAlign: TextAlign.center,
                    style: AppTheme.text(
                      size: 12.5,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
