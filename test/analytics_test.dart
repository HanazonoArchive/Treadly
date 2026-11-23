import 'package:flutter_test/flutter_test.dart';
import 'package:treadly/controllers/inquiry/inquiry_controller.dart';
import 'package:treadly/models/inquiry.dart';

TireInquiry _order(String id, InquiryStatus status, {bool set = false, int qty = 1, double price = 10000}) {
  final now = DateTime.now();
  return TireInquiry(
    id: id,
    userId: 'u',
    customerName: 'Test',
    customerPhone: '',
    tireId: 't',
    tireBrand: 'Brand',
    tireModel: 'Model',
    tireSize: '225/45 R18',
    tireImage: '',
    unitPrice: set ? price * 0.90 : price,
    quantity: qty,
    isSetOfFour: set,
    branchName: 'Shop',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late InquiryController ctrl;

  setUp(() {
    ctrl = InquiryController();
    ctrl.inquiries.clear();
    ctrl.inquiries.addAll([
      _order('ORD-1', InquiryStatus.completed, qty: 2), // 2 x 10,000 + 150 = 20,150
      _order('ORD-2', InquiryStatus.unpaid, qty: 1),
      _order('ORD-3', InquiryStatus.submitted, set: true),
      _order('ORD-4', InquiryStatus.responded, qty: 1),
      _order('ORD-5', InquiryStatus.cancelled, qty: 1),
    ]);
  });

  test('revenue, units and average ticket count installed orders only', () {
    expect(ctrl.getTimeframeRevenue('All Time'), 20150);
    expect(ctrl.getTimeframeUnitsFitted('All Time'), 2);
    expect(ctrl.getTimeframeCompletedCount('All Time'), 1);
    expect(ctrl.getTimeframeAov('All Time'), 20150);
  });

  test('cancelled orders are counted in the pipeline', () {
    expect(ctrl.getTimeframeCancelledCount('All Time'), 1);
    expect(ctrl.getTimeframeCancelledCount('Today'), 1);
  });

  test('open orders include unpaid, placed and confirmed', () {
    expect(ctrl.openOrdersCount, 3);
  });

  test('no installed orders means zero revenue and zero average', () {
    ctrl.inquiries.clear();
    ctrl.inquiries.add(_order('ORD-9', InquiryStatus.unpaid));
    expect(ctrl.getTimeframeRevenue('All Time'), 0);
    expect(ctrl.getTimeframeAov('All Time'), 0);
  });
}
