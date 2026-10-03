import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../auth_controller.dart';
import '../sync_controller.dart';

/// Controller for the My Wallet section and WalletView.
class MyWalletController extends GetxController {
  final AuthController auth = Get.put(AuthController(), permanent: true);

  final RxDouble rawBalance = 0.0.obs;
  final RxInt vouchersCount = 0.obs;
  final RxInt pointsCount = 0.obs;

  final TextEditingController amountInputController = TextEditingController();

  /// Pre-determined amounts for fast top-up
  final List<double> presetAmounts = [100.0, 300.0, 500.0, 1000.0, 2000.0, 5000.0];

  /// Formatted currency string with commas and 2 decimals (e.g. ₱1,250.00)
  String get balanceFormatted {
    final parts = rawBalance.value.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '₱$integerPart.${parts[1]}';
  }

  /// Points display: If on guest, always 0. If logged in, reflects actual points.
  int get activePoints => auth.isGuest.value ? 0 : pointsCount.value;

  /// Navigate to wallet details with Guest protection
  void navigateToWalletDetails() {
    if (auth.isGuest.value) {
      Get.toNamed('/sign-in');
      Get.snackbar(
        'Sign In Required',
        'Please sign in to access your wallet and balance.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    Get.toNamed('/wallet');
  }

  /// Navigate to vouchers with Guest protection and list available vouchers
  Future<void> navigateToMyVouchers() async {
    if (auth.isGuest.value) {
      Get.toNamed('/sign-in');
      Get.snackbar(
        'Sign In Required',
        'Please sign in to view and redeem vouchers.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    _showVouchersModal();
  }

  /// Shows the user's vouchers bottom sheet
  Future<void> _showVouchersModal() async {
    List<Map<String, dynamic>> userVouchers = [];
    try {
      final res = await Supabase.instance.client
          .from('user_vouchers')
          .select('id, is_available, vouchers(code, title, discount_amount, min_spend)')
          .eq('user_id', auth.userId.value);
      userVouchers = List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('[VouchersModal] Query user_vouchers note: $e');
    }

    // Fallback 1: Query global vouchers catalog if user-specific records are empty
    if (userVouchers.isEmpty) {
      try {
        final catalog = await Supabase.instance.client
            .from('vouchers')
            .select()
            .eq('is_active', true);
        for (final item in (catalog as List)) {
          userVouchers.add({
            'id': item['id'],
            'is_available': true,
            'vouchers': item,
          });
        }
      } catch (e) {
        debugPrint('[VouchersModal] Query vouchers catalog note: $e');
      }
    }

    // Fallback 2: Offline starter vouchers guarantee
    if (userVouchers.isEmpty) {
      for (final item in SyncController.defaultVouchers) {
        userVouchers.add({
          'id': item['id'],
          'is_available': true,
          'vouchers': item,
        });
      }
    }

    vouchersCount.value = userVouchers.where((v) => v['is_available'] == true).length;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.ticket, color: AppTheme.accentOrange, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'My Vouchers',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppTheme.textSecondary, size: 20),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (userVouchers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No vouchers available right now.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: userVouchers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = userVouchers[index];
                    final voucher = item['vouchers'] as Map<String, dynamic>? ?? {};
                    final code = voucher['code'] ?? 'CODE';
                    final title = voucher['title'] ?? 'Discount';
                    final isAvail = item['is_available'] == true;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAvail ? AppTheme.accentOrange.withValues(alpha: 0.3) : AppTheme.borderDark,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Code: $code',
                                style: const TextStyle(color: AppTheme.accentOrange, fontSize: 12),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAvail
                                  ? AppTheme.accentOrange.withValues(alpha: 0.15)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAvail ? 'Available' : 'Used',
                              style: TextStyle(
                                color: isAvail ? AppTheme.accentOrange : AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Navigate to points with Guest protection
  void navigateToMyPoints() {
    if (auth.isGuest.value) {
      Get.toNamed('/sign-in');
      Get.snackbar(
        'Sign In Required',
        'Please sign in to view your Treadly points.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
  }

  /// Sets the input field when tapping a pre-determined amount chip
  void selectPreset(double amount) {
    amountInputController.text = amount.toStringAsFixed(0);
  }

  /// Adds funds to the account and syncs to Supabase
  Future<void> addFunds() async {
    final text = amountInputController.text.trim();
    final amount = double.tryParse(text);

    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Please enter a valid amount to top up.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    rawBalance.value += amount;
    amountInputController.clear();
    FocusManager.instance.primaryFocus?.unfocus();

    // Sync to Supabase if authenticated
    if (!auth.isGuest.value && auth.userId.value.isNotEmpty) {
      if (Get.isRegistered<SyncController>()) {
        await Get.find<SyncController>().updateWalletBalance(auth.userId.value, rawBalance.value);
      }
    }

    Get.snackbar(
      'Funds Added',
      '₱${amount.toStringAsFixed(2)} has been added to your wallet!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  /// Calculates and adds 5% of checkout total to user points (only for logged-in accounts)
  void awardPointsFromCheckout(double checkoutTotal) {
    if (auth.isGuest.value) return;
    final earned = (checkoutTotal * 0.05).round();
    if (earned > 0) {
      pointsCount.value += earned;
      Get.snackbar(
        'Points Earned!',
        'You earned +$earned points (5% back) on this purchase.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  void onClose() {
    amountInputController.dispose();
    super.onClose();
  }
}
