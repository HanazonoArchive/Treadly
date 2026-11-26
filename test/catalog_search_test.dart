import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:treadly/controllers/search/search_controller.dart';
import 'package:treadly/models/tire.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('assets/data/tires.json loads 150+ verified tires with unique per-model images', () {
    final file = File('assets/data/tires.json');
    expect(file.existsSync(), isTrue);

    final jsonString = file.readAsStringSync();
    final tires = Tire.fromJsonList(jsonString);

    expect(tires.length, greaterThanOrEqualTo(150));

    final allCars = <String>{};
    final assetToModels = <String, Set<String>>{};
    const validGrades = {'A', 'B', 'C', 'D', 'E'};

    for (final tire in tires) {
      expect(tire.id.isNotEmpty, isTrue);
      expect(tire.brand.isNotEmpty, isTrue);
      expect(tire.model.isNotEmpty, isTrue);
      expect(tire.price, greaterThan(0));
      expect(tire.originalPrice, isNotNull);
      expect(tire.originalPrice!, greaterThan(tire.price));
      expect(tire.dotYear, greaterThanOrEqualTo(2025));
      expect(tire.description, isNotNull);
      expect(tire.description!.trim().isNotEmpty, isTrue);
      expect(validGrades.contains(tire.wetGrip?.toUpperCase()), isTrue,
          reason: '${tire.id} has invalid wetGrip ${tire.wetGrip}');
      expect(validGrades.contains(tire.fuelEfficiency?.toUpperCase()), isTrue,
          reason: '${tire.id} has invalid fuelEfficiency ${tire.fuelEfficiency}');
      expect(File(tire.imageAsset).existsSync(), isTrue,
          reason: 'Missing image asset ${tire.imageAsset} for ${tire.id}');

      assetToModels
          .putIfAbsent(tire.imageAsset, () => <String>{})
          .add('${tire.brand}|${tire.model}');

      expect(tire.compatibleCars, isNotNull);
      expect(tire.compatibleCars!.length, greaterThanOrEqualTo(5));
      allCars.addAll(tire.compatibleCars!);
    }

    // Strict 1-to-1 uniqueness: no two distinct models share an image asset.
    for (final entry in assetToModels.entries) {
      expect(entry.value.length, 1,
          reason: '${entry.key} shared across models: ${entry.value}');
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

    // Search normalization checks
    final search = SearchCatalogController()..allTires.addAll(tires);
    search.searchQuery.value = 'ExtremeContact';
    final compactCount = search.searchResults.length;
    search.searchQuery.value = 'Extreme Contact';
    expect(search.searchResults.length, compactCount);
    expect(compactCount, greaterThan(0));

    search.searchQuery.value = '225/45R18';
    expect(search.searchResults.isNotEmpty, isTrue);
  });
}
