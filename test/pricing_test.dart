import 'package:flutter_test/flutter_test.dart';
import 'package:treadly/core/pricing.dart';
import 'package:treadly/models/inquiry.dart';

void main() {
  group('TirePriceQuote', () {
    test('Set of 4 quote uses whole-peso amounts that add up', () {
      final q = TirePriceQuote.compute(unitListPrice: 12319, tireCount: 4, isSetOfFour: true);
      expect(q.listSubtotal, 49276);
      expect(q.discount, 4928); // 10% of 49,276 = 4,927.6, rounded once
      expect(q.serviceFee, 150);
      expect(q.total, 44498);
      expect(q.listSubtotal - q.discount + q.serviceFee, q.total);
    });

    test('Single tire has no discount', () {
      final q = TirePriceQuote.compute(unitListPrice: 12319, tireCount: 1, isSetOfFour: false);
      expect(q.discount, 0);
      expect(q.total, 12469);
    });

    test('format adds peso sign and thousands separators', () {
      expect(TirePriceQuote.format(44498), '₱44,498');
      expect(TirePriceQuote.format(4927.6), '₱4,928');
    });
  });

  test('Order card shows the same discount as the order sheet', () {
    final sheet = TirePriceQuote.compute(unitListPrice: 12319, tireCount: 4, isSetOfFour: true);
    final order = TireInquiry(
      id: 'ORD-1',
      userId: 'u1',
      customerName: 'Test',
      customerPhone: '',
      tireId: 't1',
      tireBrand: 'Michelin',
      tireModel: 'Pilot Sport 5',
      tireSize: '225/45 R18',
      tireImage: '',
      unitPrice: 12319 * 0.90, // how createInquiry stores set prices
      quantity: 1,
      isSetOfFour: true,
      serviceFee: 150,
      branchId: 'b1',
      branchName: 'Shop',
      branchAddress: '',
      vehicleModel: '',
      preferredDate: '',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(order.quote.discount, sheet.discount);
    expect(order.totalPrice, sheet.total);
    expect(order.formattedTotalPrice, '₱44,498');
  });
}
