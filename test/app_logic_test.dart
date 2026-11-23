import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:treadly/controllers/auth_controller.dart';
import 'package:treadly/controllers/search/search_controller.dart';
import 'package:treadly/models/inquiry.dart';
import 'package:treadly/models/tire.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<Tire> loadCatalog() =>
      Tire.fromJsonList(File('assets/data/tires.json').readAsStringSync());

  group('Order status mapping (CWB-01, CWB-02)', () {
    test('legacy status strings map to the current lifecycle', () {
      expect(InquiryStatusX.fromString('confirmed'), InquiryStatus.responded);
      expect(InquiryStatusX.fromString('prepped in bay'), InquiryStatus.responded);
      expect(InquiryStatusX.fromString('installed'), InquiryStatus.completed);
      expect(InquiryStatusX.fromString('ready'), InquiryStatus.completed);
      expect(InquiryStatusX.fromString('placed'), InquiryStatus.submitted);
    });

    test('labels and stepper positions', () {
      expect(InquiryStatus.submitted.label, 'Placed');
      expect(InquiryStatus.responded.label, 'Confirmed');
      expect(InquiryStatus.completed.label, 'Installed');
      expect(InquiryStatus.submitted.stageStep, 1);
      expect(InquiryStatus.responded.stageStep, 2);
      expect(InquiryStatus.completed.stageStep, 3);
      expect(InquiryStatus.unpaid.stageStep, 0);
    });
  });

  test('Staff detection ignores case and spaces (SWB-03)', () {
    final auth = AuthController();
    auth.userEmail.value = ' Tech@Treadly.com ';
    expect(auth.isStaff, isTrue);
    auth.userEmail.value = 'driver@gmail.com';
    expect(auth.isStaff, isFalse);
  });

  group('Catalog filters', () {
    late SearchCatalogController search;
    setUp(() {
      search = SearchCatalogController();
      search.allTires.addAll(loadCatalog());
    });

    test('SUV & 4x4 only returns SUV, terrain or truck tires (CWB-09)', () {
      search.selectedCategory.value = 'SUV & 4x4';
      final names = search.searchResults.map((t) => t.fullName.toLowerCase());
      expect(names, isNotEmpty);
      expect(names.any((n) => n.contains('cinturato')), isFalse);
      expect(names.any((n) => n.contains('cargo marathon')), isFalse);
    });

    test('All-Season never includes summer tires (CWB-10)', () {
      search.selectedCategory.value = 'All-Season';
      final results = search.searchResults;
      expect(results, isNotEmpty);
      expect(results.any((t) => t.season.toLowerCase().contains('summer')), isFalse);
    });

    test('size search returns only that size (CBB-02)', () {
      search.searchQuery.value = '225/45 R18';
      final results = search.searchResults;
      expect(results, isNotEmpty);
      expect(results.every((t) => t.size == '225/45 R18'), isTrue);
    });

    test('recent searches keep only the latest 10 (CWB-11)', () {
      for (var i = 0; i < 12; i++) {
        search.addRecentSearch('query $i');
      }
      expect(search.recentSearches.length, 10);
      expect(search.recentSearches.first, 'query 11');
    });
  });
}
