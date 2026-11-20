import 'package:flutter/material.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/services/models/category_model.dart';

/// A compact entry into a repair category.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final examples = category.popularServices.isEmpty
        ? category.description
        : category.popularServices.take(3).join(' · ');
    return Semantics(
      button: true,
      child: Material(
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          side: const BorderSide(color: AppTheme.browseBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          focusColor: AppTheme.primarySoft,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.browseFill,
                    borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                  ),
                  child: Icon(
                    category.iconData,
                    color: AppTheme.browseInk,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: AppTheme.display(
                          size: 17,
                          color: AppTheme.browseInk,
                          height: 1.5,
                        ),
                      ),
                      if (examples.trim().isNotEmpty)
                        Text(
                          examples,
                          style: AppTheme.text(
                            size: 13.5,
                            color: AppTheme.browseSecondary,
                            height: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
