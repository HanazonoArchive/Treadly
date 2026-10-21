import 'dart:convert';

/// Universal Tire Model for Treadly Catalog & Inquiries
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

  /// Universal Size string, e.g. "225/45 R18"
  String get size => '$width/$aspectRatio R$rimSize';

  /// Full display name
  String get fullName => '$brand $model';

  /// Base currency is Philippine Peso (PHP - ₱)
  /// Converts stored USD prices (< 1000) by 56.0, or formats stored PHP prices directly.
  double get priceInPhp => price < 1000 ? (price * 56.0).roundToDouble() : price;

  /// Original crossed-out price in PHP (₱).
  /// Uses original_price from DB if specified and greater than selling price.
  /// Otherwise, applies the fixed discount calculator: selling price + 10% (crossed out as original price).
  double? get originalPriceInPhp {
    if (originalPrice != null && originalPrice! > price) {
      return originalPrice! < 1000 ? (originalPrice! * 56.0).roundToDouble() : originalPrice!;
    }
    // Fixed discount calculator: crossed out original price = selling price + 10%
    return (priceInPhp * 1.10).roundToDouble();
  }

  /// Calculated discount percentage (e.g. 10%)
  int get discountPercentage {
    final orig = originalPriceInPhp;
    if (orig != null && orig > priceInPhp) {
      final diff = orig - priceInPhp;
      return ((diff / orig) * 100).round();
    }
    return 10;
  }

  /// Formatted Price string in PHP, e.g. "₱12,320"
  String get formattedPrice {
    final php = priceInPhp.toInt();
    final formatted = php.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '₱$formatted';
  }

  /// Formatted Original Price string in PHP, e.g. "₱13,999"
  String get formattedOriginalPrice {
    if (originalPriceInPhp == null) return '';
    final php = originalPriceInPhp!.toInt();
    final formatted = php.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '₱$formatted';
  }

  /// Stock status helpers
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

  /// Normalizes legacy connected model names to clean separated words
  static String normalizeModelName(String rawModel) {
    const Map<String, String> map = {
      'CrossContact LX25': 'Cross Contact LX25',
      'ExtremeContact DWS06 Plus': 'Extreme Contact DWS06 Plus',
      'ExtremeContact Sport 02': 'Extreme Contact Sport 02',
      'SportContact 7': 'Sport Contact 7',
      'UltraContact UC7': 'Ultra Contact UC7',
      'TerrainContact A/T': 'Terrain Contact A/T',
      'VikingContact 7': 'Viking Contact 7',
      'CrossClimate 2 SUV': 'Cross Climate 2 SUV',
      'e.Primacy Electric Drive': 'e-Primacy Electric Drive',
      'e.Primacy': 'e-Primacy',
    };
    return map[rawModel.trim()] ?? rawModel;
  }

  factory Tire.fromJson(Map<String, dynamic> json) {
    return Tire(
      id: json['id'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: normalizeModelName(json['model'] as String? ?? ''),
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
      imageAsset: json['image_asset'] as String? ?? 'assets/images/tires/michelin_pilot_sport_5.webp',
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

    return Tire(
      id: map['id'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      model: map['model'] as String? ?? '',
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
      imageAsset: map['image_asset'] as String? ?? 'assets/images/tires/michelin_pilot_sport_5.webp',
    );
  }

  static List<Tire> fromJsonList(String jsonString) {
    final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
    return list.map((item) => Tire.fromJson(item as Map<String, dynamic>)).toList();
  }
}
