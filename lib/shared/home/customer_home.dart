import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/features/services/providers/category_provider.dart';
import 'package:service_pilot/features/services/widgets/category_card.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_brand.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Customer Home Dashboard.
///
/// Features service categories discovery (US-09 / SCRUM-41) and direct
/// navigation to provider selection.
class CustomerHome extends ConsumerWidget {
  const CustomerHome({super.key});

  void _onCategorySelected(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) {
    ref.read(selectedCategoryProvider.notifier).state = category;
    context.push('/categories/${category.id}/providers', extra: category);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(authProvider.notifier).currentUser;
    final name = user?.fullName ?? l10n.homeFallbackName;
    final firstName = name.trim().split(RegExp(r'\s+')).first;
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.gutter),
          child: SpContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar / Identity row
                Row(
                  children: [
                    const SpLogoMark(size: 34),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ServicePilot',
                          style: AppTheme.display(size: 18),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Phnom Penh',
                              style: AppTheme.text(
                                size: 12,
                                weight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Logout button
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      tooltip: 'Log out',
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Greeting Hero
                Text(
                  'Hello, $firstName 👋',
                  style: AppTheme.display(size: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  'What repair or maintenance service do you need today?',
                  style: AppTheme.text(
                    size: 15,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),

                // Search quick action
                InkWell(
                  key: const Key('customer_home_search_bar'),
                  onTap: () => context.push('/categories'),
                  borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusControl),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Search AC, plumbing, electrical...',
                          style: AppTheme.text(
                            size: 14.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusChip),
                          ),
                          child: Text(
                            'Browse',
                            style: AppTheme.text(
                              size: 11,
                              weight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Categories Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Repair Categories',
                      style: AppTheme.display(size: 18),
                    ),
                    TextButton(
                      key: const Key('view_all_categories_button'),
                      onPressed: () => context.push('/categories'),
                      child: Text(
                        'See all',
                        style: AppTheme.text(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Categories List / Stream
                categoriesAsync.when(
                  data: (categories) {
                    return Column(
                      children: categories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CategoryCard(
                            key: Key('home_category_${cat.id}'),
                            category: cat,
                            onTap: () =>
                                _onCategorySelected(context, ref, cat),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  error: (err, _) => SpNotice(
                    icon: Icons.error_outline_rounded,
                    message: 'Could not load categories: $err',
                    tone: SpTone.danger,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
