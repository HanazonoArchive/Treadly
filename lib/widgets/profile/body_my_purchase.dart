import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../controllers/inquiry/inquiry_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../core/app_theme.dart';

/// Clean Customer Orders Section for Driver Profile.
/// Real-world BOPIS tire order lifecycle:
/// 1. Placed (Order received)
/// 2. Confirmed (Workshop confirmed stock and bay ready)
/// 3. Installed (Customer visited bay, fitted, and paid)
/// 4. Cancelled (Order cancelled)
class MyPurchaseSection extends StatelessWidget {
  MyPurchaseSection({super.key});

  final InquiryController controller = Get.isRegistered<InquiryController>()
      ? Get.find<InquiryController>()
      : Get.put(InquiryController(), permanent: true);

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
              'My Orders',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            controller.selectedFilter.value = 'All';
            if (Get.isRegistered<NavigationController>()) {
              Get.find<NavigationController>().changeTab(2); // Go to Orders Tab
            }
          },
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
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: _buildStatusButton(
                icon: LucideIcons.creditCard,
                label: 'Unpaid',
                count: controller.unpaidCount,
                onTap: () => _navigateToStatus('Unpaid'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: _buildStatusButton(
                icon: LucideIcons.send,
                label: 'Placed',
                count: controller.inquiringCount,
                onTap: () => _navigateToStatus('Placed'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: _buildStatusButton(
                icon: LucideIcons.checkCheck,
                label: 'Confirmed',
                count: controller.respondedCount,
                onTap: () => _navigateToStatus('Confirmed'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: _buildStatusButton(
                icon: LucideIcons.checkCircle2,
                label: 'Installed',
                count: controller.completedCount,
                onTap: () => _navigateToStatus('Installed'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: _buildStatusButton(
                icon: LucideIcons.xCircle,
                label: 'Cancelled',
                count: controller.cancelledCount,
                onTap: () => _navigateToStatus('Cancelled'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToStatus(String status) {
    controller.selectedFilter.value = status;
    if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().changeTab(2); // Orders tab
    }
  }

  Widget _buildStatusButton({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.borderDark),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: AppTheme.accentOrange.withValues(alpha: 0.2),
        highlightColor: AppTheme.accentOrange.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: count > 0,
                backgroundColor: AppTheme.accentOrange,
                textColor: Colors.white,
                label: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
                ),
                child: Icon(icon, color: AppTheme.accentOrange, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
