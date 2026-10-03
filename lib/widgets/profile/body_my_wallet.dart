import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../controllers/profile/my_wallet_controller.dart';
import '../../core/app_theme.dart';

/// Section to display the user's wallet balance and related actions.
class MyWalletSection extends StatelessWidget {
  MyWalletSection({super.key});

  final MyWalletController controller = Get.put(MyWalletController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 10),
          _buildWalletGrid(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return const Row(
      children: [
        Text(
          'My Wallet',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWalletGrid() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Obx(
              () => _buildWalletButton(
                icon: LucideIcons.wallet,
                label: 'Balance',
                value: controller.balanceFormatted,
                onTap: () => controller.navigateToWalletDetails(),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Obx(
              () => _buildWalletButton(
                icon: LucideIcons.ticket,
                label: 'Vouchers',
                value: '${controller.vouchersCount.value}',
                onTap: () => controller.navigateToMyVouchers(),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Obx(
              () => _buildWalletButton(
                icon: LucideIcons.coins,
                label: 'Points',
                value: '${controller.activePoints}',
                onTap: () => controller.navigateToMyPoints(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.bgDark.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        splashColor: AppTheme.accentOrange.withValues(alpha: 0.2),
        highlightColor: AppTheme.accentOrange.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.accentOrange, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
