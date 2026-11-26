import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/inquiry/inquiry_controller.dart';
import '../controllers/navigation_controller.dart';
import '../core/app_theme.dart';
import '../core/pricing.dart';
import '../models/tire.dart';
import '../services/navigation_service.dart';
import 'auth/sign_in_view.dart';
import '../core/toast.dart';

/// Product details: specs, compatible vehicles, Single/Set of 4 and ordering.
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
    // Tire comes from the constructor or Get.arguments
    if (widget.tire != null) {
      _tire = widget.tire!;
    } else if (Get.arguments is Tire) {
      _tire = Get.arguments as Tire;
    } else {
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

  String _formatPrice(double amount) {
    final php = amount.round();
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
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
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: double.infinity,
              height: 260,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
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
                          color: AppTheme.inputBg,
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

            // Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _tire.season.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const Text(
                        '  •  ',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      Text(
                        _tire.size,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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
                      color: AppTheme.textPrimary,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Obx(
                        () => Text(
                          _tire.formattedPrice,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '/ tire',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _tire.isOutOfStock ? 'Out of stock' : '${_tire.stock} available in shop',
                        style: TextStyle(
                          color: _tire.isOutOfStock ? Colors.redAccent : const Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Single / Set of 4
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
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
                                    color: !_isSetOfFour ? AppTheme.accentOrange : AppTheme.textSecondary,
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
                                    showToast('Only ${_tire.stock} units available for ${_tire.fullName}. Minimum 4 required for a set.');
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
                                          color: _isSetOfFour ? AppTheme.accentOrange : AppTheme.textSecondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '10% OFF',
                                        style: TextStyle(
                                          color: AppTheme.accentOrange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
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

                  // Specifications
                  const Text(
                    'Specifications',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
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
                      _buildSpecItem('Speed Rating', _tire.speedRatingFormatted),
                      _buildSpecItem('Load Index', _tire.loadIndexFormatted),
                      _buildSpecItem('Noise Level', '${_tire.noiseDb ?? 68} dB'),
                      _buildSpecItem('Wet Grip', 'Class ${_tire.wetGrip ?? 'A'}'),
                      _buildSpecItem('Fuel Efficiency', 'Class ${_tire.fuelEfficiency ?? 'B'}'),
                      _buildSpecItem('Treadwear Warranty', _tire.warrantyFormatted),
                      _buildSpecItem('DOT Production', '${_tire.dotYear ?? 2025}'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_tire.description != null && _tire.description!.isNotEmpty) ...[
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
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

                  if (_tire.compatibleCars != null && _tire.compatibleCars!.isNotEmpty) ...[
                    const Text(
                      'Compatible Vehicles',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
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
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: Text(
                            car,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
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
          color: AppTheme.headerDark,
          border: Border(top: BorderSide(color: AppTheme.borderDark)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16, color: AppTheme.textPrimary),
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16, color: AppTheme.textPrimary),
                      onPressed: (!_tire.isOutOfStock && _quantity < (_isSetOfFour ? (_tire.stock ~/ 4) : _tire.stock))
                          ? () => setState(() => _quantity++)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Order button
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tire.isOutOfStock ? AppTheme.surfaceElevated : AppTheme.accentOrange,
                    foregroundColor: _tire.isOutOfStock ? const Color(0xFF64748B) : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _tire.isOutOfStock
                      ? null
                      : () {
                          if (Get.isRegistered<AuthController>()) {
                            final auth = Get.find<AuthController>();
                            if (auth.isGuest.value || auth.userId.value.isEmpty) {
                              Get.to(() => const SignInView());
                              showToast('Please sign in to place an order.');
                              return;
                            }
                          }
                          _showInquirySheet(context);
                        },
                  child: Text(
                    _tire.isOutOfStock ? 'OUT OF STOCK' : 'Order',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showInquirySheet(BuildContext context) {
    final inquiryCtrl = Get.isRegistered<InquiryController>()
        ? Get.find<InquiryController>()
        : Get.put(InquiryController(), permanent: true);

    final notesController = TextEditingController();

    final int tireCount = _isSetOfFour ? _quantity * 4 : _quantity;
    final quote = TirePriceQuote.compute(
      unitListPrice: _tire.priceInPhp,
      tireCount: tireCount,
      isSetOfFour: _isSetOfFour,
    );
    final double serviceFee = quote.serviceFee;
    final double originalTotal = quote.listSubtotal;
    final double discountAmount = quote.discount;
    final double finalPrice = quote.total;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 14,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppTheme.borderDark, width: 1.5),
              left: BorderSide(color: AppTheme.borderDark, width: 1),
              right: BorderSide(color: AppTheme.borderDark, width: 1),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tire summary
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: AppTheme.surfaceDark,
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          _tire.imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.album_rounded,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tire.fullName,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_tire.size} • ${_tire.category}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isSetOfFour
                                ? 'Set of 4 Tires (${_quantity * 4} pcs) • 10% Bundle Discount'
                                : '$_quantity Single Tire${_quantity > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: _isSetOfFour ? AppTheme.accentOrange : const Color(0xFFCBD5E1),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price breakdown
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal ($tireCount × ${_formatPrice(_tire.priceInPhp)})',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatPrice(originalTotal),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: _isSetOfFour ? const Color(0xFF94A3B8) : AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: _isSetOfFour ? FontWeight.normal : FontWeight.bold,
                              decoration: _isSetOfFour ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ],
                      ),
                      if (_isSetOfFour) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Set of 4 Promo Discount',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '-${_formatPrice(discountAmount)}',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                color: Color(0xFF10B981),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Platform Service Fee',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatPrice(serviceFee),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: AppTheme.borderDark, height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatPrice(finalPrice),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Note for the shop
                const Text(
                  'Note',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add a note or inquiry details for the shop...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    filled: true,
                    fillColor: AppTheme.inputBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderDark),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderDark),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.accentOrange),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm Order
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      if (Get.isRegistered<AuthController>()) {
                        final auth = Get.find<AuthController>();
                        if (auth.isGuest.value || auth.userId.value.isEmpty) {
                          Navigator.pop(ctx);
                          Get.to(() => const SignInView());
                          showToast('Please sign in to place an order.');
                          return;
                        }
                      }

                      Navigator.pop(ctx); // Close sheet

                      await inquiryCtrl.createInquiry(
                        tire: _tire,
                        quantity: _quantity,
                        isSetOfFour: _isSetOfFour,
                        notes: notesController.text,
                      );

                      if (context.mounted && Navigator.canPop(context)) {
                        Navigator.pop(context); // Close product details page
                      }
                      inquiryCtrl.selectedFilter.value = 'Unpaid';
                      if (Get.isRegistered<NavigationController>()) {
                        Get.find<NavigationController>().changeTab(2); // Return to Orders tab (Tab 2)
                      }
                    },
                    child: const Text(
                      'Confirm Order',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
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
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
