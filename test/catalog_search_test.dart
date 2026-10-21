import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:treadly/models/tire.dart';

void main() {
  test('assets/data/tires.json loads 100+ tires with rich compatible cars', () {
    final file = File('assets/data/tires.json');
    expect(file.existsSync(), isTrue);

    final jsonString = file.readAsStringSync();
    final tires = Tire.fromJsonList(jsonString);

    expect(tires.length, greaterThanOrEqualTo(100));

    final allCars = <String>{};
    for (final tire in tires) {
      expect(tire.id.isNotEmpty, isTrue);
      expect(tire.brand.isNotEmpty, isTrue);
      expect(tire.model.isNotEmpty, isTrue);
      expect(tire.price, greaterThan(0));
      expect(tire.compatibleCars, isNotNull);
      expect(tire.compatibleCars!.length, greaterThanOrEqualTo(5));
      allCars.addAll(tire.compatibleCars!);
    }

    expect(allCars.length, greaterThan(150));

    // Sizing and compatibility assertions
    final civicTires = tires.where((t) =>
        t.compatibleCars!.any((c) => c.toLowerCase().contains('civic'))).toList();
    expect(civicTires.isNotEmpty, isTrue);

    final fortunerTires = tires.where((t) =>
        t.compatibleCars!.any((c) => c.toLowerCase().contains('fortuner'))).toList();
    expect(fortunerTires.isNotEmpty, isTrue);

    final teslaTires = tires.where((t) =>
        t.compatibleCars!.any((c) => c.toLowerCase().contains('tesla') || c.toLowerCase().contains('model 3'))).toList();
    expect(teslaTires.isNotEmpty, isTrue);

    final rangerTires = tires.where((t) =>
        t.compatibleCars!.any((c) => c.toLowerCase().contains('ranger'))).toList();
    expect(rangerTires.isNotEmpty, isTrue);
  });
}
