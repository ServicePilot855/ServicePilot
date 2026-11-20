import 'package:flutter/material.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/services/models/category_model.dart';

/// Interactive card widget displaying a service category, description, and icon.
///
/// Built according to ServicePilot's "Blue Pipe" design system (DESIGN.md).
/// Corresponds to US-09 (SCRUM-41).
class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          side: const BorderSide(color: AppTheme.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppTheme.primary.withValues(alpha: 0.08),
          highlightColor: AppTheme.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                  ),
                  child: Icon(category.iconData,
                      color: AppTheme.primary, size: 26),
                ),
                const SizedBox(height: 14),
                // Category Title
                Text(
                  category.name,
                  style: AppTheme.display(size: 17),
                ),
                const SizedBox(height: 6),
                // Description
                Text(
                  category.description,
                  style: AppTheme.text(
                    size: 13.5,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (category.popularServices.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: category.popularServices.take(3).map((service) {
                      return Container(
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
                          service,
                          style: AppTheme.text(
                            size: 12,
                            color: AppTheme.textBody,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
