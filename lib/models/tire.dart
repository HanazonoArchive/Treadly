import 'dart:convert';

import '../services/exchange_rate_service.dart';

/// A tire in the catalog.
class Tire {
  final String id;
  final String brand;
  final String model;
  final String category;
  final String season;
  final int width;
  final int aspectRatio;
  final int rimSize;
  final int? loadIndex;
  final String? speedRating;
  final int? dotYear;
  final double price;
  final double? originalPrice;
  final double rating;
  final int reviewsCount;
  final int stock;
  final String? wetGrip;
  final String? fuelEfficiency;
  final int? noiseDb;
  final int? warrantyMiles;
  final String? description;
  final List<String>? compatibleCars;
  final String imageAsset;

  const Tire({
    required this.id,
    required this.brand,
    required this.model,
    required this.category,
    required this.season,
    required this.width,
    required this.aspectRatio,
    required this.rimSize,
    this.loadIndex,
    this.speedRating,
    this.dotYear,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.reviewsCount,
    required this.stock,
    this.wetGrip,
    this.fuelEfficiency,
    this.noiseDb,
    this.warrantyMiles,
    this.description,
    this.compatibleCars,
    required this.imageAsset,
  });

  /// ISO / ETRTO load index to single-tire max load capacity (kg).
  static const Map<int, int> loadIndexToKg = {
    70: 335,
    71: 345,
    72: 355,
    73: 365,
    74: 375,
    75: 387,
    76: 400,
    77: 412,
    78: 425,
    79: 437,
    80: 450,
    81: 462,
    82: 475,
    83: 487,
    84: 500,
    85: 515,
    86: 530,
    87: 545,
    88: 560,
    89: 580,
    90: 600,
    91: 615,
    92: 630,
    93: 650,
    94: 670,
    95: 690,
    96: 710,
    97: 730,
    98: 750,
    99: 775,
    100: 800,
    101: 825,
    102: 850,
    103: 875,
    104: 900,
    105: 925,
    106: 950,
    107: 975,
    108: 1000,
    109: 1030,
    110: 1060,
    111: 1090,
    112: 1120,
    113: 1150,
    114: 1180,
    115: 1215,
    116: 1250,
    117: 1285,
    118: 1320,
    119: 1360,
    120: 1400,
    121: 1450,
    122: 1500,
    123: 1550,
    124: 1600,
    125: 1650,
    126: 1700,
  };

  /// ISO / ETRTO speed symbol to maximum rated speed.
  static const Map<String, String> speedRatingToKmh = {
    'N': '140 km/h',
    'P': '150 km/h',
    'Q': '160 km/h',
    'R': '170 km/h',
    'S': '180 km/h',
    'T': '190 km/h',
    'U': '200 km/h',
    'H': '210 km/h',
    'V': '240 km/h',
    'ZR': '240+ km/h',
    'W': '270 km/h',
    'Y': '300 km/h',
    '(Y)': '300+ km/h',
  };

  /// Size, e.g. "225/45 R18".
  String get size => '$width/$aspectRatio R$rimSize';

  String get fullName => '$brand $model';

  /// Accurate load index label, e.g. "115 (1,215 kg)".
  String get loadIndexFormatted {
    final idx = loadIndex ?? 95;
    final kg = loadIndexToKg[idx];
    if (kg == null) return '$idx';
    return '$idx (${_formatWithCommas(kg)} kg)';
  }

  /// Accurate speed rating label, e.g. "Y (300 km/h)".
  String get speedRatingFormatted {
    final code = (speedRating ?? 'Y').trim().toUpperCase();
    final kmh = speedRatingToKmh[code];
    return kmh != null ? '$code ($kmh)' : code;
  }

  /// Treadwear warranty display string.
  String get warrantyFormatted {
    if (warrantyMiles == null || warrantyMiles! <= 0) {
      return 'Manufacturer Warranty';
    }
    return '${_formatWithCommas(warrantyMiles!)} mi';
  }

  static String _formatWithCommas(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// Price in pesos. Prices under 1000 are stored in USD and converted using
  /// the live USD/PHP exchange rate from [ExchangeRateService].
  double get priceInPhp => price < 1000
      ? (price * ExchangeRateService.instance.rate).roundToDouble()
      : price;

  /// Crossed-out price: original_price if higher than the selling price,
  /// otherwise selling price + 10%.
  double? get originalPriceInPhp {
    if (originalPrice != null && originalPrice! > price) {
      return originalPrice! < 1000
          ? (originalPrice! * ExchangeRateService.instance.rate).roundToDouble()
          : originalPrice!;
    }
    return (priceInPhp * 1.10).roundToDouble();
  }

  /// e.g. "Est. ₱14,013"
  String get formattedPrice {
    final php = priceInPhp.toInt();
    return 'Est. ₱${_formatWithCommas(php)}';
  }

  /// e.g. "₱14,013"
  String get rawFormattedPrice {
    final php = priceInPhp.toInt();
    return '₱${_formatWithCommas(php)}';
  }

  /// No longer used.
  int get discountPercentage => 0;
  String get formattedOriginalPrice => '';

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= 5;

  Tire copyWith({
    String? id,
    String? brand,
    String? model,
    String? category,
    String? season,
    int? width,
    int? aspectRatio,
    int? rimSize,
    int? loadIndex,
    String? speedRating,
    int? dotYear,
    double? price,
    double? originalPrice,
    double? rating,
    int? reviewsCount,
    int? stock,
    String? wetGrip,
    String? fuelEfficiency,
    int? noiseDb,
    int? warrantyMiles,
    String? description,
    List<String>? compatibleCars,
    String? imageAsset,
  }) {
    return Tire(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      category: category ?? this.category,
      season: season ?? this.season,
      width: width ?? this.width,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      rimSize: rimSize ?? this.rimSize,
      loadIndex: loadIndex ?? this.loadIndex,
      speedRating: speedRating ?? this.speedRating,
      dotYear: dotYear ?? this.dotYear,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      stock: stock ?? this.stock,
      wetGrip: wetGrip ?? this.wetGrip,
      fuelEfficiency: fuelEfficiency ?? this.fuelEfficiency,
      noiseDb: noiseDb ?? this.noiseDb,
      warrantyMiles: warrantyMiles ?? this.warrantyMiles,
      description: description ?? this.description,
      compatibleCars: compatibleCars ?? this.compatibleCars,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }

  /// Normalizes legacy spaced model variants back to official trademark spellings.
  static String normalizeModelName(String rawModel) {
    const Map<String, String> map = {
      'Cross Contact LX25': 'CrossContact LX25',
      'Cross Contact AX6': 'CrossContact AX6',
      'Extreme Contact DWS06 Plus': 'ExtremeContact DWS06 Plus',
      'Extreme Contact Sport 02': 'ExtremeContact Sport 02',
      'Extreme Contact Force': 'ExtremeContact Force',
      'Sport Contact 7': 'SportContact 7',
      'Premium Contact 7': 'PremiumContact 7',
      'Comfort Contact CC7': 'ComfortContact CC7',
      'Ultra Contact UC7': 'UltraContact UC7',
      'Terrain Contact A/T': 'TerrainContact A/T',
      'Viking Contact 7': 'VikingContact 7',
      'Van Contact Ultra': 'VanContact Ultra',
      'Cross Climate 2 SUV': 'CrossClimate 2 SUV',
      'e-Primacy Electric Drive': 'e.Primacy',
      'e.Primacy Electric Drive': 'e.Primacy',
      'e-Primacy': 'e.Primacy',
    };
    final trimmed = rawModel.trim();
    return map[trimmed] ?? trimmed;
  }

  factory Tire.fromJson(Map<String, dynamic> json) {
    final model = normalizeModelName(json['model'] as String? ?? '');
    return Tire(
      id: json['id'] as String? ?? '',
      brand: (json['brand'] as String? ?? '').trim(),
      model: model,
      category: json['category'] as String? ?? '',
      season: json['season'] as String? ?? '',
      width: (json['width'] as num?)?.toInt() ?? 225,
      aspectRatio: (json['aspect_ratio'] as num?)?.toInt() ?? 45,
      rimSize: (json['rim_size'] as num?)?.toInt() ?? 18,
      loadIndex: (json['load_index'] as num?)?.toInt(),
      speedRating: json['speed_rating'] as String?,
      dotYear: (json['dot_year'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      wetGrip: json['wet_grip'] as String?,
      fuelEfficiency: json['fuel_efficiency'] as String?,
      noiseDb: (json['noise_db'] as num?)?.toInt(),
      warrantyMiles: (json['warranty_miles'] as num?)?.toInt(),
      description: json['description'] as String?,
      compatibleCars: (json['compatible_cars'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      imageAsset: resolveImageAsset(
        explicit: json['image_asset'] as String?,
        brand: json['brand'] as String?,
        model: model,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'category': category,
      'season': season,
      'width': width,
      'aspect_ratio': aspectRatio,
      'rim_size': rimSize,
      'load_index': loadIndex,
      'speed_rating': speedRating,
      'dot_year': dotYear,
      'price': price,
      'original_price': originalPrice,
      'rating': rating,
      'reviews_count': reviewsCount,
      'stock': stock,
      'wet_grip': wetGrip,
      'fuel_efficiency': fuelEfficiency,
      'noise_db': noiseDb,
      'warranty_miles': warrantyMiles,
      'description': description,
      'compatible_cars': compatibleCars,
      'image_asset': imageAsset,
    };
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'category': category,
      'season': season,
      'size': size,
      'width': width,
      'aspect_ratio': aspectRatio,
      'rim_size': rimSize,
      'load_index': loadIndex,
      'speed_rating': speedRating,
      'dot_year': dotYear,
      'price': price,
      'original_price': originalPrice,
      'rating': rating,
      'reviews_count': reviewsCount,
      'stock': stock,
      'wet_grip': wetGrip,
      'fuel_efficiency': fuelEfficiency,
      'noise_db': noiseDb,
      'warranty_miles': warrantyMiles,
      'description': description,
      'compatible_cars': compatibleCars != null ? jsonEncode(compatibleCars) : null,
      'image_asset': imageAsset,
    };
  }

  factory Tire.fromSqliteMap(Map<String, dynamic> map) {
    List<String>? cars;
    if (map['compatible_cars'] != null) {
      try {
        final decoded = jsonDecode(map['compatible_cars'] as String);
        if (decoded is List) {
          cars = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    final model = normalizeModelName(map['model'] as String? ?? '');
    return Tire(
      id: map['id'] as String? ?? '',
      brand: (map['brand'] as String? ?? '').trim(),
      model: model,
      category: map['category'] as String? ?? '',
      season: map['season'] as String? ?? 'All-Season',
      width: (map['width'] as num?)?.toInt() ?? 225,
      aspectRatio: (map['aspect_ratio'] as num?)?.toInt() ?? 45,
      rimSize: (map['rim_size'] as num?)?.toInt() ?? 18,
      loadIndex: (map['load_index'] as num?)?.toInt(),
      speedRating: map['speed_rating'] as String?,
      dotYear: (map['dot_year'] as num?)?.toInt(),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['original_price'] as num?)?.toDouble(),
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewsCount: (map['reviews_count'] as num?)?.toInt() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      wetGrip: map['wet_grip'] as String?,
      fuelEfficiency: map['fuel_efficiency'] as String?,
      noiseDb: (map['noise_db'] as num?)?.toInt(),
      warrantyMiles: (map['warranty_miles'] as num?)?.toInt(),
      description: map['description'] as String?,
      compatibleCars: cars,
      imageAsset: resolveImageAsset(
        explicit: map['image_asset'] as String?,
        brand: map['brand'] as String?,
        model: model,
      ),
    );
  }

  static List<Tire> fromJsonList(String jsonString) {
    final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
    return list.map((item) => Tire.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Picks the image in assets/images/tires/ that matches the brand and model.
  static String resolveImageAsset({String? explicit, String? brand, String? model}) {
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final bSlug = _toSlug(brand ?? '');
    final mSlug = _toSlug(model ?? '');
    if (bSlug.isNotEmpty && mSlug.isNotEmpty) {
      return 'assets/images/tires/${bSlug}_$mSlug.webp';
    }
    return 'assets/images/tires/michelin_pilot_sport_5.webp';
  }

  static String _toSlug(String input) {
    return input
        .toLowerCase()
        .replaceAll('+', ' plus')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
