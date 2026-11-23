/// Represents a physical shop branch of Treadly.
class ShopBranch {
  final String id;
  final String name;
  final String address;
  final String city;
  final String distanceText;
  final String phone;
  final String operatingHours;
  final List<String> availableServices;
  final bool isMainBranch;
  final double latitude;
  final double longitude;

  const ShopBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.distanceText,
    required this.phone,
    required this.operatingHours,
    required this.availableServices,
    this.isMainBranch = false,
    this.latitude = 14.6366,
    this.longitude = 121.0189,
  });

  ShopBranch copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? distanceText,
    String? phone,
    String? operatingHours,
    List<String>? availableServices,
    bool? isMainBranch,
    double? latitude,
    double? longitude,
  }) {
    return ShopBranch(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      distanceText: distanceText ?? this.distanceText,
      phone: phone ?? this.phone,
      operatingHours: operatingHours ?? this.operatingHours,
      availableServices: availableServices ?? this.availableServices,
      isMainBranch: isMainBranch ?? this.isMainBranch,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'distance_text': distanceText,
        'phone': phone,
        'operating_hours': operatingHours,
        'available_services': availableServices,
        'is_main_branch': isMainBranch,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory ShopBranch.fromJson(Map<String, dynamic> json) {
    return ShopBranch(
      id: json['id'] as String? ?? 'branch-qc-main',
      name: json['name'] as String? ?? 'Treadly Auto Hub (Main Flagship)',
      address: json['address'] as String? ?? '108 Quezon Avenue, Brgy. Paligsahan',
      city: json['city'] as String? ?? 'Quezon City',
      distanceText: json['distance_text'] as String? ?? '1.2 km away',
      phone: json['phone'] as String? ?? '+63 (02) 8924-8833',
      operatingHours: json['operating_hours'] as String? ?? 'Mon - Sat: 8:00 AM - 6:00 PM',
      availableServices: (json['available_services'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'Tire Mounting',
            'Computerized Wheel Alignment',
            'High-Speed Balancing',
            'Nitrogen Inflation',
          ],
      isMainBranch: json['is_main_branch'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 14.6366,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 121.0189,
    );
  }

  /// The one shop the app currently serves.
  static const ShopBranch flagship = ShopBranch(
    id: 'treadly-flagship',
    name: 'Treadly Auto & Tire Center',
    address: '108 Quezon Avenue, Brgy. Paligsahan',
    city: 'Quezon City',
    distanceText: 'Flagship Workshop Bay',
    phone: '+63 (02) 8924-8833',
    operatingHours: 'Mon - Sat: 8:00 AM - 6:00 PM',
    availableServices: [
      'Tire Mounting & Fitting',
      'Computerized Wheel Alignment',
      'High-Speed Dynamic Balancing',
      'Nitrogen Inflation & Bay Inspection',
    ],
    isMainBranch: true,
    latitude: 14.6366,
    longitude: 121.0189,
  );

  static const List<ShopBranch> defaultBranches = [flagship];
}
