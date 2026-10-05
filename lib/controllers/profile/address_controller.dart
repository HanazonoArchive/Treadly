import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/app_theme.dart';
import '../../services/firebase_sync_service.dart';
import '../auth_controller.dart';

/// AddressController manages user delivery address state,
/// persistence with Firebase Firestore `user_addresses`, and local caching.
class AddressController extends GetxController {
  final AuthController auth = Get.find<AuthController>();

  // Reactive state
  final RxString recipientName = ''.obs;
  final RxString phoneNumber = ''.obs;
  final RxString streetAddress = ''.obs;
  final RxString city = ''.obs;
  final RxString postalCode = ''.obs;
  final RxBool isDefault = true.obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  // Form input controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();

  bool get hasAddress =>
      recipientName.value.isNotEmpty && streetAddress.value.isNotEmpty;

  String get formattedAddress {
    if (!hasAddress) return 'No address saved yet';
    final parts = [streetAddress.value, city.value, postalCode.value]
        .where((s) => s.isNotEmpty)
        .join(', ');
    return parts.isEmpty ? 'No address saved yet' : parts;
  }

  @override
  void onInit() {
    super.onInit();
    // If already authenticated on startup, fetch address
    if (!auth.isGuest.value && auth.userId.value.isNotEmpty) {
      fetchAddress(auth.userId.value);
    }
  }

  /// Syncs text controllers with current reactive values
  void populateInputs() {
    nameController.text = recipientName.value;
    phoneController.text = phoneNumber.value;
    streetController.text = streetAddress.value;
    cityController.text = city.value;
    postalCodeController.text = postalCode.value;
  }

  /// Fetches saved address from Firestore
  Future<void> fetchAddress(String userId) async {
    if (userId.isEmpty) return;
    isLoading.value = true;

    try {
      final data = await FirebaseSyncService.instance.getAddress(userId);
      if (data != null) {
        recipientName.value = data['recipient_name'] as String? ?? '';
        phoneNumber.value = data['phone_number'] as String? ?? '';
        streetAddress.value = data['street_address'] as String? ?? '';
        city.value = data['city'] as String? ?? '';
        postalCode.value = data['postal_code'] as String? ?? '';
        populateInputs();
      }
    } catch (e) {
      debugPrint('[AddressController] Note fetching address: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Saves or updates the address in Firestore
  Future<bool> saveAddress() async {
    if (auth.isGuest.value) {
      Get.toNamed('/sign-in');
      Get.snackbar(
        'Sign In Required',
        'Please sign in to save your delivery address.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final street = streetController.text.trim();
    final userCity = cityController.text.trim();
    final zip = postalCodeController.text.trim();

    if (name.isEmpty || phone.isEmpty || street.isEmpty || userCity.isEmpty) {
      Get.snackbar(
        'Incomplete Details',
        'Please complete recipient name, phone, street, and city.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }

    isSaving.value = true;
    try {
      // Update reactive values locally first for instant UI response
      recipientName.value = name;
      phoneNumber.value = phone;
      streetAddress.value = street;
      city.value = userCity;
      postalCode.value = zip;

      // Save to Firebase Firestore
      await FirebaseSyncService.instance.syncAddress(
        userId: auth.userId.value,
        recipientName: name,
        phoneNumber: phone,
        streetAddress: street,
        city: userCity,
        postalCode: zip,
      );

      Get.back(); // Dismiss modal
      Get.snackbar(
        'Address Saved',
        'Your delivery address has been saved successfully in Firebase.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return true;
    } finally {
      isSaving.value = false;
    }
  }

  /// Deletes the saved delivery address in Firestore
  Future<void> deleteAddress() async {
    if (auth.isGuest.value) return;

    await FirebaseSyncService.instance.deleteAddress(auth.userId.value);

    reset();
    Get.back();
    Get.snackbar(
      'Address Removed',
      'Saved delivery address has been removed.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  /// Clears address data upon sign out
  void reset() {
    recipientName.value = '';
    phoneNumber.value = '';
    streetAddress.value = '';
    city.value = '';
    postalCode.value = '';
    nameController.clear();
    phoneController.clear();
    streetController.clear();
    cityController.clear();
    postalCodeController.clear();
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    streetController.dispose();
    cityController.dispose();
    postalCodeController.dispose();
    super.onClose();
  }
}
