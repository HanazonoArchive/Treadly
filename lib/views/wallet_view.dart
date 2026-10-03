import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../controllers/profile/my_wallet_controller.dart';
import '../core/app_theme.dart';
import '../services/navigation_service.dart';

/// WalletView allows users to view their balance and simulate adding funds.
/// - 2-column pre-determined amount grid.
/// - Fixed bottom button for quick and easy top-up.
class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyWalletController());

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(controller),
                    const SizedBox(height: 24),
                    _buildTopUpSection(controller),
                  ],
                ),
              ),
            ),
            _buildBottomBar(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderDark, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.textPrimary, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => NavigationService.goBackOrHome(context, targetTab: 4),
          ),
          const SizedBox(width: 14),
          const Text(
            'My Wallet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(MyWalletController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(LucideIcons.wallet, color: AppTheme.accentOrange, size: 20),
              SizedBox(width: 8),
              Text(
                'Available Balance',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => Text(
              controller.balanceFormatted,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUpSection(MyWalletController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Up Balance',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildAmountInput(controller),
        const SizedBox(height: 16),
        _buildPresetGrid(controller),
      ],
    );
  }

  Widget _buildAmountInput(MyWalletController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: TextField(
        controller: controller.amountInputController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        decoration: const InputDecoration(
          prefixText: '₱ ',
          prefixStyle: TextStyle(
            color: AppTheme.accentOrange,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          hintText: 'Enter custom amount',
          hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          border: InputBorder.none,
        ),
      ),
    );
  }

  /// 2-Column Grid for pre-determined amounts
  Widget _buildPresetGrid(MyWalletController controller) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.8,
      ),
      itemCount: controller.presetAmounts.length,
      itemBuilder: (context, index) {
        final amount = controller.presetAmounts[index];
        final label = '+₱${amount.toStringAsFixed(0)}';

        return Material(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => controller.selectPreset(amount),
            borderRadius: BorderRadius.circular(8),
            splashColor: AppTheme.accentOrange.withValues(alpha: 0.2),
            highlightColor: AppTheme.accentOrange.withValues(alpha: 0.1),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderDark),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.accentOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Fixed bottom button bar
  Widget _buildBottomBar(MyWalletController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(
          top: BorderSide(color: AppTheme.borderDark, width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: () => controller.addFunds(),
          child: const Text(
            'Add to Account',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
