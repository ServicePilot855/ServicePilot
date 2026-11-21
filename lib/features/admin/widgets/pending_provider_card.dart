import 'package:flutter/material.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/widgets/provider_type_badge.dart';

/// Card displaying a technician or company account awaiting administrative review.
///
/// Complies with DESIGN.md ("The Waiting Rule" with Tape Yellow badge,
/// Flat card layout, and cool neutral borders).
class PendingProviderCard extends StatelessWidget {
  const PendingProviderCard({
    super.key,
    required this.provider,
    this.onTap,
  });

  final ProviderModel provider;
  final VoidCallback? onTap;

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recently';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBusiness = provider.businessName != null &&
        provider.businessName!.trim().isNotEmpty &&
        provider.businessName != provider.name;

    final coverage = provider.coverageAreas.isNotEmpty
        ? provider.coverageAreas.join(', ')
        : provider.serviceArea;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Name & Provider Type Badge ────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: AppTheme.text(
                        size: 16.5,
                        weight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    if (hasBusiness) ...[
                      const SizedBox(height: 2),
                      Text(
                        provider.businessName!,
                        style: AppTheme.text(
                          size: 13.5,
                          weight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              ProviderTypeBadge(type: provider.type),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // ── Pending Verification Status Badge (The Waiting Rule) ──────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.accentSoft,
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppTheme.accentDeep,
                ),
                const SizedBox(width: 6),
                Text(
                  'Pending Verification',
                  style: AppTheme.text(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: AppTheme.accentDeep,
                  ),
                ),
                if (provider.createdAt != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '• ${_formatDate(provider.createdAt)}',
                    style: AppTheme.text(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppTheme.accentDeep,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Bio or Description ────────────────────────────────────────────
          if (provider.description.isNotEmpty || provider.bio.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              provider.bio.isNotEmpty ? provider.bio : provider.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.text(
                size: 14,
                weight: FontWeight.w400,
                color: AppTheme.textBody,
                height: 1.45,
              ),
            ),
          ],

          const SizedBox(height: AppTheme.spacingMd),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: AppTheme.spacingMd),

          // ── Contact Details & Coverage ────────────────────────────────────
          if (provider.phone.isNotEmpty) ...[
            _DetailRow(
              icon: Icons.phone_outlined,
              label: provider.phone,
            ),
            const SizedBox(height: 6),
          ],
          if (provider.email.isNotEmpty) ...[
            _DetailRow(
              icon: Icons.email_outlined,
              label: provider.email,
            ),
            const SizedBox(height: 6),
          ],
          if (coverage.isNotEmpty) ...[
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: coverage,
            ),
            const SizedBox(height: 6),
          ],

          // ── Specialties / Category Tags ───────────────────────────────────
          if (provider.specialties.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: provider.specialties.map((specialty) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Text(
                    specialty,
                    style: AppTheme.text(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTheme.text(
              size: 13.5,
              weight: FontWeight.w500,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
