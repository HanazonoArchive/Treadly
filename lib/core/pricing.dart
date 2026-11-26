class TirePriceQuote {
  static const double platformServiceFee = 150.0;
  static const double setOfFourDiscountRate = 0.10;

  final double unitListPrice;

  final int tireCount;

  final double listSubtotal;

  final double discount;

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
    final discount = isSetOfFour
        ? (list * setOfFourDiscountRate).roundToDouble()
        : 0.0;
    return TirePriceQuote._(
      unitListPrice: unit,
      tireCount: tireCount,
      listSubtotal: list,
      discount: discount,
      serviceFee: serviceFee,
    );
  }

  double get discountedSubtotal => listSubtotal - discount;

  double get total => discountedSubtotal + serviceFee;

  static String format(double amount) {
    final php = amount.round();
    final formatted = php.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '₱$formatted';
  }
}
