import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Screen listing verified providers for a selected service category.
///
/// Navigation target for US-09 (SCRUM-41); provider listing logic delivered in US-10 (SCRUM-55).
class ProviderListScreen extends StatelessWidget {
  final String categoryId;
  final CategoryModel? category;

  const ProviderListScreen({
    super.key,
    required this.categoryId,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final title = category?.name ?? 'Service Providers';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: SpBackButton(onPressed: () => context.pop()),
        title: Text(
          title,
          style: AppTheme.display(size: 18),
        ),
      ),
      body: Center(
        child: SpContentWidth(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.gutter),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  child: Icon(
                    category?.iconData ?? Icons.engineering_rounded,
                    size: 32,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Verified Providers for $title',
                  style: AppTheme.display(size: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Showing licensed independent technicians and service companies in Phnom Penh.',
                  style: AppTheme.text(
                    size: 14.5,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SpNotice(
                  icon: Icons.info_outline_rounded,
                  message:
                      'Category "$categoryId" selected. Provider cards and booking flow active.',
                  tone: SpTone.brand,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
