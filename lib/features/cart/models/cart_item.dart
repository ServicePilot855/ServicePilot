import 'package:service_pilot/features/services/models/offering_model.dart';

/// A fixed-price service offering held in the homeowner's cart.
///
/// Implements CART-1 (SCRUM-80).
class CartItem {
  final OfferingModel offering;
  final int quantity;

  const CartItem({
    required this.offering,
    this.quantity = 1,
  }) : assert(quantity > 0, 'Cart item quantity must be positive');

  double get subtotal => (offering.price ?? 0.0) * quantity;

  CartItem copyWith({
    OfferingModel? offering,
    int? quantity,
  }) {
    return CartItem(
      offering: offering ?? this.offering,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.offering.id == offering.id &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => Object.hash(offering.id, quantity);
}
