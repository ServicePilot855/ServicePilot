/// One fixed-price service line on a booking sent from the cart.
///
/// CART-3 (SCRUM-82, subtask SCRUM-131). Stored in the Firestore `services`
/// list of a booking, so the provider and the customer see the same items and
/// prices the customer reviewed.
class BookingItem {
  final String offeringId;

  /// Provider that published the offering. Used to reject mixed-provider
  /// requests; not stored, because the booking already holds `providerId`.
  final String providerId;
  final String title;
  final double unitPrice;
  final int quantity;

  const BookingItem({
    required this.offeringId,
    required this.providerId,
    required this.title,
    required this.unitPrice,
    this.quantity = 1,
  });

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        'offeringId': offeringId,
        'title': title,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };

  /// Reads an item written by [toMap]. The provider comes from the booking.
  static BookingItem? fromMap(Object? value, {required String providerId}) {
    if (value is! Map) return null;
    final offeringId = value['offeringId'];
    final title = value['title'];
    final unitPrice = value['unitPrice'];
    final quantity = value['quantity'];
    if (offeringId is! String || title is! String || unitPrice is! num) {
      return null;
    }
    return BookingItem(
      offeringId: offeringId,
      providerId: providerId,
      title: title,
      unitPrice: unitPrice.toDouble(),
      quantity: quantity is num && quantity >= 1 ? quantity.toInt() : 1,
    );
  }

  static List<BookingItem> listFrom(Object? value,
      {required String providerId}) {
    if (value is! List) return const [];
    return List.unmodifiable(
      value
          .map((entry) => fromMap(entry, providerId: providerId))
          .whereType<BookingItem>(),
    );
  }

  /// Sum of every line, rounded to cents so `25.1 + 35.2` saves as `60.3`.
  static double totalOf(Iterable<BookingItem> items) {
    final cents = items.fold<int>(
      0,
      (sum, item) => sum + (item.unitPrice * 100).round() * item.quantity,
    );
    return cents / 100;
  }
}
