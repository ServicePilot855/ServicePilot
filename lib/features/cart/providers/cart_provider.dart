import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_pilot/features/cart/models/cart_item.dart';
import 'package:service_pilot/features/cart/models/cart_state.dart';
import 'package:service_pilot/features/services/models/offering_model.dart';

/// Manages single-provider fixed-price cart state and enforces CART-1 rules.
///
/// Implements SCRUM-80 (SCRUM-125):
/// - First fixed-price item sets the cart's provider.
/// - Subsequent eligible fixed-price items from the same provider are accepted.
/// - Quote-required, inactive, invalid-price, or other-provider items are
///   rejected without modifying existing cart contents.
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState.empty());

  /// Attempts to add [offering] to the cart.
  ///
  /// Returns a [CartAddResult] indicating whether the item was accepted or
  /// why it was rejected. Rejected additions leave [state] unchanged.
  CartAddResult addOffering(
    OfferingModel offering, {
    String? providerName,
  }) {
    if (offering.isQuoteRequired || !offering.canAddToCart) {
      return const CartAddResult.rejected(CartAddRejectionReason.quoteRequired);
    }

    if (!offering.isActive) {
      return const CartAddResult.rejected(
        CartAddRejectionReason.inactiveOffering,
      );
    }

    if (!OfferingModel.isValidFixedPrice(offering.price)) {
      return const CartAddResult.rejected(CartAddRejectionReason.invalidPrice);
    }

    if (state.providerId != null && state.providerId != offering.providerId) {
      return CartAddResult.rejected(
        CartAddRejectionReason.differentProvider,
        existingProviderName: state.providerName,
      );
    }

    final resolvedProviderName = (providerName != null &&
            providerName.trim().isNotEmpty)
        ? providerName.trim()
        : (offering.providerName.trim().isNotEmpty
            ? offering.providerName.trim()
            : state.providerName);

    final existingIndex =
        state.items.indexWhere((item) => item.offering.id == offering.id);

    final updatedItems = List<CartItem>.from(state.items);
    if (existingIndex >= 0) {
      final current = updatedItems[existingIndex];
      updatedItems[existingIndex] =
          current.copyWith(quantity: current.quantity + 1);
    } else {
      updatedItems.add(CartItem(offering: offering));
    }

    state = state.copyWith(
      providerId: state.providerId ?? offering.providerId,
      providerName: resolvedProviderName,
      items: List.unmodifiable(updatedItems),
    );

    return const CartAddResult.accepted();
  }

  /// Removes an offering from the cart, clearing the provider if empty.
  void removeOffering(String offeringId) {
    final updatedItems =
        state.items.where((item) => item.offering.id != offeringId).toList();
    if (updatedItems.isEmpty) {
      state = const CartState.empty();
      return;
    }
    state = state.copyWith(items: List.unmodifiable(updatedItems));
  }

  /// Clears all items and resets the selected provider.
  void clear() {
    state = const CartState.empty();
  }
}

/// Global Riverpod provider for the homeowner's service cart.
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
