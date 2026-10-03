import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../controllers/profile/my_purchase_controller.dart';
import '../../core/app_theme.dart';

class MyPurchaseSection extends StatelessWidget {
  MyPurchaseSection({super.key});

  final MyPurchaseController controller = Get.put(MyPurchaseController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 10),
          _buildStatusGrid(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Text(
              'My Purchases',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => controller.navigateToAllPurchases(),
          child: const Text(
            'View All',
            style: TextStyle(
              color: AppTheme.accentOrange,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusGrid() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildStatusButton(
                icon: LucideIcons.package,
                label: 'To Ship',
                count: controller.activeToShip,
                onTap: () => controller.navigateToPurchaseStatus('To Ship'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildStatusButton(
                icon: LucideIcons.box,
                label: 'Received',
                count: controller.activeReceived,
                onTap: () => controller.navigateToPurchaseStatus('Received'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildStatusButton(
                icon: LucideIcons.rotateCcw,
                label: 'Returns',
                count: controller.activeReturns,
                onTap: () => controller.navigateToPurchaseStatus('Returns'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildStatusButton(
                icon: LucideIcons.archive,
                label: 'Cancelled',
                count: controller.activeCancelled,
                onTap: () => controller.navigateToPurchaseStatus('Cancelled'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required IconData icon,
    required String label,
    required int count,
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
              if (count > 0)
                Text(
                  count.toString(),
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
