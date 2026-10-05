import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../controllers/settings_controller.dart';
import '../core/app_theme.dart';
import '../services/navigation_service.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(controller),
                    const SizedBox(height: 28),
                    _buildNotificationsSection(controller),
                    const SizedBox(height: 28),
                    _buildAppStorageSection(controller),
                    const SizedBox(height: 36),
                    _buildDangerZoneSection(controller),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
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
        border: Border(bottom: BorderSide(color: AppTheme.borderDark, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.textPrimary, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => NavigationService.goBackOrHome(context, targetTab: 3),
          ),
          const SizedBox(width: 14),
          const Text(
            'Settings',
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

  Widget _buildProfileSection(SettingsController controller) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatarPicker(controller),
          const SizedBox(height: 14),
          Obx(
            () => Text(
              controller.auth.isGuest.value ? 'Guest Driver' : (controller.auth.userEmail.value),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 18),
          _buildNameInputField(controller),
        ],
      ),
    );
  }

  Widget _buildAvatarPicker(SettingsController controller) {
    return GestureDetector(
      onTap: () => _openAvatarBottomSheet(controller),
      child: Stack(
        children: [
          Obx(() {
            final avatarUrl = controller.auth.avatarUrl.value;
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bgDark,
                border: Border.all(color: AppTheme.accentOrange, width: 2.5),
                image: avatarUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: avatarUrl.isEmpty
                  ? const Icon(LucideIcons.user, color: Colors.white, size: 40)
                  : null,
            );
          }),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentOrange,
                border: Border.all(color: AppTheme.bgDark, width: 2),
              ),
              child: const Icon(LucideIcons.camera, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInputField(SettingsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.userPen, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller.nameInputController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Enter display name',
                hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          Obx(
            () => IconButton(
              icon: controller.isSavingName.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: AppTheme.accentOrange, strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.check, color: AppTheme.accentOrange, size: 20),
              tooltip: 'Save Name',
              onPressed: controller.isSavingName.value ? null : () => controller.updateName(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(SettingsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notifications',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Column(
            children: [
              Obx(
                () => _buildSwitchTile(
                  icon: LucideIcons.bell,
                  title: 'Push Notifications',
                  subtitle: 'Receive instant alerts on your phone',
                  value: controller.pushNotificationsEnabled.value,
                  onChanged: (val) => controller.pushNotificationsEnabled.value = val,
                ),
              ),
              const Divider(color: AppTheme.borderDark, height: 1),
              Obx(
                () => _buildSwitchTile(
                  icon: LucideIcons.truck,
                  title: 'Order & Delivery Updates',
                  subtitle: 'Track tire shipping and arrival',
                  value: controller.orderUpdatesEnabled.value,
                  onChanged: (val) => controller.orderUpdatesEnabled.value = val,
                ),
              ),
              const Divider(color: AppTheme.borderDark, height: 1),
              Obx(
                () => _buildSwitchTile(
                  icon: LucideIcons.sparkles,
                  title: 'Exclusive Deals & Vouchers',
                  subtitle: 'Get notified of flash discounts',
                  value: controller.promoAlertsEnabled.value,
                  onChanged: (val) => controller.promoAlertsEnabled.value = val,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentOrange, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppTheme.accentOrange,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildAppStorageSection(SettingsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'App & Storage',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: AppTheme.textSecondary, size: 20),
                title: const Text(
                  'Clear Cache & Temporary Files',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(LucideIcons.chevronRight, color: AppTheme.textSecondary, size: 18),
                onTap: () => controller.clearAppCache(),
              ),
              const Divider(color: AppTheme.borderDark, height: 1),
              const ListTile(
                leading: Icon(LucideIcons.info, color: AppTheme.textSecondary, size: 20),
                title: Text(
                  'Version',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                trailing: Text(
                  'v1.0.0 (Build 1)',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZoneSection(SettingsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Permanently remove your account and all associated purchase history and saved vouchers.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => controller.promptAccountTermination(),
              child: const Text('Terminate Account', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _openAvatarBottomSheet(SettingsController controller) {
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
                const Text(
                  'Select Driver Avatar',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppTheme.textSecondary, size: 20),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Preset Driver Avatars',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: SettingsController.avatarPresets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final url = SettingsController.avatarPresets[index];
                  return GestureDetector(
                    onTap: () => controller.setAvatar(url),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accentOrange, width: 2),
                        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Or Custom Image URL',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.customAvatarController,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'https://example.com/avatar.jpg',
                        hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final url = controller.customAvatarController.text.trim();
                      if (url.isNotEmpty) controller.setAvatar(url);
                    },
                    child: const Text('Apply', style: TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
