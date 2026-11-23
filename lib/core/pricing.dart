/// Order pricing used by every screen (order sheet, order card, chat,
/// analytics), so the amounts always match. Amounts are rounded to whole
/// pesos before they are added up.
class TirePriceQuote {
  static const double platformServiceFee = 150.0;
  static const double setOfFourDiscountRate = 0.10;

  /// Regular price of one tire, in whole pesos.
  final double unitListPrice;

  /// Number of physical tires (a Set of 4 with quantity 2 = 8 tires).
  final int tireCount;

  /// unitListPrice × tireCount, before any discount.
  final double listSubtotal;

  /// Set of 4 promo discount (0 when not a set), in whole pesos.
  final double discount;

  /// Platform service fee charged per order.
  final double serviceFee;

  const TirePriceQuote._({
    required this.unitListPrice,
    required this.tireCount,
    required this.listSubtotal,
    required this.discount,
    required this.serviceFee,
  });

  factory TirePriceQuote.compute({
    required double unitListPrice,
    required int tireCount,
    required bool isSetOfFour,
    double serviceFee = platformServiceFee,
  }) {
    final unit = unitListPrice.roundToDouble();
    final list = unit * tireCount;
    final discount = isSetOfFour ? (list * setOfFourDiscountRate).roundToDouble() : 0.0;
    return TirePriceQuote._(
      unitListPrice: unit,
      tireCount: tireCount,
      listSubtotal: list,
      discount: discount,
      serviceFee: serviceFee,
    );
  }

  /// Tire subtotal after the Set of 4 discount.
  double get discountedSubtotal => listSubtotal - discount;

  /// Amount the customer pays.
  double get total => discountedSubtotal + serviceFee;

  /// Formats a peso amount as "₱44,498".
  static String format(double amount) {
    final php = amount.round();
    final formatted = php.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '₱$formatted';
  }
}
