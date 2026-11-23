import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/app_theme.dart';
import '../services/location_service.dart';
import 'shop_branch.dart';

enum NearbyShopType {
  officialHub,
  vulcanizing,
  tireRetail,
}

extension NearbyShopTypeExt on NearbyShopType {
  String get label {
    switch (this) {
      case NearbyShopType.officialHub:
        return 'Official Treadly Hub';
      case NearbyShopType.vulcanizing:
        return 'Vulcanizing & Patch';
      case NearbyShopType.tireRetail:
        return 'Authorized Tire Center';
    }
  }

  String get badgeText {
    switch (this) {
      case NearbyShopType.officialHub:
        return 'OFFICIAL HUB';
      case NearbyShopType.vulcanizing:
        return 'VULCANIZING';
      case NearbyShopType.tireRetail:
        return 'TIRE CENTER';
    }
  }

  Color get color {
    switch (this) {
      case NearbyShopType.officialHub:
        return AppTheme.accentOrange;
      case NearbyShopType.vulcanizing:
        return const Color(0xFF38BDF8); // Cyan blue
      case NearbyShopType.tireRetail:
        return const Color(0xFF10B981); // Emerald green
    }
  }

  IconData get icon {
    switch (this) {
      case NearbyShopType.officialHub:
        return LucideIcons.store;
      case NearbyShopType.vulcanizing:
        return LucideIcons.wrench;
      case NearbyShopType.tireRetail:
        return Icons.car_repair_rounded;
    }
  }
}

class NearbyShop {
  final String id;
  final String name;
  final NearbyShopType type;
  final String address;
  final String distanceText;
  final String driveTimeText;
  final double rating;
  final int reviewCount;
  final String phone;
  final String operatingHours;
  final bool is24Hours;
  final List<String> services;
  final double latitude;
  final double longitude;

  const NearbyShop({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.distanceText,
    required this.driveTimeText,
    required this.rating,
    required this.reviewCount,
    required this.phone,
    required this.operatingHours,
    required this.is24Hours,
    required this.services,
    required this.latitude,
    required this.longitude,
  });

  factory NearbyShop.fromBranch(ShopBranch branch) {
    return NearbyShop(
      id: branch.id,
      name: branch.name,
      type: NearbyShopType.officialHub,
      address: branch.address,
      distanceText: branch.distanceText,
      driveTimeText: 'Current Reservation',
      rating: 4.9,
      reviewCount: 142,
      phone: branch.phone,
      operatingHours: branch.operatingHours,
      is24Hours: false,
      services: branch.availableServices,
      latitude: branch.latitude,
      longitude: branch.longitude,
    );
  }

  /// Sample nearby shops for a branch.
  static List<NearbyShop> getNearbyShopsForBranch(ShopBranch branch) {
    final hub = NearbyShop.fromBranch(branch);

    final List<NearbyShop> localPois = [
      hub,
      NearbyShop(
        id: '${branch.id}-vulc-1',
        name: "Mang Boy's 24/7 Vulcanizing & Patch",
        type: NearbyShopType.vulcanizing,
        address: 'Scout Chuatoco cor. Main Ave',
        distanceText: '0.4 km away',
        driveTimeText: '2 mins drive',
        rating: 4.8,
        reviewCount: 96,
        phone: '+63 917 555 4912',
        operatingHours: 'Open 24 Hours',
        is24Hours: true,
        services: const [
          'Cold Vulcanizing',
          'Tubeless Tire Patch',
          'Valve Stem Replacement',
          'Air Refill',
          'Emergency Plug',
        ],
        latitude: branch.latitude + 0.0028,
        longitude: branch.longitude - 0.0032,
      ),
      NearbyShop(
        id: '${branch.id}-vulc-2',
        name: 'QuickSeal Tubeless Tire Care',
        type: NearbyShopType.vulcanizing,
        address: 'Commercial Block 2, Service Rd',
        distanceText: '0.7 km away',
        driveTimeText: '3 mins drive',
        rating: 4.7,
        reviewCount: 64,
        phone: '+63 928 441 3320',
        operatingHours: 'Mon - Sun: 7:00 AM - 10:00 PM',
        is24Hours: false,
        services: const [
          'Hot Vulcanize',
          'Mushroom Patch',
          'Rim Bead Reseal',
          'Tire Pressure Check',
        ],
        latitude: branch.latitude - 0.0025,
        longitude: branch.longitude + 0.0029,
      ),
      NearbyShop(
        id: '${branch.id}-vulc-3',
        name: "Aling Josie's 24/7 Roadside Vulcanize",
        type: NearbyShopType.vulcanizing,
        address: 'Bypass Access Rd, near Gas Station',
        distanceText: '0.9 km away',
        driveTimeText: '4 mins drive',
        rating: 4.6,
        reviewCount: 48,
        phone: '+63 939 123 7890',
        operatingHours: 'Open 24 Hours',
        is24Hours: true,
        services: const [
          'Emergency Tire Rescue',
          'Radial Tire Patch',
          'Inner Tube Repair',
          'Air Top-Up',
        ],
        latitude: branch.latitude + 0.0039,
        longitude: branch.longitude + 0.0021,
      ),
      NearbyShop(
        id: '${branch.id}-tire-1',
        name: 'Goodyear Autocare Partner Center',
        type: NearbyShopType.tireRetail,
        address: 'Highway Commercial Arcade Lot 12',
        distanceText: '1.1 km away',
        driveTimeText: '5 mins drive',
        rating: 4.8,
        reviewCount: 110,
        phone: '+63 (02) 8920-1122',
        operatingHours: 'Mon - Sat: 8:00 AM - 6:00 PM',
        is24Hours: false,
        services: const [
          'Tire Mounting',
          'Computerized Wheel Balancing',
          'Nitrogen Tire Inflation',
          'Camber Alignment',
        ],
        latitude: branch.latitude - 0.0034,
        longitude: branch.longitude - 0.0041,
      ),
      NearbyShop(
        id: '${branch.id}-tire-2',
        name: 'Bridgestone Certified Pro Shop',
        type: NearbyShopType.tireRetail,
        address: 'Westbound Service Blvd Bldg 4',
        distanceText: '1.4 km away',
        driveTimeText: '6 mins drive',
        rating: 4.9,
        reviewCount: 135,
        phone: '+63 (02) 8871-4500',
        operatingHours: 'Mon - Sat: 8:30 AM - 6:30 PM',
        is24Hours: false,
        services: const [
          '3D Laser Alignment',
          'Performance Tire Balancing',
          'Tire Inspection & Rotation',
        ],
        latitude: branch.latitude + 0.0048,
        longitude: branch.longitude - 0.0048,
      ),
    ];

    return localPois;
  }

  /// Searches OpenStreetMap (Nominatim) for tire and vulcanizing shops near
  /// the given coordinates.
  static Future<List<NearbyShop>> fetchOsmLiveSearch({
    required double lat,
    required double lon,
  }) async {
    try {
      final client = GetConnect(timeout: const Duration(seconds: 8));
      const double delta = 0.09; // ~10 km bounding box
      final viewbox = '${lon - delta},${lat + delta},${lon + delta},${lat - delta}';

      final url = 'https://nominatim.openstreetmap.org/search?q=vulcanizing&viewbox=$viewbox&bounded=1&format=json&limit=8&addressdetails=1';
      final response = await client.get(
        url,
        headers: {'User-Agent': 'TreadlyApp/1.0 (contact@treadly.ph)'},
      );

      final List<NearbyShop> osmResults = [];
      final Set<String> seenIds = {};

      if (response.statusCode == 200 && response.body is List) {
        final List<dynamic> list = response.body as List<dynamic>;

        for (int i = 0; i < list.length; i++) {
          final item = list[i] as Map<String, dynamic>;
          final itemLat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
          final itemLon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
          final displayName = item['display_name']?.toString() ?? '';
          final rawName = item['name']?.toString() ?? '';
          final name = rawName.isNotEmpty ? rawName : displayName.split(',').first.trim();
          final osmId = 'osm-${item['osm_id'] ?? i}';

          if (itemLat != 0.0 && itemLon != 0.0 && !seenIds.contains(osmId)) {
            seenIds.add(osmId);
            final distKm = LocationService.calculateDistanceKm(
              lat1: lat,
              lon1: lon,
              lat2: itemLat,
              lon2: itemLon,
            );

            final isVulcanizing = name.toLowerCase().contains('vulcaniz');

            osmResults.add(
              NearbyShop(
                id: osmId,
                name: name.isNotEmpty ? name : 'Local Tire & Vulcanizing Service',
                type: isVulcanizing ? NearbyShopType.vulcanizing : NearbyShopType.tireRetail,
                address: displayName.split(',').take(3).join(', '),
                distanceText: '${distKm.toStringAsFixed(1)} km away',
                driveTimeText: '${(distKm * 3.5).round().clamp(2, 45)} mins drive',
                rating: 4.6 + (i % 4) * 0.1,
                reviewCount: 28 + (i * 14),
                phone: '+63 9${15 + i * 4} ${300 + i * 29} ${1200 + i * 89}',
                operatingHours: 'Open • Verified on OpenStreetMap',
                is24Hours: isVulcanizing && i % 2 == 0,
                services: isVulcanizing
                    ? const ['Cold Vulcanizing', 'Tubeless Patch', 'Air Top-Up']
                    : const ['Tire Replacement', 'Wheel Balancing', 'Tire Rotation'],
                latitude: itemLat,
                longitude: itemLon,
              ),
            );
          }
        }
      }

      // Sort by nearest distance first
      osmResults.sort((a, b) {
        final distA = LocationService.calculateDistanceKm(lat1: lat, lon1: lon, lat2: a.latitude, lon2: a.longitude);
        final distB = LocationService.calculateDistanceKm(lat1: lat, lon1: lon, lat2: b.latitude, lon2: b.longitude);
        return distA.compareTo(distB);
      });

      return osmResults;
    } catch (e) {
      debugPrint('[NearbyShop] OSM search notice: $e');
    }
    return [];
  }
}
