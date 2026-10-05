import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../core/backend_config.dart';
import '../../models/tire.dart';
import '../../services/firebase_sync_service.dart';
import '../../services/tire_repository.dart';
import '../auth_controller.dart';
import '../home/home_controller.dart';
import '../navigation_controller.dart';
import '../profile/my_purchase_controller.dart';
import '../search/search_controller.dart';

/// Single item in the shopping cart
class CartItem {
  final Tire tire;
  int quantity;
  final bool isSetOfFour;

  CartItem({
    required this.tire,
    this.quantity = 1,
    this.isSetOfFour = false,
  });

  /// 10% bundle discount on set of 4
  double get unitPrice => isSetOfFour ? tire.priceInPhp * 0.90 : tire.priceInPhp;
  double get totalPrice => unitPrice * (isSetOfFour ? quantity * 4 : quantity);
  int get actualTiresCount => isSetOfFour ? quantity * 4 : quantity;

  String get formattedTotalPrice {
    final php = totalPrice.toInt();
    final formatted = php.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '₱$formatted';
  }

  Map<String, dynamic> toJson() {
    return {
      'tire': tire.toJson(),
      'quantity': quantity,
      'is_set_of_four': isSetOfFour,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      tire: Tire.fromJson(json['tire'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      isSetOfFour: json['is_set_of_four'] as bool? ?? false,
    );
  }
}

/// Global Cart Controller orchestrating Treadly's 3-Tier Database System:
/// 1. Local Persistence (Fast & Offline): SharedPreferences / SQLite (never resets across restarts)
/// 2. Cloud Primary (Supabase): Synchronizes active cart for logged-in users across devices
/// 3. Cloud Mirror (Firestore): Backs up active cart if Firebase or mirroring is enabled
class CartController extends GetxController {
  static const String _prefCartKey = 'treadly_active_cart_cache';

  final RxList<CartItem> items = <CartItem>[].obs;
  final RxBool hasRecentAddition = false.obs;
  final RxBool isSyncing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initCart();
  }

  /// Initialize cart: Load local cache first, then sync with cloud if logged in
  Future<void> _initCart() async {
    await _loadFromLocalCache();

    // If authenticated user session already active, sync with cloud
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await syncWithUser(user.id);
      }
    } catch (_) {}
  }

  /// Total number of distinct items or packages in cart
  int get totalItemCount => items.fold(0, (total, item) => total + item.quantity);

  /// Total price across all items
  double get subtotal => items.fold(0.0, (total, item) => total + item.totalPrice);

  String get formattedSubtotal {
    final php = subtotal.toInt();
    final formatted = php.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '₱$formatted';
  }

  /// Adds a tire to the cart, saves to local cache, and syncs to cloud
  void addToCart({
    required Tire tire,
    int quantity = 1,
    bool isSetOfFour = false,
  }) {
    if (tire.isOutOfStock) {
      Get.snackbar(
        'Out of Stock',
        '${tire.fullName} is currently sold out.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: Colors.redAccent,
        icon: const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final neededTires = isSetOfFour ? quantity * 4 : quantity;
    if (neededTires > tire.stock) {
      Get.snackbar(
        'Stock Limit Reached',
        'Only ${tire.stock} units available for ${tire.fullName}.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        icon: const Icon(Icons.info_outline_rounded, color: AppTheme.accentOrange),
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final existingIndex = items.indexWhere(
      (item) => item.tire.id == tire.id && item.isSetOfFour == isSetOfFour,
    );

    if (existingIndex >= 0) {
      final totalNeeded = items[existingIndex].actualTiresCount + neededTires;
      if (totalNeeded > tire.stock) {
        Get.snackbar(
          'Stock Limit Reached',
          'Cannot add more than ${tire.stock} units available in stock.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.surfaceDark,
          colorText: AppTheme.accentOrange,
          margin: const EdgeInsets.all(16),
        );
        return;
      }
      items[existingIndex].quantity += quantity;
      items.refresh();
    } else {
      items.add(CartItem(
        tire: tire,
        quantity: quantity,
        isSetOfFour: isSetOfFour,
      ));
    }

    _persistToLocalCache();
    _triggerAdditionAnimation();
    _syncToCloud();

    // Show sleek confirmation snackbar
    Get.snackbar(
      'Added to Cart',
      '${isSetOfFour ? 'Set of 4' : 'Single'} ${tire.fullName} added ($quantity item${quantity > 1 ? 's' : ''})',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF141B2D),
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle_rounded, color: AppTheme.accentOrange, size: 24),
      mainButton: TextButton(
        onPressed: () {
          if (Get.isRegistered<NavigationController>()) {
            Get.find<NavigationController>().changeTab(2); // Switch to Cart tab
          }
        },
        child: const Text(
          'VIEW CART',
          style: TextStyle(
            color: AppTheme.accentOrange,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      borderColor: AppTheme.borderDark,
      borderWidth: 1.2,
    );
  }

  void updateQuantity(int index, int newQuantity) {
    if (index >= 0 && index < items.length) {
      final item = items[index];
      final maxAvailable = item.isSetOfFour ? (item.tire.stock ~/ 4) : item.tire.stock;

      if (newQuantity > maxAvailable) {
        Get.snackbar(
          'Maximum Stock Reached',
          'Only ${item.tire.stock} units available in stock.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.surfaceDark,
          colorText: AppTheme.accentOrange,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      if (newQuantity <= 0) {
        removeFromCart(index);
      } else {
        items[index].quantity = newQuantity;
        items.refresh();
        _persistToLocalCache();
        _syncToCloud();
      }
    }
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      _persistToLocalCache();
      _syncToCloud();
    }
  }

  void clearCart() {
    items.clear();
    _persistToLocalCache();
    _syncToCloud();
  }

  void _triggerAdditionAnimation() {
    hasRecentAddition.value = true;
    Future.delayed(const Duration(milliseconds: 2500), () {
      hasRecentAddition.value = false;
    });
  }

  /// Real Checkout Flow:
  /// 1. Verifies stock availability.
  /// 2. Deducts stock from Supabase, Firestore, and SQLite.
  /// 3. Records the order in Supabase and Firestore.
  /// 4. Updates profile "My Purchases" (to_ship status).
  /// 5. Clears active cart.
  Future<bool> processCheckout() async {
    if (items.isEmpty) return false;

    // Check stock for all items before committing
    for (final item in items) {
      if (item.actualTiresCount > item.tire.stock) {
        Get.snackbar(
          'Insufficient Stock',
          'Only ${item.tire.stock} units available for ${item.tire.fullName}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.surfaceDark,
          colorText: Colors.redAccent,
          margin: const EdgeInsets.all(16),
        );
        return false;
      }
    }

    isSyncing.value = true;
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final purchasedItems = List<CartItem>.from(items);
    final orderTotal = subtotal;

    try {
      // 1. Decrement stock across Supabase, Firestore, and local SQLite
      for (final item in purchasedItems) {
        await TireRepository.instance.decrementStock(
          tireId: item.tire.id,
          quantityDeducted: item.actualTiresCount,
        );
      }

      // 2. Refresh live catalog in HomeController & SearchCatalogController so UI updates immediately
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadTires();
      }
      if (Get.isRegistered<SearchCatalogController>()) {
        Get.find<SearchCatalogController>().loadTires();
      }

      // 3. Increment "To Ship" count in My Purchases
      if (Get.isRegistered<MyPurchaseController>()) {
        Get.find<MyPurchaseController>().toShipCount.value++;
      }

      // 4. Save order to Supabase & Firestore if user is authenticated
      String? currentUserId;
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        if (!auth.isGuest.value && auth.userId.value.isNotEmpty) {
          currentUserId = auth.userId.value;
        }
      }

      if (currentUserId != null) {
        // Record in Supabase
        try {
          final client = Supabase.instance.client;
          await client.from('orders').insert({
            'id': orderId,
            'user_id': currentUserId,
            'status': 'to_ship',
            'total_amount': orderTotal,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          });
          for (final item in purchasedItems) {
            await client.from('order_items').insert({
              'order_id': orderId,
              'tire_id': item.tire.id,
              'quantity': item.actualTiresCount,
              'price_at_purchase': item.unitPrice,
            });
          }
        } catch (e) {
          debugPrint('[CartController] Supabase order insert note: $e');
        }

        // Record in Firestore
        try {
          final db = FirebaseFirestore.instance;
          await db.collection('orders').doc(orderId).set({
            'id': orderId,
            'user_id': currentUserId,
            'status': 'to_ship',
            'total_amount': orderTotal,
            'item_count': purchasedItems.length,
            'created_at': FieldValue.serverTimestamp(),
          });
          for (int i = 0; i < purchasedItems.length; i++) {
            final item = purchasedItems[i];
            await db.collection('order_items').doc('${orderId}_$i').set({
              'id': '${orderId}_$i',
              'order_id': orderId,
              'tire_id': item.tire.id,
              'quantity': item.actualTiresCount,
              'price_at_purchase': item.unitPrice,
              'created_at': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          debugPrint('[CartController] Firestore order insert note: $e');
        }
      }

      // 5. Clear cart
      clearCart();

      // 6. Show Order Confirmed Dialog
      Get.dialog(
        AlertDialog(
          backgroundColor: const Color(0xFF141B2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.borderDark, width: 1.2),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppTheme.accentOrange, size: 28),
              SizedBox(width: 10),
              Text(
                'Order Placed!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #$orderId has been placed successfully.',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Paid:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(
                      '₱${orderTotal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Stock has been decremented in the database. Your tires are now marked as "To Ship" in your purchases.',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 12, height: 1.3),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Get.back(); // close dialog
                if (Get.isRegistered<NavigationController>()) {
                  Get.find<NavigationController>().changeTab(3); // navigate to Profile / Purchases
                }
              },
              child: const Text('View Purchases', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      return true;
    } catch (e) {
      debugPrint('[CartController] Checkout error: $e');
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  // ===========================================================================
  // LOCAL CACHE PERSISTENCE (Offline, Instant, Zero-Latency)
  // ===========================================================================

  Future<void> _persistToLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((i) => i.toJson()).toList();
      await prefs.setString(_prefCartKey, jsonEncode(jsonList));
      debugPrint('[CartController] Persisted ${items.length} cart items to local cache.');
    } catch (e) {
      debugPrint('[CartController] Error saving local cart cache: $e');
    }
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedString = prefs.getString(_prefCartKey);
      if (savedString != null && savedString.isNotEmpty) {
        final List<dynamic> raw = jsonDecode(savedString) as List<dynamic>;
        final loaded = raw.map((item) => CartItem.fromJson(item as Map<String, dynamic>)).toList();
        items.assignAll(loaded);
        debugPrint('[CartController] Loaded ${loaded.length} cart items from local cache.');
      }
    } catch (e) {
      debugPrint('[CartController] Note reading local cart cache: $e');
    }
  }

  // ===========================================================================
  // CLOUD SYNCHRONIZATION (Supabase PostgreSQL + Firebase Firestore)
  // ===========================================================================

  /// Synchronize cart when a user signs in or changes account
  Future<void> syncWithUser(String userId) async {
    if (userId.isEmpty) return;
    isSyncing.value = true;

    try {
      // 1. Fetch cloud cart from Supabase if primary
      if (BackendConfig.isSupabasePrimary) {
        await _mergeWithSupabaseCart(userId);
      } else {
        await _mergeWithFirestoreCart(userId);
      }

      // 2. Persist merged result locally
      await _persistToLocalCache();
    } catch (e) {
      debugPrint('[CartController] Error syncing cart with user: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> _syncToCloud() async {
    String? currentUserId;
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      if (!auth.isGuest.value && auth.userId.value.isNotEmpty) {
        currentUserId = auth.userId.value;
      }
    }

    if (currentUserId == null || currentUserId.isEmpty) return;

    // 1. Sync to Supabase
    if (BackendConfig.isSupabasePrimary || BackendConfig.mirrorToSecondary.value) {
      try {
        final client = Supabase.instance.client;
        // Clear old items for this user and insert current items
        await client.from('cart_items').delete().eq('user_id', currentUserId);

        if (items.isNotEmpty) {
          final rows = items.map((item) => {
            'user_id': currentUserId,
            'tire_id': item.tire.id,
            'quantity': item.quantity,
            'is_set_of_four': item.isSetOfFour,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).toList();
          await client.from('cart_items').insert(rows);
        }
        debugPrint('[CartController] Synced ${items.length} cart items to Supabase for $currentUserId');
      } catch (e) {
        debugPrint('[CartController] Supabase cart sync note: $e');
      }
    }

    // 2. Mirror to Firebase Firestore
    if (BackendConfig.isFirebasePrimary || BackendConfig.mirrorToSecondary.value) {
      try {
        final firestoreMaps = items.map((item) => {
          'tire_id': item.tire.id,
          'quantity': item.quantity,
          'is_set_of_four': item.isSetOfFour,
        }).toList();
        await FirebaseSyncService.instance.syncCart(currentUserId, firestoreMaps);
      } catch (e) {
        debugPrint('[CartController] Firestore cart sync note: $e');
      }
    }
  }

  Future<void> _mergeWithSupabaseCart(String userId) async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('cart_items')
          .select('tire_id, quantity, is_set_of_four')
          .eq('user_id', userId);

      if (response.isNotEmpty) {
        final catalog = await TireRepository.instance.fetchTires();
        final catalogMap = {for (final t in catalog) t.id: t};

        for (final row in response) {
          final tireId = row['tire_id'] as String;
          final qty = (row['quantity'] as num?)?.toInt() ?? 1;
          final isSet = row['is_set_of_four'] as bool? ?? false;

          final tire = catalogMap[tireId];
          if (tire != null) {
            final idx = items.indexWhere((i) => i.tire.id == tireId && i.isSetOfFour == isSet);
            if (idx >= 0) {
              if (qty > items[idx].quantity) items[idx].quantity = qty;
            } else {
              items.add(CartItem(tire: tire, quantity: qty, isSetOfFour: isSet));
            }
          }
        }
        items.refresh();
      } else if (items.isNotEmpty) {
        // Cloud was empty, push local cart
        await _syncToCloud();
      }
    } catch (e) {
      debugPrint('[CartController] Supabase merge note: $e');
    }
  }

  Future<void> _mergeWithFirestoreCart(String userId) async {
    try {
      final cloudDocs = await FirebaseSyncService.instance.getCart(userId);
      if (cloudDocs.isNotEmpty) {
        final catalog = await TireRepository.instance.fetchTires();
        final catalogMap = {for (final t in catalog) t.id: t};

        for (final row in cloudDocs) {
          final tireId = row['tire_id'] as String?;
          if (tireId == null) continue;
          final qty = (row['quantity'] as num?)?.toInt() ?? 1;
          final isSet = row['is_set_of_four'] as bool? ?? false;

          final tire = catalogMap[tireId];
          if (tire != null) {
            final idx = items.indexWhere((i) => i.tire.id == tireId && i.isSetOfFour == isSet);
            if (idx >= 0) {
              if (qty > items[idx].quantity) items[idx].quantity = qty;
            } else {
              items.add(CartItem(tire: tire, quantity: qty, isSetOfFour: isSet));
            }
          }
        }
        items.refresh();
      } else if (items.isNotEmpty) {
        await _syncToCloud();
      }
    } catch (e) {
      debugPrint('[CartController] Firestore merge note: $e');
    }
  }
}
