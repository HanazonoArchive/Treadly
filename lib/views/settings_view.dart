import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';
import '../core/app_theme.dart';
import '../core/backend_config.dart';
import '../services/firebase_sync_service.dart';
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
                    Obx(() {
                      if (controller.showDeveloperCloudSettings.value) {
                        return Column(
                          children: [
                            const SizedBox(height: 36),
                            _buildCloudDatabaseSection(),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),
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

  Widget _buildCloudDatabaseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cloud Database Architecture',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.accentOrange.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'MULTI-CLOUD',
                style: TextStyle(
                  color: AppTheme.accentOrange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          LucideIcons.database,
                          color: AppTheme.accentOrange,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Primary Database Provider',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose which cloud backend acts as your primary database',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Obx(
                      () => Row(
                        children: [
                          Expanded(
                            child: _buildDatabaseOption(
                              title: 'Supabase',
                              subtitle: 'PostgreSQL',
                              isSelected: BackendConfig.isSupabasePrimary,
                              onTap: () {
                                if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
                                BackendConfig.setPrimary(CloudBackend.supabase);
                                Get.snackbar(
                                  'Primary Database Set',
                                  'Supabase (PostgreSQL) is now your primary database.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppTheme.surfaceDark,
                                  colorText: Colors.white,
                                  margin: const EdgeInsets.all(16),
                                  duration: const Duration(milliseconds: 1400),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDatabaseOption(
                              title: 'Firebase',
                              subtitle: 'Cloud Firestore',
                              isSelected: BackendConfig.isFirebasePrimary,
                              onTap: () {
                                if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
                                BackendConfig.setPrimary(CloudBackend.firebase);
                                Get.snackbar(
                                  'Primary Database Set',
                                  'Firebase (Cloud Firestore) is now your primary database.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppTheme.surfaceDark,
                                  colorText: AppTheme.accentOrange,
                                  margin: const EdgeInsets.all(16),
                                  duration: const Duration(milliseconds: 1400),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.borderDark, height: 1),
              Obx(
                () => _buildSwitchTile(
                  icon: LucideIcons.refreshCw,
                  title: 'Real-Time Dual-Cloud Sync',
                  subtitle: 'Mirrors data to both Supabase & Firebase Firestore',
                  value: BackendConfig.mirrorToSecondary.value,
                  onChanged: (val) {
                    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
                    BackendConfig.toggleMirror(val);
                    Get.snackbar(
                      val ? 'Dual-Sync Enabled' : 'Dual-Sync Disabled',
                      val
                          ? 'Transactions mirror to both Supabase & Firebase Firestore.'
                          : 'Transactions only route to the primary database.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppTheme.surfaceDark,
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(milliseconds: 1400),
                    );
                  },
                ),
              ),
              const Divider(color: AppTheme.borderDark, height: 1),
              Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(LucideIcons.database, size: 16),
                    label: const Text(
                      'Push 1:1 Live Data to Firebase Console',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () async {
                      final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
                      final uid = (auth != null && !auth.isGuest.value) ? auth.userId.value : null;

                      Get.snackbar(
                        'Syncing to Firebase...',
                        'Writing 1:1 live collections (tires, users, wallets, vouchers, orders, addresses, cart)...',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppTheme.surfaceDark,
                        colorText: AppTheme.accentOrange,
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      );

                      final report = await FirebaseSyncService.instance.performFullMirrorSync(userId: uid);
                      final error = report['error'] as String?;

                      if (error == null) {
                        Get.snackbar(
                          'Firestore 1:1 Sync Completed!',
                          'Synced: ${report['tires_synced']} tires, ${report['catalog_vouchers_synced']} vouchers, ${report['orders_synced']} orders, ${report['order_items_synced']} order items, and user profile/wallet/cart! Check your Firebase Console.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppTheme.surfaceDark,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 5),
                        );
                      } else {
                        Get.snackbar(
                          'Firestore Sync Note',
                          'Error: $error\nEnsure Firestore rules in Firebase Console are in Test Mode (allow read, write: if true;).',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppTheme.surfaceDark,
                          colorText: Colors.redAccent,
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 6),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatabaseOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? AppTheme.accentOrange.withValues(alpha: 0.15)
          : AppTheme.bgDark.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.accentOrange : AppTheme.borderDark,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    const Icon(
                      LucideIcons.check,
                      color: AppTheme.accentOrange,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.accentOrange
                          : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
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
              Obx(
                () => ListTile(
                  leading: const Icon(LucideIcons.info, color: AppTheme.textSecondary, size: 20),
                  title: const Text(
                    'Version',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Text(
                    'v1.0.0 (Build 1)',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  onTap: controller.showDeveloperCloudSettings.value
                      ? null
                      : () => controller.onVersionTapped(),
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
