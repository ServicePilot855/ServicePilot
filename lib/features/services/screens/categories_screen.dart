import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/features/services/providers/category_provider.dart';
import 'package:service_pilot/features/services/widgets/category_card.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Screen allowing customers to browse and search all available repair categories.
///
/// Implements US-09 (SCRUM-41).
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(CategoryModel category) {
    if (category.hasAvailableProviders) {
      ref.read(selectedCategoryProvider.notifier).state = category;
      context.push(
        '/categories/${category.id}/providers',
        extra: category,
      );
    } else {
      _showEmptyCategoryDialog(category);
    }
  }

  void _showEmptyCategoryDialog(CategoryModel category) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('empty_category_dialog'),
        backgroundColor: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentSoft,
                borderRadius: BorderRadius.circular(AppTheme.radiusControl),
              ),
              child: const Icon(
                Icons.handyman_outlined,
                color: AppTheme.accentDeep,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No Providers Available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'There are currently no verified service providers listed for "${category.name}" in Phnom Penh.',
              style: AppTheme.text(
                size: 14.5,
                color: AppTheme.textBody,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const SpNotice(
              icon: Icons.info_outline_rounded,
              message:
                  'Our team is actively onboarding licensed technicians for this service area.',
              tone: SpTone.waiting,
            ),
          ],
        ),
        actions: [
          SpPrimaryButton(
            key: const Key('empty_category_dialog_ok'),
            label: 'Explore Other Services',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Repair & Maintenance',
          style: AppTheme.display(size: 20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: SpContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                0,
                AppTheme.gutter,
                12,
              ),
              child: SizedBox(
                height: 48,
                child: TextField(
                  key: const Key('category_search_field'),
                  controller: _searchController,
                  style: AppTheme.text(size: 15, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    fillColor: AppTheme.surfaceElevated,
                    hintText: 'Search categories or services...',
                    hintStyle: AppTheme.text(size: 14.5, color: AppTheme.textSecondary),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppTheme.textSecondary,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(categoryQueryProvider.notifier).state = '';
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                  onChanged: (val) {
                    ref.read(categoryQueryProvider.notifier).state = val;
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: SpContentWidth(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SpStatusHero(
                        icon: Icons.search_off_rounded,
                        title: 'No Categories Found',
                        message:
                            'No repair categories match your current search terms.',
                        tone: SpTone.neutral,
                      ),
                      const SizedBox(height: 20),
                      SpSecondaryButton(
                        label: 'Clear Search',
                        onPressed: () {
                          _searchController.clear();
                          ref.read(categoryQueryProvider.notifier).state = '';
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
              child: ListView.separated(
                key: const Key('categories_list_view'),
                padding: const EdgeInsets.all(AppTheme.gutter),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return CategoryCard(
                    key: Key('category_card_${cat.id}'),
                    category: cat,
                    onTap: () => _onCategorySelected(cat),
                  );
                },
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.error,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load categories',
                  style: AppTheme.display(size: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: AppTheme.text(size: 13.5, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                SpPrimaryButton(
                  label: 'Try Again',
                  onPressed: () => ref.refresh(categoriesListProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
