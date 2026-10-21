import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/app_theme.dart';
import '../models/nearby_shop.dart';
import '../models/shop_branch.dart';
import '../services/location_service.dart';
import '../widgets/shop/osm_interactive_map.dart';

/// Dedicated Shop Detail & OpenStreetMap Discovery View
/// Clean minimalist layout:
/// - Top bar matching Profile & Inquiries (< Chevron + "Shop Location")
/// - Interactive Slippy Map with dynamic scaling circles (no lines, no text tags)
/// - Device location permission for real-time accurate distance
/// - Clean bottom card with distance, shop name, rating, address, and a single "Call" button
class ShopLocationView extends StatefulWidget {
  final ShopBranch? branch;

  const ShopLocationView({super.key, this.branch});

  @override
  State<ShopLocationView> createState() => _ShopLocationViewState();
}

class _ShopLocationViewState extends State<ShopLocationView> {
  late final ShopBranch _activeBranch;
  late final List<NearbyShop> _allShops;
  late NearbyShop _selectedShop;

  double? _userLat;
  double? _userLon;
  double? _userDistanceKm;

  @override
  void initState() {
    super.initState();
    _activeBranch = widget.branch ?? ShopBranch.defaultBranches.first;
    _allShops = NearbyShop.getNearbyShopsForBranch(_activeBranch);
    _selectedShop = _allShops.first;

    // Prompt for device location permission and calculate real-time distance
    _initDeviceLocation();
  }

  Future<void> _initDeviceLocation() async {
    final loc = await LocationService.requestDeviceLocation();
    if (mounted && loc != null) {
      setState(() {
        _userLat = loc.latitude;
        _userLon = loc.longitude;
        _userDistanceKm = LocationService.calculateDistanceKm(
          lat1: loc.latitude,
          lon1: loc.longitude,
          lat2: _selectedShop.latitude,
          lon2: _selectedShop.longitude,
        );
      });
    }

    // Query real, live OpenStreetMap tire & vulcanizing stations
    await _loadLiveOsmShops();
  }

  Future<void> _loadLiveOsmShops() async {
    final searchLat = _userLat ?? _activeBranch.latitude;
    final searchLon = _userLon ?? _activeBranch.longitude;

    final liveShops = await NearbyShop.fetchOsmLiveSearch(
      lat: searchLat,
      lon: searchLon,
    );

    if (mounted && liveShops.isNotEmpty) {
      setState(() {
        final hub = NearbyShop.fromBranch(_activeBranch);
        _allShops = [hub, ...liveShops];
        if (!_allShops.any((s) => s.id == _selectedShop.id)) {
          _selectedShop = _allShops.first;
        }
      });
    }
  }

  void _onShopSelected(NearbyShop shop) {
    setState(() {
      _selectedShop = shop;
      if (_userLat != null && _userLon != null) {
        _userDistanceKm = LocationService.calculateDistanceKm(
          lat1: _userLat!,
          lon1: _userLon!,
          lat2: shop.latitude,
          lon2: shop.longitude,
        );
      }
    });
  }

  String get _distanceDisplay {
    if (_userDistanceKm != null) {
      return '${_userDistanceKm!.toStringAsFixed(1)} km away';
    }
    return _selectedShop.distanceText;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav Bar matching Profile and Inquiries: Back Icon Button + Title
            Container(
              color: AppTheme.bgDark,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      color: AppTheme.textPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Shop Location',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // OpenStreetMap Canvas Area with Dynamic Minimalist Circles
            Expanded(
              child: OsmInteractiveMap(
                centerLat: _activeBranch.latitude,
                centerLon: _activeBranch.longitude,
                userLat: _userLat,
                userLon: _userLon,
                shops: _allShops,
                selectedShop: _selectedShop,
                onShopSelected: _onShopSelected,
              ),
            ),

            // Bottom Selected Shop Minimal Card
            _buildShopDetailCard(context, _selectedShop),
          ],
        ),
      ),
    );
  }

  Widget _buildShopDetailCard(BuildContext context, NearbyShop shop) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: const BoxDecoration(
        color: AppTheme.headerDark,
        border: Border(
          top: BorderSide(color: AppTheme.borderDark, width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distance (km) only, no reservation or drive time wording
          Row(
            children: [
              const Icon(LucideIcons.navigation, color: AppTheme.statusCompleted, size: 13),
              const SizedBox(width: 6),
              Text(
                _distanceDisplay,
                style: const TextStyle(
                  color: AppTheme.statusCompleted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Shop Name & Rating
          Row(
            children: [
              Expanded(
                child: Text(
                  shop.name,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                  const SizedBox(width: 3),
                  Text(
                    shop.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ' (${shop.reviewCount})',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Address
          Text(
            shop.address,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Simple Call Button (No icon, full width)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Get.snackbar(
                  'Calling ${shop.name}',
                  'Connecting to ${shop.phone}...',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppTheme.surfaceElevated,
                  colorText: AppTheme.accentOrange,
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 3),
                );
              },
              child: const Text(
                'Call',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
