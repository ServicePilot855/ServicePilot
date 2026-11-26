import 'package:service_pilot/features/cart/models/cart_item.dart';

/// Reason an offering was rejected when attempting to add it to the cart.
enum CartAddRejectionReason {
  notHomeowner,
  quoteRequired,
  inactiveOffering,
  invalidPrice,
  differentProvider,
}

/// Outcome of attempting to add an offering to the cart.
class CartAddResult {
  final bool accepted;
  final CartAddRejectionReason? rejectionReason;
  final String? existingProviderName;

  const CartAddResult.accepted()
      : accepted = true,
        rejectionReason = null,
        existingProviderName = null;

  const CartAddResult.rejected(
    CartAddRejectionReason this.rejectionReason, {
    this.existingProviderName,
  }) : accepted = false;
}

/// Single-provider fixed-price cart state for a homeowner (CART-1 / SCRUM-80).
class CartState {
  final String? providerId;
  final String? providerName;
  final List<CartItem> items;

  const CartState({
    this.providerId,
    this.providerName,
    this.items = const [],
  });

  const CartState.empty()
      : providerId = null,
        providerName = null,
        items = const [];

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.subtotal);

  bool containsOffering(String offeringId) =>
      items.any((item) => item.offering.id == offeringId);

  CartState copyWith({
    String? providerId,
    String? providerName,
    List<CartItem>? items,
    bool clearProvider = false,
  }) {
    return CartState(
      providerId: clearProvider ? null : (providerId ?? this.providerId),
      providerName: clearProvider ? null : (providerName ?? this.providerName),
      items: items ?? this.items,
    );
  }
}
