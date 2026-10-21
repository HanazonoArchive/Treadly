import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../controllers/inquiry/inquiry_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../core/app_theme.dart';

/// Clean Inquiries & Reservations Section for Driver Profile.
/// Replaces the complex "To Ship, Received, Returns, Cancelled" e-commerce tabs
/// with a streamlined single-shop drive-in pipeline:
/// 1. Pending (Shop checking stock)
/// 2. Confirmed (Stock held)
/// 3. Ready for Visit (Prepped in bay)
/// 4. Completed (Installed in-store)
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
              'My Inquiries',
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
              Get.find<NavigationController>().changeTab(2); // Go to Inquiries Tab
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
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildStatusButton(
                icon: LucideIcons.send,
                label: 'Inquiring',
                count: controller.inquiringCount,
                onTap: () => _navigateToStatus('Inquiring'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildStatusButton(
                icon: LucideIcons.messageSquareCheck,
                label: 'Responded',
                count: controller.respondedCount,
                onTap: () => _navigateToStatus('Responded'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildStatusButton(
                icon: LucideIcons.checkCircle2,
                label: 'Completed',
                count: controller.completedCount,
                onTap: () => _navigateToStatus('Completed'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
      Get.find<NavigationController>().changeTab(2); // Inquiries tab
    }
  }

  Widget _buildStatusButton({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.bgDark.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(10),
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
                textColor: Colors.black,
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
