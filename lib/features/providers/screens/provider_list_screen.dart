import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/provider_directory.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

class ProviderListScreen extends ConsumerWidget {
  const ProviderListScreen(
      {super.key, required this.categoryId, this.category});

  final String categoryId;
  final CategoryModel? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final providers = categoryProvidersProvider(categoryId);
    return ProviderDirectoryPage(
      title: category?.name ?? l10n.providerDirectoryTitle,
      child: ref.watch(providers).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => ProviderDirectoryMessage(
              text: l10n.providerDirectoryError,
              onRetry: () => ref.invalidate(providers),
            ),
            data: (entries) => entries.isEmpty
                ? ProviderDirectoryMessage(text: l10n.providerDirectoryEmpty)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final provider = entries[index];
                      return ProviderSummaryCard(
                        provider: provider,
                        onTap: () => context.push(
                          '/providers/${Uri.encodeComponent(provider.id)}',
                        ),
                      );
                    },
                  ),
          ),
    );
  }
}

/// Profile route handoff for SCRUM-54.
class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({super.key, required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = providerProfileProvider(providerId);
    return ProviderDirectoryPage(
      title: l10n.providerProfileTitle,
      child: ref.watch(profile).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => ProviderDirectoryMessage(
              text: l10n.providerProfileError,
              onRetry: () => ref.invalidate(profile),
            ),
            data: (provider) => provider == null
                ? ProviderDirectoryMessage(
                    text: l10n.providerProfileUnavailable)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [ProviderSummaryCard(provider: provider)],
                  ),
          ),
    );
  }
}

class ProviderDirectoryPage extends StatelessWidget {
  const ProviderDirectoryPage(
      {super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/categories');
            }
          },
        ),
        title: Text(title, style: AppTheme.display(size: 18)),
      ),
      body: SafeArea(child: SpContentWidth(child: child)),
    );
  }
}

class ProviderSummaryCard extends StatelessWidget {
  const ProviderSummaryCard({super.key, required this.provider, this.onTap});

  final ProviderSummary provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final company = provider.type == ProviderType.company;
    final tone = company ? SpTone.brand : SpTone.success;
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(provider.name, style: AppTheme.display(size: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(provider.serviceArea,
                style: AppTheme.text(color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: tone.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  company
                      ? l10n.providerTypeCompany
                      : l10n.providerTypeIndependent,
                  style: AppTheme.text(
                      size: 12,
                      color: tone.foreground,
                      weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        trailing:
            onTap == null ? null : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class ProviderDirectoryMessage extends StatelessWidget {
  const ProviderDirectoryMessage({super.key, required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (onRetry != null)
              TextButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.providerDirectoryRetry)),
          ],
        ),
      ),
    );
  }
}
