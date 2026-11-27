import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
import 'package:service_pilot/features/services/models/category_model.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';
import 'package:service_pilot/features/services/providers/category_provider.dart';
import 'package:service_pilot/features/services/providers/offering_provider.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/sp_text_field.dart';

/// Screen allowing providers and company account managers to publish a new
/// service offering in either Fixed-Price or Quote-Required mode.
///
/// Shared form for SCRUM-76 and SCRUM-77.
class CreateOfferingScreen extends ConsumerStatefulWidget {
  const CreateOfferingScreen({
    super.key,
    this.initialCategoryId,
    this.initialProviderId,
  });

  final String? initialCategoryId;
  final String? initialProviderId;

  @override
  ConsumerState<CreateOfferingScreen> createState() =>
      _CreateOfferingScreenState();
}

class _CreateOfferingScreenState extends ConsumerState<CreateOfferingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();

  String? _selectedCategoryId;
  OfferingPricingMode _pricingMode = OfferingPricingMode.quoteRequired;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(ref.read(currentUserProvider)?.role.homeRoute ?? '/login');
    }
  }

  Future<void> _submitOffering(List<CategoryModel> categories) async {
    if (_isSubmitting) return;
    final l10n = context.l10n;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final categoryId = _selectedCategoryId;
    if (categoryId == null ||
        !categories.any((category) => category.id == categoryId)) {
      setState(() => _errorMessage = l10n.offeringCategoryRequired);
      return;
    }

    final user = ref.read(currentUserProvider);
    final isFixed = _pricingMode == OfferingPricingMode.fixed;
    if (user == null ||
        !(user.isIndependentTechnician ||
            user.isCompany ||
            (!isFixed && user.isAdmin))) {
      setState(() => _errorMessage = l10n.offeringUnauthorized);
      return;
    }

    final ownProviderId = ref.read(currentProviderIdProvider);
    final requestedProviderId = widget.initialProviderId;
    if (isFixed &&
        (ownProviderId.isEmpty ||
            (requestedProviderId != null &&
                requestedProviderId != ownProviderId) ||
            (user.isCompany &&
                user.companyId != null &&
                user.companyId != ownProviderId))) {
      setState(() => _errorMessage = l10n.offeringUnauthorized);
      return;
    }

    final providerId = !isFixed && requestedProviderId?.isNotEmpty == true
        ? requestedProviderId!
        : ownProviderId;
    final price =
        isFixed ? double.tryParse(_priceController.text.trim()) : null;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final unit = _unitController.text.trim();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final provider =
          await ref.read(providerServiceProvider).getProviderById(providerId);
      if (!mounted) return;

      final isProviderActive = provider != null
          ? provider.isApprovedAndActive
          : !isFixed && user.isActive && Firebase.apps.isEmpty;

      if (!isProviderActive || user.isSuspended) {
        setState(() => _errorMessage = l10n.offeringActiveRequired);
        return;
      }

      if (isFixed &&
          (provider!.appRole != user.role ||
              (provider.id != user.id &&
                  provider.email.toLowerCase() != user.email.toLowerCase()))) {
        setState(() => _errorMessage = l10n.offeringUnauthorized);
        return;
      }

      final category =
          await ref.read(categoryServiceProvider).getCategoryById(categoryId);
      if (!mounted) return;
      if (category == null || !category.isActive) {
        setState(() => _errorMessage = l10n.offeringCategoryRequired);
        return;
      }

      final newOffering = OfferingModel(
        id: 'offering-${DateTime.now().millisecondsSinceEpoch}',
        providerId: providerId,
        providerName: provider?.displayName ??
            (user.isCompany
                ? user.companyName ?? user.fullName
                : user.fullName),
        providerType: provider?.type ??
            (user.isCompany ? ProviderType.company : ProviderType.independent),
        categoryId: category.id,
        categoryName: category.name,
        title: title,
        description: description,
        pricingMode: isFixed
            ? OfferingPricingMode.fixed
            : OfferingPricingMode.quoteRequired,
        price: price,
        unit: isFixed && unit.isNotEmpty ? unit : null,
      );

      final service = ref.read(offeringServiceProvider);
      await service.createOffering(newOffering);

      if (!mounted) return;
      ref.invalidate(offeringsByProviderProvider(providerId));
      ref.invalidate(offeringsByCategoryProvider(categoryId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.offeringSuccessSnackbar),
          backgroundColor: AppTheme.success,
        ),
      );

      _leave(context);
    } catch (error) {
      debugPrint('[CreateOfferingScreen] Publish failed: $error');
      if (mounted) setState(() => _errorMessage = l10n.offeringPublishError);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categoriesAsync = ref.watch(_offeringCategoriesProvider);
    final categories = categoriesAsync.asData?.value;

    return Form(
      key: _formKey,
      child: SpFlowPage(
        title: l10n.offeringCreateTitle,
        onBack: () => _leave(context),
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null) ...[
              Semantics(
                liveRegion: true,
                child: SpNotice(
                  icon: Icons.error_outline_rounded,
                  message: _errorMessage!,
                  tone: SpTone.danger,
                ),
              ),
              const SizedBox(height: 8),
            ],
            SpPrimaryButton(
              key: const Key('publish_offering_button'),
              label: l10n.offeringCreateButton,
              isLoading: _isSubmitting,
              wrapLabel: true,
              onPressed:
                  _isSubmitting || categories == null || categories.isEmpty
                      ? null
                      : () => _submitOffering(categories),
            ),
          ],
        ),
        children: [
          SpPageHeader(
            title: l10n.offeringHeaderTitle,
            subtitle: l10n.offeringCreateSubtitle,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.offeringCategoryLabel,
            style: AppTheme.text(
              size: 14,
              weight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return SpNotice(
                  icon: Icons.list_alt_rounded,
                  message: l10n.offeringCategoriesEmpty,
                  tone: SpTone.neutral,
                );
              }
              return DropdownButtonFormField<String>(
                key: const Key('offering_category_dropdown'),
                isExpanded: true,
                initialValue:
                    categories.any((cat) => cat.id == _selectedCategoryId)
                        ? _selectedCategoryId
                        : null,
                items: categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat.id,
                    child: Text(cat.name, style: AppTheme.text(size: 15)),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() {
                          _selectedCategoryId = value;
                          _errorMessage = null;
                        }),
                validator: (value) =>
                    value == null ? l10n.offeringCategoryRequired : null,
                decoration: InputDecoration(
                  hintText: l10n.offeringCategoryHint,
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => SpNotice(
              icon: Icons.error_outline_rounded,
              message: l10n.offeringCategoriesError,
              tone: SpTone.danger,
            ),
          ),
          const SizedBox(height: 20),
          SpTextField(
            key: const Key('offering_title_field'),
            label: l10n.offeringTitleLabel,
            hint: l10n.offeringTitleHint,
            controller: _titleController,
            maxLength: 150,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return l10n.offeringTitleRequired;
              }
              if (val.trim().length < 3) {
                return l10n.offeringTitleMinLength;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SpTextField(
            key: const Key('offering_description_field'),
            label: l10n.offeringDescLabel,
            hint: l10n.offeringDescHint,
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 2000,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return l10n.offeringDescRequired;
              }
              if (val.trim().length < 10) {
                return l10n.offeringDescMinLength;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              l10n.offeringPricingModeLabel,
              style: AppTheme.text(
                size: 14,
                weight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            ),
            child: RadioGroup<OfferingPricingMode>(
              groupValue: _pricingMode,
              onChanged: (mode) {
                if (mode != null) {
                  setState(() => _pricingMode = mode);
                }
              },
              child: Column(
                children: [
                  RadioListTile<OfferingPricingMode>(
                    key: const Key('pricing_mode_quote_required'),
                    value: OfferingPricingMode.quoteRequired,
                    activeColor: AppTheme.primary,
                    title: Text(
                      l10n.offeringModeQuote,
                      style: AppTheme.text(
                        size: 15,
                        weight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      l10n.offeringModeQuoteDesc,
                      style: AppTheme.text(
                        size: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  RadioListTile<OfferingPricingMode>(
                    key: const Key('pricing_mode_fixed'),
                    value: OfferingPricingMode.fixed,
                    activeColor: AppTheme.primary,
                    title: Text(
                      l10n.offeringModeFixed,
                      style: AppTheme.text(
                        size: 15,
                        weight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      l10n.offeringModeFixedDesc,
                      style: AppTheme.text(
                        size: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_pricingMode == OfferingPricingMode.quoteRequired) ...[
            SpNotice(
              key: const Key('quote_mode_notice'),
              icon: Icons.request_quote_rounded,
              message: l10n.offeringNoticeQuoteMode,
              tone: SpTone.waiting,
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SpTextField(
                    key: const Key('offering_price_field'),
                    label: l10n.offeringPriceLabel,
                    hint: '25.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    controller: _priceController,
                    validator: (val) {
                      if (_pricingMode == OfferingPricingMode.fixed) {
                        if (val == null || val.trim().isEmpty) {
                          return l10n.offeringPriceRequired;
                        }
                        final p = double.tryParse(val.trim());
                        if (!OfferingModel.isValidFixedPrice(p)) {
                          return l10n.offeringPricePositive;
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SpTextField(
                    key: const Key('offering_unit_field'),
                    label: l10n.offeringUnitLabel,
                    hint: l10n.offeringUnitHint,
                    controller: _unitController,
                    maxLength: 50,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

final _offeringCategoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final categories = await ref.watch(categoryServiceProvider).getCategories();
  return categories.where((category) => category.isActive).toList();
});
