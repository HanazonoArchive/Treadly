import 'dart:math' as math;

// Conditional import: dart:html on web, stub on mobile/desktop
import 'location_service_stub.dart'
    if (dart.library.html) 'location_service_web.dart' as platform_loc;

class UserLocation {
  final double latitude;
  final double longitude;
  final bool isAccurate;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.isAccurate = false,
  });
}

class LocationService {
  static Future<UserLocation?> requestDeviceLocation() async {
    try {
      return await platform_loc.getPlatformLocation();
    } catch (_) {
      return null;
    }
  }

  /// Haversine formula to compute distance in km between two lat/lon points
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R * asin...
  }
}
