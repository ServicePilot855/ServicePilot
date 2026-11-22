import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/auth/auth_provider.dart';
import 'package:service_pilot/core/auth/auth_state.dart';
import 'package:service_pilot/core/constants/app_roles.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/providers/models/provider_model.dart';
import 'package:service_pilot/features/providers/providers/provider_provider.dart';
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
/// Implements US OFFER-2 (SCRUM-77) and SCRUM-119.
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
  final _unitController = TextEditingController(text: 'job');

  String? _selectedCategoryId;
  String? _selectedCategoryName;
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
      context.go('/home/technician');
    }
  }

  Future<void> _submitOffering() async {
    final l10n = context.l10n;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      setState(() {
        _errorMessage = l10n.offeringCategoryRequired;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authProvider);

      // ── Authorization & Role Restriction (Issue 2) ─────────────────────
      if (authState is! AuthStateAuthenticated) {
        setState(() {
          _errorMessage = l10n.offeringUnauthorized;
          _isSubmitting = false;
        });
        return;
      }

      final user = authState.user;
      final allowedRoles = [
        AppRole.independentProvider,
        AppRole.company,
        AppRole.admin,
      ];

      if (!allowedRoles.contains(user.role)) {
        setState(() {
          _errorMessage = l10n.offeringUnauthorized;
          _isSubmitting = false;
        });
        return;
      }

      // ── Provider Identification & Active Check (Issue 1) ───────────────
      final resolvedId = ref.read(currentProviderIdProvider);
      String providerId = widget.initialProviderId ?? '';
      if (providerId.isEmpty && resolvedId.isNotEmpty) {
        providerId = resolvedId;
      }
      if (providerId.isEmpty) {
        providerId = user.id;
      }
      if (providerId.isEmpty) {
        providerId = 'prov-virak-ac';
      }

      final providerService = ref.read(providerServiceProvider);
      final provider = await providerService.getProviderById(providerId);

      final isProviderActive = provider != null
          ? provider.isApprovedAndActive
          : (user.status.toLowerCase() == 'active' && Firebase.apps.isEmpty);

      if (!isProviderActive) {
        setState(() {
          _errorMessage = l10n.offeringActiveRequired;
          _isSubmitting = false;
        });
        return;
      }

      // ── Provider Name & Company Listing Display (Issue 7) ───────────────
      String providerName = provider?.displayName ?? user.fullName;
      ProviderType providerType = provider?.type ?? ProviderType.independent;

      if (user.role == AppRole.company || provider?.isCompany == true) {
        providerType = ProviderType.company;
        final companyName = user.companyName?.trim();
        if (companyName != null && companyName.isNotEmpty) {
          providerName = companyName;
        } else if (provider?.businessName != null &&
            provider!.businessName!.trim().isNotEmpty) {
          providerName = provider.businessName!.trim();
        } else if (provider != null && provider.name.isNotEmpty) {
          providerName = provider.name;
        }
      }

      // ── Resolve Category Name (Issue 8) ─────────────────────────────────
      if (_selectedCategoryName == null || _selectedCategoryName!.isEmpty) {
        final categories = ref.read(categoriesListProvider).valueOrNull;
        if (categories != null && categories.isNotEmpty) {
          final match = categories.where((c) => c.id == _selectedCategoryId);
          if (match.isNotEmpty) {
            _selectedCategoryName = match.first.name;
          }
        }
        if (_selectedCategoryName == null || _selectedCategoryName!.isEmpty) {
          try {
            final cat = await ref
                .read(categoryServiceProvider)
                .getCategoryById(_selectedCategoryId!);
            if (cat != null) {
              _selectedCategoryName = cat.name;
            }
          } catch (e) {
            debugPrint('[CreateOfferingScreen] Failed to resolve category name: $e');
          }
        }
      }

      final double? parsedPrice = _pricingMode == OfferingPricingMode.fixed
          ? double.tryParse(_priceController.text.trim())
          : null;

      final newOffering = OfferingModel(
        id: 'offering-${DateTime.now().millisecondsSinceEpoch}',
        providerId: providerId,
        providerName: providerName,
        providerType: providerType,
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        pricingMode: _pricingMode,
        price: parsedPrice,
        unit: _pricingMode == OfferingPricingMode.fixed
            ? _unitController.text.trim()
            : null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final service = ref.read(offeringServiceProvider);
      await service.createOffering(newOffering);

      // Invalidate relevant providers to refresh UI lists
      ref.invalidate(offeringsByProviderProvider(providerId));
      ref.invalidate(offeringsByCategoryProvider(_selectedCategoryId!));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.offeringSuccessSnackbar),
          backgroundColor: AppTheme.success,
        ),
      );

      _leave(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to publish offering: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: SpBackButton(onPressed: () => _leave(context)),
        title: Text(
          l10n.offeringCreateTitle,
          style: AppTheme.display(size: 18, color: AppTheme.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.gutter),
          child: SpContentWidth(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpPageHeader(
                    title: l10n.offeringHeaderTitle,
                    subtitle: l10n.offeringCreateSubtitle,
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    SpNotice(
                      icon: Icons.error_outline_rounded,
                      message: _errorMessage!,
                      tone: SpTone.danger,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Category Selector (Issue 8 & 11) ───────────────────
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
                      if (_selectedCategoryId != null &&
                          (_selectedCategoryName == null ||
                              _selectedCategoryName!.isEmpty)) {
                        final match = categories
                            .where((c) => c.id == _selectedCategoryId);
                        if (match.isNotEmpty) {
                          _selectedCategoryName = match.first.name;
                        }
                      } else if (_selectedCategoryId == null &&
                          categories.isNotEmpty) {
                        _selectedCategoryId = categories.first.id;
                        _selectedCategoryName = categories.first.name;
                      }
                      return DropdownButtonFormField<String>(
                        key: const Key('offering_category_dropdown'),
                        isExpanded: true,
                        initialValue: _selectedCategoryId,
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child:
                                Text(cat.name, style: AppTheme.text(size: 15)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final cat = categories.firstWhere(
                              (c) => c.id == val,
                              orElse: () => categories.first,
                            );
                            setState(() {
                              _selectedCategoryId = val;
                              _selectedCategoryName = cat.name;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: l10n.offeringCategoryHint,
                          fillColor: AppTheme.inputFill,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusControl),
                            borderSide:
                                const BorderSide(color: AppTheme.border),
                          ),
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => Text(
                      'Failed to load categories',
                      style: AppTheme.text(color: AppTheme.error),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Title Field (Issue 11) ──────────────────────────────
                  SpTextField(
                    key: const Key('offering_title_field'),
                    label: l10n.offeringTitleLabel,
                    hint: l10n.offeringTitleHint,
                    controller: _titleController,
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

                  // ── Description Field (Issue 11) ────────────────────────
                  SpTextField(
                    key: const Key('offering_description_field'),
                    label: l10n.offeringDescLabel,
                    hint: l10n.offeringDescHint,
                    controller: _descriptionController,
                    maxLines: 4,
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

                  // ── Pricing Mode Selector (Issue 11) ────────────────────
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
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusControl),
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

                  // ── Conditional Pricing Input Or Quote Notice ───────────
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
                                if (p == null || p <= 0) {
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
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),

                  // ── Submit Button (Issue 11) ────────────────────────────
                  SpPrimaryButton(
                    key: const Key('publish_offering_button'),
                    label: l10n.offeringCreateButton,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submitOffering,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
