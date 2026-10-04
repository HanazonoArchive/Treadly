import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/cart/cart_controller.dart';
import '../core/app_theme.dart';
import '../models/tire.dart';
import '../services/navigation_service.dart';

/// Product Details View: Simple, clean, usable showcase page for a single tire.
class ProductView extends StatefulWidget {
  final Tire? tire;
  final bool initialSetOfFour;

  const ProductView({
    super.key,
    this.tire,
    this.initialSetOfFour = false,
  });

  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  late Tire _tire;
  int _quantity = 1;
  bool _isSetOfFour = false;

  @override
  void initState() {
    super.initState();
    // Resolve tire from widget or Get.arguments
    if (widget.tire != null) {
      _tire = widget.tire!;
    } else if (Get.arguments is Tire) {
      _tire = Get.arguments as Tire;
    } else {
      // Fallback default tire
      _tire = const Tire(
        id: 'michelin-pilot-sport-5',
        brand: 'Michelin',
        model: 'Pilot Sport 5',
        category: 'Ultra High Performance Summer',
        season: 'Summer',
        width: 225,
        aspectRatio: 45,
        rimSize: 18,
        price: 219.99,
        rating: 4.9,
        reviewsCount: 512,
        stock: 36,
        imageAsset: 'assets/images/tires/michelin_pilot_sport_5.webp',
      );
    }
    _isSetOfFour = widget.initialSetOfFour && _tire.stock >= 4;
  }

  double get _effectiveUnitPrice {
    if (_isSetOfFour) {
      // 10% discount for set of 4
      return _tire.priceInPhp * 0.90;
    }
    return _tire.priceInPhp;
  }

  double get _totalPrice => _effectiveUnitPrice * (_isSetOfFour ? _quantity * 4 : _quantity);

  String _formatPrice(double amount) {
    final php = amount.toInt();
    final formatted = php.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '₱$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            NavigationService.goBackOrHome(context, targetTab: 0);
          },
        ),
        title: Text(
          _tire.brand.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tire Stage & Hero Image
            Container(
              width: double.infinity,
              height: 260,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [Color(0xFF1E283F), Color(0xFF101625)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Center(
                child: Hero(
                  tag: 'tire-${_tire.id}',
                  child: Image.asset(
                    _tire.imageAsset,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.album_rounded,
                          color: AppTheme.textSecondary,
                          size: 80,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 2. Product Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _tire.season.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.accentOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Text(
                          _tire.size,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${_tire.rating}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' (${_tire.reviewsCount})',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Brand & Model Name
                  Text(
                    _tire.brand.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _tire.model,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _tire.formattedPrice,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      if (_tire.originalPriceInPhp != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _tire.formattedOriginalPrice,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.accentOrange.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '-${_tire.discountPercentage}%',
                            style: const TextStyle(
                              color: AppTheme.accentOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        _tire.isOutOfStock ? 'Out of stock' : '${_tire.stock} in stock',
                        style: TextStyle(
                          color: _tire.isOutOfStock ? Colors.redAccent : const Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Set Bundle Selector Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141B2D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isSetOfFour = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isSetOfFour ? AppTheme.surfaceDark : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: !_isSetOfFour
                                    ? Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.4))
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Single Tire',
                                  style: TextStyle(
                                    color: !_isSetOfFour ? Colors.white : AppTheme.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _tire.stock < 4
                                ? () {
                                    Get.snackbar(
                                      'Insufficient Stock',
                                      'Only ${_tire.stock} units available for ${_tire.fullName}. Minimum 4 required for a set.',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: AppTheme.surfaceDark,
                                      colorText: AppTheme.accentOrange,
                                      margin: const EdgeInsets.all(16),
                                    );
                                  }
                                : () => setState(() => _isSetOfFour = true),
                            child: Opacity(
                              opacity: _tire.stock < 4 ? 0.4 : 1.0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isSetOfFour ? AppTheme.surfaceDark : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: _isSetOfFour
                                      ? Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.4))
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Set of 4',
                                        style: TextStyle(
                                          color: _isSetOfFour ? Colors.white : AppTheme.textSecondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentOrange,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '-10%',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Technical Specifications Grid
                  const Text(
                    'Specifications',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildSpecItem('Size Dimension', _tire.size),
                      _buildSpecItem('Speed Rating', _tire.speedRating ?? 'Y (300 km/h)'),
                      _buildSpecItem('Load Index', '${_tire.loadIndex ?? 95} (690 kg)'),
                      _buildSpecItem('Noise Level', '${_tire.noiseDb ?? 68} dB'),
                      _buildSpecItem('Wet Grip', 'Class ${_tire.wetGrip ?? 'A'}'),
                      _buildSpecItem('DOT Production', '${_tire.dotYear ?? 2024}'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  if (_tire.description != null && _tire.description!.isNotEmpty) ...[
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tire.description!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Compatible Vehicles
                  if (_tire.compatibleCars != null && _tire.compatibleCars!.isNotEmpty) ...[
                    const Text(
                      'Compatible Vehicles',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tire.compatibleCars!.map((car) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141B2D),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: Text(
                            car,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF101625),
          border: Border(top: BorderSide(color: AppTheme.borderDark)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity Counter
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141B2D),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16, color: Colors.white),
                      onPressed: (!_tire.isOutOfStock && _quantity < (_isSetOfFour ? (_tire.stock ~/ 4) : _tire.stock))
                          ? () => setState(() => _quantity++)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Add to Cart Button
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tire.isOutOfStock ? const Color(0xFF232D42) : AppTheme.accentOrange,
                    foregroundColor: _tire.isOutOfStock ? const Color(0xFF64748B) : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _tire.isOutOfStock
                      ? null
                      : () {
                          final cartController = Get.isRegistered<CartController>()
                              ? Get.find<CartController>()
                              : Get.put(CartController(), permanent: true);

                          // 1. Close product details page first using Navigator
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            NavigationService.goBackOrHome(context, targetTab: 0);
                          }

                          // 2. Add to cart (triggers bottom navigation bar bounce and confirmation)
                          cartController.addToCart(
                            tire: _tire,
                            quantity: _quantity,
                            isSetOfFour: _isSetOfFour,
                          );
                        },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_tire.isOutOfStock)
                        const Text(
                          'OUT OF STOCK',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                        )
                      else ...[
                        const Text(
                          'Add to Cart • ',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        Text(
                          _formatPrice(_totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
