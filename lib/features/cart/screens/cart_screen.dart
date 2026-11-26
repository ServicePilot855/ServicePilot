import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/cart/models/cart_item.dart';
import 'package:service_pilot/features/cart/models/cart_state.dart';
import 'package:service_pilot/features/cart/providers/cart_provider.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Cart review: the cart's provider, each selected service with its fixed
/// price, and the computed total. An empty cart shows an empty state.
///
/// CART-2 (SCRUM-81, subtask SCRUM-128). Reached from the cart badge on the
/// provider page at [CartScreen.path].
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  static const String path = '/cart';

  static void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home/customer');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) {
      return SpFlowPage(
        title: l10n.cartTitle,
        onBack: () => _leave(context),
        children: [
          SpStatusHero(
            key: const Key('cart_empty_state'),
            icon: Icons.shopping_cart_outlined,
            title: l10n.cartEmptyTitle,
            message: l10n.cartEmptyBody,
            tone: SpTone.neutral,
          ),
          const SizedBox(height: 24),
          SpSecondaryButton(
            key: const Key('cart_browse_services'),
            label: l10n.cartBrowseServices,
            icon: Icons.grid_view_rounded,
            wrapLabel: true,
            onPressed: () => context.go('/categories'),
          ),
        ],
      );
    }

    return SpFlowPage(
      title: l10n.cartTitle,
      onBack: () => _leave(context),
      children: [
        SpPageHeader(
          title: l10n.cartHeading,
          subtitle: l10n.cartItemCount(cart.itemCount),
        ),
        const SizedBox(height: 24),
        _CartProvider(cart: cart),
        const SizedBox(height: 24),
        const Divider(height: 1, color: AppTheme.border),
        for (final item in cart.items) ...[
          _CartItemRow(
            item: item,
            onRemove: () => ref
                .read(cartProvider.notifier)
                .removeOffering(item.offering.id),
          ),
          const Divider(height: 1, color: AppTheme.border),
        ],
        const SizedBox(height: 16),
        _CartTotal(total: cart.totalPrice),
        const SizedBox(height: 24),
        SpNotice(
          icon: Icons.info_outline_rounded,
          message: l10n.cartPaymentNote,
          tone: SpTone.neutral,
        ),
      ],
    );
  }
}

/// Formats a USD amount the way the rest of the app does (`$25.00`).
String formatCartPrice(double amount) => '\$${amount.toStringAsFixed(2)}';

const _tabular = [FontFeature.tabularFigures()];

class _CartProvider extends StatelessWidget {
  const _CartProvider({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = cart.providerName?.trim() ?? '';

    return Row(
      key: const Key('cart_provider'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.storefront_outlined,
            size: 24,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.cartProviderLabel,
                style: AppTheme.text(size: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                name.isEmpty ? l10n.cartProviderUnknown : name,
                style: AppTheme.text(
                  size: 16.5,
                  weight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({required this.item, required this.onRemove});

  final CartItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final offering = item.offering;
    final unitPrice = formatCartPrice(offering.price ?? 0);
    final priceLine = item.quantity > 1
        ? l10n.cartItemQuantityPrice(item.quantity, unitPrice)
        : unitPrice;

    return Padding(
      key: Key('cart_item_${offering.id}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offering.title,
                    style: AppTheme.text(
                      size: 16,
                      weight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    priceLine,
                    key: Key('cart_item_price_${offering.id}'),
                    style: AppTheme.text(
                      size: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ).copyWith(fontFeatures: _tabular),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatCartPrice(item.subtotal),
            key: Key('cart_item_subtotal_${offering.id}'),
            style: AppTheme.text(
              size: 16,
              weight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ).copyWith(fontFeatures: _tabular),
          ),
          IconButton(
            key: Key('cart_remove_${offering.id}'),
            tooltip: l10n.cartRemoveItem(offering.title),
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            icon: const Icon(Icons.delete_outline_rounded, size: 22),
            color: AppTheme.textSecondary,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _CartTotal extends StatelessWidget {
  const _CartTotal({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = formatCartPrice(total);

    return Semantics(
      container: true,
      label: l10n.cartTotalSemantics(value),
      excludeSemantics: true,
      child: Row(
        key: const Key('cart_total'),
        children: [
          Expanded(
            child: Text(
              l10n.cartTotalLabel,
              style: AppTheme.display(size: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 48),
            child: Text(
              value,
              key: const Key('cart_total_value'),
              style: AppTheme.display(size: 20).copyWith(
                fontFeatures: _tabular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
