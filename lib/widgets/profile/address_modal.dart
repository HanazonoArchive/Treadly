import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/profile/address_controller.dart';
import '../../core/app_theme.dart';

/// Modal bottom sheet for viewing and editing saved delivery address.
class AddressModal {
  static void show(BuildContext context) {
    final auth = Get.find<AuthController>();
    if (auth.isGuest.value) {
      Get.toNamed('/sign-in');
      Get.snackbar(
        'Sign In Required',
        'Please sign in to manage your delivery address.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final controller = Get.find<AddressController>();
    controller.populateInputs();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _AddressSheetContent(),
      ),
    );
  }
}

class _AddressSheetContent extends StatelessWidget {
  const _AddressSheetContent();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddressController>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHandle(),
            const SizedBox(height: 12),
            _buildHeader(),
            const SizedBox(height: 20),
            _buildInputField(
              label: 'Recipient Name',
              hint: 'e.g. John Doe',
              icon: LucideIcons.user,
              textController: controller.nameController,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              label: 'Mobile Number',
              hint: 'e.g. +63 917 123 4567',
              icon: LucideIcons.phone,
              textController: controller.phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              label: 'Street Address & Unit / Floor',
              hint: 'e.g. Unit 4B, 123 Radial Street',
              icon: LucideIcons.mapPin,
              textController: controller.streetController,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildInputField(
                    label: 'City / Municipality',
                    hint: 'e.g. Makati City',
                    icon: LucideIcons.building,
                    textController: controller.cityController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildInputField(
                    label: 'Postal Code',
                    hint: '1200',
                    icon: LucideIcons.mail,
                    textController: controller.postalCodeController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSaveButton(controller),
            Obx(() {
              if (controller.hasAddress) {
                return _buildDeleteButton(controller);
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.mapPin, color: AppTheme.accentOrange, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saved Delivery Address',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Used for dispatch & order tracking',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(LucideIcons.x, color: AppTheme.textSecondary, size: 20),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController textController,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgDark.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: TextField(
            controller: textController,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(AddressController controller) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: controller.isSaving.value ? null : () => controller.saveAddress(),
          child: controller.isSaving.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'Save Delivery Address',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(AddressController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextButton.icon(
          onPressed: () => controller.deleteAddress(),
          icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 16),
          label: const Text(
            'Remove Saved Address',
            style: TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
