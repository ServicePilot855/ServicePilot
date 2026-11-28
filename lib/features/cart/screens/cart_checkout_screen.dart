import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:service_pilot/features/bookings/screens/create_booking_screen.dart';
import 'package:service_pilot/features/cart/models/cart_state.dart';
import 'package:service_pilot/features/cart/providers/cart_provider.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';

/// Checkout for the reviewed cart: the existing booking request form with the
/// cart's services in place of the service picker.
///
/// CART-3 (SCRUM-82, subtask SCRUM-130). Reached from Continue to checkout on
/// the cart at `/cart/checkout`.
class CartCheckoutScreen extends ConsumerStatefulWidget {
  const CartCheckoutScreen({super.key});

  @override
  ConsumerState<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends ConsumerState<CartCheckoutScreen> {
  /// The cart as the customer reviewed it. Read once: the cart cannot change
  /// while this page is open, and it is cleared after a successful send while
  /// this page is still animating out.
  late final CartState _cart = ref.read(cartProvider);

  @override
  Widget build(BuildContext context) {
    final providerId = _cart.providerId;
    if (_cart.isEmpty || providerId == null) {
      final l10n = context.l10n;
      return SpFlowPage(
        title: l10n.cartCheckoutTitle,
        onBack: () => context.canPop()
            ? context.pop()
            : context.go('/home/customer'),
        children: [
          SpStatusHero(
            key: const Key('cart_checkout_empty'),
            icon: Icons.shopping_cart_outlined,
            title: l10n.cartEmptyTitle,
            message: l10n.cartEmptyBody,
            tone: SpTone.neutral,
          ),
          const SizedBox(height: 24),
          SpSecondaryButton(
            label: l10n.cartBrowseServices,
            icon: Icons.grid_view_rounded,
            wrapLabel: true,
            onPressed: () => context.go('/categories'),
          ),
        ],
      );
    }

    return CreateBookingScreen(providerId: providerId, cart: _cart);
  }
}
