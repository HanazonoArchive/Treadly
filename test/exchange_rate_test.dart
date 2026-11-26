import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:treadly/models/tire.dart';
import 'package:treadly/services/exchange_rate_service.dart';

void main() {
  tearDown(() {
    ExchangeRateService.instance.resetForTest();
  });

  group('ExchangeRateService parsing', () {
    test('parses open.er-api.com payload', () {
      final json = jsonDecode('{"result":"success","base_code":"USD","rates":{"PHP":63.77,"EUR":0.94}}');
      expect(ExchangeRateService.parseUsdToPhpRate(json), 63.77);
    });

    test('parses frankfurter.dev payload', () {
      final json = jsonDecode('{"amount":1.0,"base":"USD","date":"2026-11-26","rates":{"PHP":63.61}}');
      expect(ExchangeRateService.parseUsdToPhpRate(json), 63.61);
    });

    test('parses fawazahmed0 currency-api payload', () {
      final json = jsonDecode('{"date":"2026-11-26","usd":{"eur":0.94,"php":63.72}}');
      expect(ExchangeRateService.parseUsdToPhpRate(json), 63.72);
    });

    test('rejects invalid or out-of-bounds rates', () {
      expect(ExchangeRateService.parseUsdToPhpRate({'rates': {'PHP': 0}}), isNull);
      expect(ExchangeRateService.parseUsdToPhpRate({'rates': {'PHP': 500.0}}), isNull);
      expect(ExchangeRateService.parseUsdToPhpRate({'rates': {'EUR': 0.94}}), isNull);
      expect(ExchangeRateService.parseUsdToPhpRate('bad'), isNull);
    });
  });

  group('Tire pricing and ISO specs', () {
    test('priceInPhp uses live ExchangeRateService rate for USD prices', () {
      ExchangeRateService.instance.setRateForTest(63.50);
      const tire = Tire(
        id: 'test-1',
        brand: 'Michelin',
        model: 'Pilot Sport 5',
        category: 'Ultra High Performance Summer',
        season: 'Summer',
        width: 225,
        aspectRatio: 45,
        rimSize: 18,
        loadIndex: 95,
        speedRating: 'Y',
        price: 200.0,
        rating: 4.9,
        reviewsCount: 100,
        stock: 10,
        imageAsset: 'assets/images/tires/michelin_pilot_sport_5.webp',
      );
      expect(tire.priceInPhp, 12700.0);
      expect(tire.formattedPrice, 'Est. ₱12,700');
    });

    test('priceInPhp preserves direct PHP prices (>= 1000)', () {
      ExchangeRateService.instance.setRateForTest(63.50);
      const tire = Tire(
        id: 'test-2',
        brand: 'Michelin',
        model: 'Pilot Sport 5',
        category: 'Ultra High Performance Summer',
        season: 'Summer',
        width: 225,
        aspectRatio: 45,
        rimSize: 18,
        price: 14500.0,
        rating: 4.9,
        reviewsCount: 100,
        stock: 10,
        imageAsset: 'assets/images/tires/michelin_pilot_sport_5.webp',
      );
      expect(tire.priceInPhp, 14500.0);
    });

    test('loadIndexFormatted and speedRatingFormatted reflect real ISO values', () {
      const compact = Tire(
        id: 'c',
        brand: 'Michelin',
        model: 'Energy XM2+',
        category: 'Touring',
        season: 'All-Season',
        width: 175,
        aspectRatio: 65,
        rimSize: 14,
        loadIndex: 82,
        speedRating: 'T',
        price: 75.0,
        rating: 4.7,
        reviewsCount: 50,
        stock: 20,
        imageAsset: 'assets/images/tires/michelin_energy_xm2_plus.webp',
      );
      expect(compact.loadIndexFormatted, '82 (475 kg)');
      expect(compact.speedRatingFormatted, 'T (190 km/h)');

      const suv = Tire(
        id: 's',
        brand: 'BFGoodrich',
        model: 'All-Terrain T/A KO2',
        category: 'All-Terrain',
        season: 'All-Terrain',
        width: 265,
        aspectRatio: 70,
        rimSize: 17,
        loadIndex: 115,
        speedRating: 'S',
        price: 260.0,
        rating: 4.9,
        reviewsCount: 50,
        stock: 20,
        imageAsset: 'assets/images/tires/bfgoodrich_all_terrain_ta_ko2.webp',
      );
      expect(suv.loadIndexFormatted, '115 (1,215 kg)');
      expect(suv.speedRatingFormatted, 'S (180 km/h)');
    });
  });
}
