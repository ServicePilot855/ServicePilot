import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/features/services/providers/category_provider.dart';
import 'package:service_pilot/features/services/widgets/category_card.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Browse and search available repair categories.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(categoryQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(categoryQueryProvider.notifier).state = '';
  }

  void _openCategory(CategoryModel category) {
    ref.read(selectedCategoryProvider.notifier).state = category;
    context.push('/categories/${category.id}/providers', extra: category);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesListProvider);
    final query = ref.watch(categoryQueryProvider);

    return Scaffold(
      backgroundColor: AppTheme.browseBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: SpBackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home/customer'),
        ),
        title: Text(
          l10n.discoveryCategoriesTitle,
          style: AppTheme.display(size: 18, color: AppTheme.browseInk),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SpContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  key: const Key('category_search_field'),
                  controller: _searchController,
                  style: AppTheme.text(
                    size: 15,
                    height: 1.5,
                    color: AppTheme.browseInk,
                  ),
                  decoration: InputDecoration(
                    fillColor: AppTheme.surface,
                    labelText: l10n.discoverySearchLabel,
                    labelStyle: AppTheme.text(color: AppTheme.browseSecondary),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.discoveryClearSearch,
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: _clearSearch,
                          ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusControl),
                      borderSide: const BorderSide(
                        color: AppTheme.browseControlBorder,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(categoryQueryProvider.notifier).state = value;
                  },
                ),
              ),
              Expanded(
                child: categories.when(
                  data: (items) {
                    if (items.isEmpty) {
                      final searching = query.trim().isNotEmpty;
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          SpNotice(
                            icon: Icons.search_off_rounded,
                            message: searching
                                ? l10n.discoveryNoMatchingCategories
                                : l10n.discoveryNoCategories,
                            tone: SpTone.neutral,
                          ),
                          if (searching) ...[
                            const SizedBox(height: 12),
                            SpSecondaryButton(
                              label: l10n.discoveryClearSearch,
                              outlineColor: AppTheme.browseControlBorder,
                              wrapLabel: true,
                              onPressed: _clearSearch,
                            ),
                          ],
                        ],
                      );
                    }
                    return ListView.separated(
                      key: const Key('categories_list_view'),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final category = items[index];
                        return CategoryCard(
                          key: Key('category_card_${category.id}'),
                          category: category,
                          onTap: () => _openCategory(category),
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: l10n.discoveryLoadingCategories,
                    ),
                  ),
                  error: (_, __) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SpNotice(
                        icon: Icons.error_outline_rounded,
                        message: l10n.discoveryCategoriesError,
                        tone: SpTone.danger,
                      ),
                      const SizedBox(height: 12),
                      SpPrimaryButton(
                        label: l10n.providerDirectoryRetry,
                        wrapLabel: true,
                        onPressed: () => ref.invalidate(categoriesListProvider),
                      ),
                    ],
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
