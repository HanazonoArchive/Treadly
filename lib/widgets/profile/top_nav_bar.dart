import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../controllers/navigation_controller.dart';
import '../../controllers/profile/top_nav_bar_controller.dart';
import '../../core/app_theme.dart';

class ProfileTopNavBar extends StatelessWidget {
  ProfileTopNavBar({super.key});

  final TopNavBarController controller = Get.put(TopNavBarController());

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgDark,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          _buildBackButton(),
          const SizedBox(width: 4),
          _buildTitle(),
          const Spacer(),
          _buildSettingsButton(),
        ],
      ),
    );
  }

  /// "<" Back icon button
  Widget _buildBackButton() {
    return IconButton(
      onPressed: () {
        final nav = Get.isRegistered<NavigationController>()
            ? Get.find<NavigationController>()
            : null;
        if (nav != null) {
          nav.changeTab(0); // Return to Home
        } else {
          Get.back();
        }
      },
      icon: const Icon(
        LucideIcons.chevronLeft,
        color: AppTheme.textPrimary,
        size: 24,
      ),
    );
  }

  /// "Profile" text
  Widget _buildTitle() {
    return const Text(
      'Profile',
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Settings icon button
  Widget _buildSettingsButton() {
    return IconButton(
      onPressed: () => controller.navigateToSettings(),
      icon: const Icon(
        LucideIcons.settings,
        color: AppTheme.textPrimary,
        size: 22,
      ),
    );
  }
}
