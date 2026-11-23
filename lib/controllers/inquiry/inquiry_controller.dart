import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/pricing.dart';
import '../../core/shop.dart';
import '../../models/inquiry.dart';
import '../../models/tire.dart';
import '../auth_controller.dart';
import '../../core/toast.dart';

/// Orders (inquiries), chat and analytics for both customers and staff.
class InquiryController extends GetxController {
  static const String _prefInquiriesKey = 'treadly_local_inquiries_cache';
  static const String _prefRoleKey = 'treadly_active_role_portal';

  // Portal toggle: false = customer, true = staff.
  final RxBool isShopPortal = false.obs;

  // Inquiries collections
  final RxList<TireInquiry> inquiries = <TireInquiry>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'All'.obs;

  // Analytics

  /// Revenue from completed orders (falls back to all non-cancelled orders).
  double get totalRevenue {
    final completed = inquiries.where((inq) => inq.status == InquiryStatus.completed);
    if (completed.isNotEmpty) {
      return completed.fold(0.0, (acc, inq) => acc + inq.totalPrice);
    }
    return inquiries
        .where((inq) => inq.status != InquiryStatus.cancelled)
        .fold(0.0, (acc, inq) => acc + inq.totalPrice);
  }

  /// Number of tires installed or ordered.
  int get totalUnitsFitted {
    return inquiries
        .where((inq) => inq.status != InquiryStatus.cancelled)
        .fold(0, (acc, inq) => acc + inq.totalTiresCount);
  }

  int get completedOrdersCount =>
      inquiries.where((inq) => inq.status == InquiryStatus.completed).length;

  /// Orders pending bay prep
  int get pendingPrepsCount =>
      inquiries.where((inq) => inq.status == InquiryStatus.submitted).length;

  /// Orders ready in bay
  int get bayReadyCount =>
      inquiries.where((inq) => inq.status == InquiryStatus.responded).length;

  /// Average order value.
  double get averageOrderValue {
    final valid = inquiries.where((inq) => inq.status != InquiryStatus.cancelled).toList();
    if (valid.isEmpty) return 0.0;
    return totalRevenue / valid.length;
  }

  /// Share of orders that are Set of 4.
  double get setOfFourRatio {
    final valid = inquiries.where((inq) => inq.status != InquiryStatus.cancelled).toList();
    if (valid.isEmpty) return 0.70;
    final setOfFourCount = valid.where((inq) => inq.isSetOfFour).length;
    return setOfFourCount / valid.length;
  }

  /// Top 5 tires by units ordered.
  List<Map<String, dynamic>> get topSellingTiresAnalytics =>
      getTopSellingTiresWithSort(sortBy: 'units', timeframe: 'All Time').take(5).toList();

  List<TireInquiry> getInquiriesForTimeframe(String timeframe) {
    final now = DateTime.now();
    final valid = inquiries.where((i) => i.status != InquiryStatus.cancelled).toList();
    if (timeframe == 'Today') {
      final startOfDay = DateTime(now.year, now.month, now.day);
      return valid.where((i) => i.createdAt.isAfter(startOfDay)).toList();
    } else if (timeframe == 'This Week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      return valid.where((i) => i.createdAt.isAfter(startDay)).toList();
    } else if (timeframe == 'This Month') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      return valid.where((i) => i.createdAt.isAfter(startOfMonth)).toList();
    }
    return valid;
  }

  double getTimeframeRevenue(String timeframe) {
    final inqs = getInquiriesForTimeframe(timeframe);
    final completed = inqs.where((inq) => inq.status == InquiryStatus.completed);
    if (completed.isNotEmpty) {
      return completed.fold(0.0, (acc, inq) => acc + inq.totalPrice);
    }
    return inqs.fold(0.0, (acc, inq) => acc + inq.totalPrice);
  }

  int getTimeframeUnitsFitted(String timeframe) {
    return getInquiriesForTimeframe(timeframe)
        .fold(0, (acc, inq) => acc + inq.totalTiresCount);
  }

  int getTimeframeCompletedCount(String timeframe) {
    return getInquiriesForTimeframe(timeframe)
        .where((i) => i.status == InquiryStatus.completed)
        .length;
  }

  double getTimeframeAov(String timeframe) {
    final inqs = getInquiriesForTimeframe(timeframe);
    if (inqs.isEmpty) return 0.0;
    return getTimeframeRevenue(timeframe) / inqs.length;
  }

  /// Conversion rate: completed / total non-cancelled orders
  double get conversionRate {
    final total = inquiries.where((i) => i.status != InquiryStatus.cancelled).length;
    if (total == 0) return 0.0;
    return (completedOrdersCount / total) * 100.0;
  }

  /// Top-selling tires for a timeframe, sorted by units, revenue or brand.
  List<Map<String, dynamic>> getTopSellingTiresWithSort({
    String sortBy = 'units',
    String timeframe = 'All Time',
  }) {
    final inqs = getInquiriesForTimeframe(timeframe);
    final Map<String, Map<String, dynamic>> aggregates = {};
    for (final inq in inqs) {
      final key = '${inq.tireBrand} ${inq.tireModel}';
      if (!aggregates.containsKey(key)) {
        aggregates[key] = {
          'name': key,
          'brand': inq.tireBrand,
          'model': inq.tireModel,
          'size': inq.tireSize,
          'unitsSold': 0,
          'revenue': 0.0,
        };
      }
      aggregates[key]!['unitsSold'] = (aggregates[key]!['unitsSold'] as int) + inq.totalTiresCount;
      aggregates[key]!['revenue'] = (aggregates[key]!['revenue'] as double) + inq.totalPrice;
    }

    final list = aggregates.values.toList();
    if (sortBy == 'revenue') {
      list.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    } else if (sortBy == 'brand') {
      list.sort((a, b) => (a['brand'] as String).compareTo(b['brand'] as String));
    } else {
      list.sort((a, b) => (b['unitsSold'] as int).compareTo(a['unitsSold'] as int));
    }
    return list;
  }

  /// CSV export for the Analytics tab.
  String generateCsvExport({String timeframe = 'All Time'}) {
    final inqs = getInquiriesForTimeframe(timeframe);
    final buffer = StringBuffer();
    buffer.writeln('Treadly Auto & Tire Center - Workshop Analytics Export');
    buffer.writeln('Generated,${DateTime.now().toLocal().toString().split('.').first}');
    buffer.writeln('Time Horizon,$timeframe');
    buffer.writeln('');
    buffer.writeln('=== EXECUTIVE METRICS ===');
    buffer.writeln('Metric,Value');
    buffer.writeln('Gross Revenue,PHP ${getTimeframeRevenue(timeframe).toStringAsFixed(2)}');
    buffer.writeln('Completed Bay Fittings,${getTimeframeCompletedCount(timeframe)}');
    buffer.writeln('Units Fitted,${getTimeframeUnitsFitted(timeframe)}');
    buffer.writeln('Average Order Value,PHP ${getTimeframeAov(timeframe).toStringAsFixed(2)}');
    buffer.writeln('Order Conversion Rate,${conversionRate.toStringAsFixed(1)}%');
    buffer.writeln('');
    buffer.writeln('=== TOP SELLING TIRES ===');
    buffer.writeln('Rank,Brand,Model,Size,Units Fitted,Revenue (PHP)');
    final top = getTopSellingTiresWithSort(sortBy: 'units', timeframe: timeframe);
    for (int i = 0; i < top.length; i++) {
      final t = top[i];
      buffer.writeln('${i + 1},"${t['brand']}","${t['model']}","${t['size']}",${t['unitsSold']},${(t['revenue'] as double).toStringAsFixed(2)}');
    }
    buffer.writeln('');
    buffer.writeln('=== ORDER TRANSACTIONS ===');
    buffer.writeln('Order Number,Customer Name,Phone,Tire Brand,Tire Model,Size,Units,Set of 4,Total (PHP),Status,Date');
    for (final inq in inqs) {
      buffer.writeln('${inq.orderNumber},"${inq.customerName}","${inq.customerPhone}","${inq.tireBrand}","${inq.tireModel}","${inq.tireSize}",${inq.totalTiresCount},${inq.isSetOfFour},${inq.totalPrice.toStringAsFixed(2)},${inq.status.label},${inq.createdAt.toLocal().toString().split(' ').first}');
    }
    return buffer.toString();
  }

  /// Plain-text summary for pasting into a message or email.
  String generateExecutiveTextSummary({String timeframe = 'All Time'}) {
    final buffer = StringBuffer();
    buffer.writeln('TREADLY WORKSHOP EXECUTIVE SUMMARY');
    buffer.writeln('Shop: ${Shop.name}');
    buffer.writeln('Generated: ${DateTime.now().toLocal().toString().split('.').first}');
    buffer.writeln('Timeframe: $timeframe');
    buffer.writeln('----------------------------------------');
    buffer.writeln('• Gross Revenue: ₱${getTimeframeRevenue(timeframe).toStringAsFixed(0)}');
    buffer.writeln('• Completed Bay Fittings: ${getTimeframeCompletedCount(timeframe)} orders');
    buffer.writeln('• Total Tires Fitted: ${getTimeframeUnitsFitted(timeframe)} units');
    buffer.writeln('• In Bay Preparation: ${pendingPrepsCount + bayReadyCount} orders');
    buffer.writeln('• Average Order Ticket: ₱${getTimeframeAov(timeframe).toStringAsFixed(0)}');
    buffer.writeln('• Conversion Rate: ${conversionRate.toStringAsFixed(1)}%');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Top Fitting Tires:');
    final top = getTopSellingTiresWithSort(sortBy: 'units', timeframe: timeframe).take(5).toList();
    for (int i = 0; i < top.length; i++) {
      final t = top[i];
      buffer.writeln('${i + 1}. ${t['brand']} ${t['model']} (${t['size']}): ${t['unitsSold']} units • ₱${(t['revenue'] as double).toStringAsFixed(0)}');
    }
    return buffer.toString();
  }

  // Staff names, keyed by staff id.
  final RxMap<String, String> staffNames = <String, String>{}.obs;
  final RxString activeStaffDisplayName = 'jhon'.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreSubscription;

  @override
  void onInit() {
    super.onInit();
    _initInquiryController();
  }

  @override
  void onClose() {
    _firestoreSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initInquiryController() async {
    await _loadPersistedRole();
    await _loadPersistedStaffName();
    fetchStaffDirectory();
    await _loadLocalInquiries();
    _startFirestoreInquiriesStream();

    try {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        ever(auth.userId, (_) => onUserSessionChanged());
        ever(auth.userEmail, (_) => onUserSessionChanged());
        ever(auth.isGuest, (isGuest) {
          if (isGuest) {
            clearOnSignOut();
          } else {
            onUserSessionChanged();
          }
        });
      }
    } catch (_) {}
  }

  /// Re-subscribe to Firestore when the signed-in user changes.
  void onUserSessionChanged() {
    _startFirestoreInquiriesStream();
    refreshInquiries();
  }

  Future<void> _loadPersistedStaffName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('latest_staff_name');
      if (saved != null && saved.trim().isNotEmpty && saved.trim().toLowerCase() != 'staff') {
        activeStaffDisplayName.value = saved.trim();
      }
    } catch (_) {}
  }

  /// Loads staff display names from the users collection.
  Future<void> fetchStaffDirectory() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final email = (data['email'] as String? ?? '').toLowerCase();
        final name = (data['name'] as String? ?? '').trim();
        final uid = (data['user_id'] as String? ?? doc.id).trim();
        if (email.endsWith('@treadly.com') && name.isNotEmpty) {
          if (uid.isNotEmpty) staffNames[uid] = name;
          if (email.isNotEmpty) staffNames[email] = name;
          if (name.toLowerCase() != 'staff') {
            activeStaffDisplayName.value = name;
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('latest_staff_name', name);
            } catch (_) {}
          }
        }
      }
      sanitizeStaffData();
    } catch (e) {
      debugPrint('[InquiryController] Fetch staff directory note: $e');
    }
  }

  // Order lists and counts

  bool get _isStaffViewer {
    if (!Get.isRegistered<AuthController>()) return false;
    return Get.find<AuthController>().isStaff;
  }

  /// Orders of the signed-in customer (empty for guests).
  List<TireInquiry> get customerInquiries {
    if (!Get.isRegistered<AuthController>()) return [];
    final auth = Get.find<AuthController>();
    if (auth.isGuest.value || auth.isStaff) {
      return [];
    }

    final currentUid = auth.userId.value;
    final currentEmail = auth.userEmail.value;

    return inquiries.where((i) {
      if (i.status == InquiryStatus.cancelled) return false;
      if (currentUid.isNotEmpty && i.userId == currentUid) return true;
      if (currentEmail.isNotEmpty && i.userId == currentEmail) return true;
      return false;
    }).toList();
  }

  /// Orders visible to the signed-in staff member: unclaimed orders are visible
  /// to everyone, claimed ones only to the staff member who replied.
  List<TireInquiry> get staffInquiries {
    String currentStaffId = '';
    String currentStaffEmail = '';
    String currentStaffName = '';
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      if (auth.isStaff) {
        currentStaffId = auth.userId.value.isNotEmpty ? auth.userId.value : auth.userEmail.value;
        currentStaffEmail = auth.userEmail.value;
        currentStaffName = auth.displayName.value;
      }
    }

    final activeInquiries = inquiries.where((i) => i.status != InquiryStatus.cancelled);

    if (currentStaffId.isEmpty) {
      return activeInquiries.toList();
    }

    return activeInquiries.where((i) => i.isVisibleToStaff(
      currentStaffId,
      currentStaffEmail: currentStaffEmail,
      currentStaffName: currentStaffName,
    )).toList();
  }

  int get unpaidCount => _isStaffViewer
      ? staffInquiries.where((i) => i.status == InquiryStatus.unpaid).length
      : customerInquiries.where((i) => i.status == InquiryStatus.unpaid).length;

  int get inquiringCount => _isStaffViewer
      ? staffInquiries.where((i) => i.status == InquiryStatus.submitted).length
      : customerInquiries.where((i) => i.status == InquiryStatus.submitted).length;

  int get submittedCount => inquiringCount;

  int get respondedCount => _isStaffViewer
      ? staffInquiries.where((i) => i.status == InquiryStatus.responded).length
      : customerInquiries.where((i) => i.status == InquiryStatus.responded).length;

  int get completedCount => _isStaffViewer
      ? staffInquiries.where((i) => i.status == InquiryStatus.completed).length
      : customerInquiries.where((i) => i.status == InquiryStatus.completed).length;

  int get cancelledCount => _isStaffViewer
      ? staffInquiries.where((i) => i.status == InquiryStatus.cancelled).length
      : customerInquiries.where((i) => i.status == InquiryStatus.cancelled).length;

  // Unread badge counts
  int get unreadResponsesCount => customerInquiries
      .where((i) => i.status != InquiryStatus.cancelled && i.status != InquiryStatus.completed && i.hasCustomerUnread)
      .length;

  int get unreadCustomerMessagesCount => staffInquiries
      .where((i) => i.status != InquiryStatus.cancelled && i.status != InquiryStatus.completed && i.hasStaffUnread)
      .length;

  /// Unread count for one chat filter chip.
  int getCategoryUnreadCount(String category, {required bool isStaff}) {
    final list = isStaff ? staffInquiries : customerInquiries;
    final active = list.where((i) => i.status != InquiryStatus.cancelled && i.status != InquiryStatus.completed);
    if (category == 'All') {
      return active.where((i) => isStaff ? i.hasStaffUnread : i.hasCustomerUnread).length;
    }
    if (category == 'Unpaid') {
      return active
          .where((i) => i.status == InquiryStatus.unpaid && (isStaff ? i.hasStaffUnread : i.hasCustomerUnread))
          .length;
    }
    if (category == 'Placed' || category == 'Inquired' || category == 'Submitted') {
      return active
          .where((i) => i.status == InquiryStatus.submitted && (isStaff ? i.hasStaffUnread : i.hasCustomerUnread))
          .length;
    }
    if (category == 'Confirmed' || category == 'Responded') {
      return active
          .where((i) => i.status == InquiryStatus.responded && (isStaff ? i.hasStaffUnread : i.hasCustomerUnread))
          .length;
    }
    if (category == 'Installed' || category == 'Completed') {
      return 0; // Completed conversations are done; no badge number
    }
    return 0;
  }

  int get placedCount => inquiringCount;
  int get confirmedCount => respondedCount;
  int get installedCount => completedCount;

  /// Unpaid, Placed and Confirmed orders (not yet installed or cancelled).
  List<TireInquiry> get activeInquiries => (_isStaffViewer ? staffInquiries : customerInquiries)
      .where((i) =>
          i.status == InquiryStatus.unpaid ||
          i.status == InquiryStatus.submitted ||
          i.status == InquiryStatus.responded)
      .toList();

  List<TireInquiry> get historyInquiries => (_isStaffViewer ? staffInquiries : customerInquiries)
      .where((i) => i.status == InquiryStatus.cancelled)
      .toList();

  // Portal switch

  void togglePortal() async {
    isShopPortal.value = !isShopPortal.value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefRoleKey, isShopPortal.value);
    } catch (_) {}
  }

  Future<void> _loadPersistedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isShopPortal.value = prefs.getBool(_prefRoleKey) ?? false;
    } catch (_) {}
  }

  // Creating orders

  Future<TireInquiry> createInquiry({
    required Tire tire,
    required int quantity,
    required bool isSetOfFour,
    String notes = '',
  }) async {
    String userId = 'guest';
    String userName = 'Driver Guest';
    String userPhone = '';

    try {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        if (!auth.isGuest.value && auth.userId.value.isNotEmpty) {
          userId = auth.userId.value;
          userName = auth.displayName.value;
          userPhone = auth.userEmail.value;
        }
      }
    } catch (_) {}

    final inquiryId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final totalTires = isSetOfFour ? quantity * 4 : quantity;
    final quote = TirePriceQuote.compute(
      unitListPrice: tire.priceInPhp,
      tireCount: totalTires,
      isSetOfFour: isSetOfFour,
    );
    // Stored per-tire price (discounted for sets) for backward compatibility.
    final unitPrice = isSetOfFour
        ? quote.unitListPrice * (1 - TirePriceQuote.setOfFourDiscountRate)
        : quote.unitListPrice;
    final double serviceFee = quote.serviceFee;
    final formattedTotal = TirePriceQuote.format(quote.total);
    final formattedSubtotal = TirePriceQuote.format(quote.discountedSubtotal);

    final startingBuffer = StringBuffer();
    startingBuffer.writeln('Treadly Order Details:');
    startingBuffer.writeln('• Order ID: $inquiryId');
    startingBuffer.writeln('• Product: ${tire.brand} ${tire.model} (${tire.size})');
    final qtyText = isSetOfFour
        ? 'Set of 4 (${quantity * 4} pcs)'
        : '$quantity Tire${quantity > 1 ? 's' : ''}';
    startingBuffer.writeln('• Quantity: $qtyText');
    startingBuffer.writeln('• Tires Subtotal: $formattedSubtotal');
    startingBuffer.writeln('• Platform Service Fee: ${TirePriceQuote.format(serviceFee)}');
    startingBuffer.writeln('• Total Amount: $formattedTotal');
    startingBuffer.writeln('• Workshop: ${Shop.name}');
    startingBuffer.writeln('• Bay Service: Drive-in Installation & Wheel Balancing');
    startingBuffer.writeln('• Status: Unpaid (Pending Payment)');
    if (notes.trim().isNotEmpty) {
      startingBuffer.writeln('\nCustomer Note: ${notes.trim()}');
    }

    final initialMessages = <InquiryMessage>[
      InquiryMessage(
        id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
        senderId: userId,
        senderName: userName,
        senderRole: 'customer',
        text: startingBuffer.toString().trim(),
        timestamp: DateTime.now(),
        isRead: false,
      ),
    ];

    final newInquiry = TireInquiry(
      id: inquiryId,
      userId: userId,
      customerName: userName,
      customerPhone: userPhone,
      tireId: tire.id,
      tireBrand: tire.brand,
      tireModel: tire.model,
      tireSize: tire.size,
      tireImage: tire.imageAsset,
      unitPrice: unitPrice,
      quantity: quantity,
      isSetOfFour: isSetOfFour,
      serviceFee: serviceFee,
      branchName: Shop.name,
      notes: notes.trim(),
      status: InquiryStatus.unpaid, // Initial status is UNPAID until Pay Now is completed
      messages: initialMessages,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    inquiries.insert(0, newInquiry);
    await _persistLocalInquiries();
    _syncInquiryToFirestore(newInquiry);

    return newInquiry;
  }

  /// Records the payment and moves the order to Placed.
  Future<void> markOrderAsPaid(String inquiryId, {String paymentMethod = 'GCash'}) async {
    final idx = inquiries.indexWhere((i) => i.id == inquiryId);
    if (idx == -1) return;

    final existing = inquiries[idx];
    final updatedMessages = List<InquiryMessage>.from(existing.effectiveMessages);
    final formattedTotal = existing.formattedTotalPrice;
    updatedMessages.add(
      InquiryMessage(
        id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
        senderId: existing.userId,
        senderName: existing.customerName,
        senderRole: 'customer',
        text: 'Payment Received: $formattedTotal paid via $paymentMethod.\nOrder status is now Placed and queued for workshop confirmation.',
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );

    final updated = existing.copyWith(
      status: InquiryStatus.submitted, // Transition to Placed
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    inquiries[idx] = updated;
    inquiries.refresh();
    await _persistLocalInquiries();
    _syncInquiryToFirestore(updated);
  }

  // Chat

  /// Sends a chat message. A staff reply to a Placed order confirms it.
  Future<void> sendInquiryMessage({
    required String inquiryId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final index = inquiries.indexWhere((i) => i.id == inquiryId);
    if (index < 0) return;

    final currentInquiry = inquiries[index];

    String senderId = 'guest';
    String senderName = 'Customer';
    bool isStaffSender = false;
    String currentStaffId = '';

    try {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        if (auth.userId.value.isNotEmpty) {
          senderId = auth.userId.value;
        } else if (auth.userEmail.value.isNotEmpty) {
          senderId = auth.userEmail.value;
        }
        if (auth.displayName.value.isNotEmpty) {
          senderName = auth.displayName.value;
        }
        isStaffSender = auth.isStaff;
        if (isStaffSender) {
          currentStaffId = senderId;
          if (senderName.isNotEmpty && senderName.toLowerCase() != 'staff') {
            activeStaffDisplayName.value = senderName;
          }
        }
      }
    } catch (_) {}

    final resolvedSenderName = isStaffSender
        ? (senderName.isNotEmpty && senderName.toLowerCase() != 'staff'
            ? senderName
            : (activeStaffDisplayName.value.isNotEmpty ? activeStaffDisplayName.value : 'jhon'))
        : senderName;

    final message = InquiryMessage(
      id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: resolvedSenderName,
      senderRole: isStaffSender ? 'staff' : 'customer',
      text: trimmed,
      timestamp: DateTime.now(),
      isRead: false,
    );

    final updatedMessages = List<InquiryMessage>.from(currentInquiry.effectiveMessages)..add(message);

    // First staff reply moves a Placed order to Confirmed.
    InquiryStatus newStatus = currentInquiry.status;
    if (isStaffSender && currentInquiry.status == InquiryStatus.submitted) {
      newStatus = InquiryStatus.responded;
    }

    // The staff member who replies first claims the order.
    String? assignedId = currentInquiry.assignedStaffId;
    String? assignedName = currentInquiry.assignedStaffName;
    if (isStaffSender) {
      if (assignedId == null || assignedId.isEmpty || assignedId == 'staff') {
        assignedId = currentStaffId.isNotEmpty ? currentStaffId : 'staff';
        assignedName = resolvedSenderName;
      } else {
        // Keep name fresh if staff renamed
        assignedName = resolvedSenderName;
      }
    }

    final updatedInquiry = currentInquiry.copyWith(
      messages: updatedMessages,
      status: newStatus,
      assignedStaffId: assignedId,
      assignedStaffName: assignedName,
      isCustomerViewed: isStaffSender ? false : true,
      isStaffViewed: isStaffSender ? true : false,
      updatedAt: DateTime.now(),
    );

    inquiries[index] = updatedInquiry;
    inquiries.refresh();
    await _persistLocalInquiries();

    try {
      await FirebaseFirestore.instance.collection('inquiries').doc(inquiryId).set(
        {
          'messages': updatedMessages.map((m) => m.toJson()).toList(),
          'status': newStatus.value,
          'assigned_staff_id': assignedId,
          'assigned_staff_name': assignedName,
          'is_customer_viewed': isStaffSender ? false : true,
          'is_staff_viewed': isStaffSender ? true : false,
          'updated_at': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[InquiryController] Error sending message to Firestore: $e');
    }
  }

  /// Marks the other side's messages as read.
  Future<void> markMessagesAsRead(String inquiryId, {required bool isStaffViewer}) async {
    final index = inquiries.indexWhere((i) => i.id == inquiryId);
    if (index < 0) return;

    final currentInquiry = inquiries[index];
    bool hasChanges = false;

    bool updatedCustomerViewed = currentInquiry.isCustomerViewed;
    bool updatedStaffViewed = currentInquiry.isStaffViewed;

    if (!isStaffViewer && !currentInquiry.isCustomerViewed) {
      updatedCustomerViewed = true;
      hasChanges = true;
    }
    if (isStaffViewer && !currentInquiry.isStaffViewed) {
      updatedStaffViewed = true;
      hasChanges = true;
    }

    final updatedMessages = currentInquiry.effectiveMessages.map((m) {
      // If customer is viewing, mark staff messages as read
      if (!isStaffViewer && m.isStaff && !m.isRead) {
        hasChanges = true;
        return m.copyWith(isRead: true);
      }
      // If staff is viewing, mark customer messages as read
      if (isStaffViewer && !m.isStaff && !m.isRead) {
        hasChanges = true;
        return m.copyWith(isRead: true);
      }
      return m;
    }).toList();

    if (hasChanges) {
      final updatedInquiry = currentInquiry.copyWith(
        messages: updatedMessages,
        isCustomerViewed: updatedCustomerViewed,
        isStaffViewed: updatedStaffViewed,
      );
      inquiries[index] = updatedInquiry;
      inquiries.refresh();
      await _persistLocalInquiries();

      try {
        await FirebaseFirestore.instance.collection('inquiries').doc(inquiryId).set(
          {
            'messages': updatedMessages.map((m) => m.toJson()).toList(),
            'is_customer_viewed': updatedCustomerViewed,
            'is_staff_viewed': updatedStaffViewed,
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('[InquiryController] Error marking read in Firestore: $e');
      }
    }
  }

  // Status changes

  Future<void> updateInquiryStatus(String inquiryId, InquiryStatus newStatus) async {
    final index = inquiries.indexWhere((i) => i.id == inquiryId);
    if (index >= 0) {
      final inq = inquiries[index];

      // Installed orders cannot be cancelled.
      if (inq.status == InquiryStatus.completed && newStatus == InquiryStatus.cancelled) {
        debugPrint('[InquiryController] Blocked attempt to cancel completed inquiry #$inquiryId');
        return;
      }

      String? assignedId = inq.assignedStaffId;
      String? assignedName = inq.assignedStaffName;
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        if (auth.isStaff && (assignedId == null || assignedId.isEmpty)) {
          assignedId = auth.userId.value.isNotEmpty ? auth.userId.value : auth.userEmail.value;
          assignedName = auth.displayName.value;
        }
      }

      final isCompleted = newStatus == InquiryStatus.completed;
      final updatedMessages = isCompleted
          ? inq.messages.map((m) => m.copyWith(isRead: true)).toList()
          : inq.messages;

      final updated = inq.copyWith(
        status: newStatus,
        assignedStaffId: assignedId,
        assignedStaffName: assignedName,
        messages: updatedMessages,
        isCustomerViewed: true,
        isStaffViewed: true,
        updatedAt: DateTime.now(),
      );
      inquiries[index] = updated;
      inquiries.refresh();
      await _persistLocalInquiries();

      try {
        await FirebaseFirestore.instance.collection('inquiries').doc(inquiryId).set(
          {
            'status': newStatus.value,
            'assigned_staff_id': assignedId,
            'assigned_staff_name': assignedName,
            'messages': updatedMessages.map((m) => m.toJson()).toList(),
            'is_customer_viewed': true,
            'is_staff_viewed': true,
            'updated_at': DateTime.now().toIso8601String(),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('[InquiryController] Error updating status in Firestore: $e');
      }
    }
  }

  /// Renames a staff member in every chat they took part in.
  Future<void> updateStaffDisplayName({required String staffId, required String newDisplayName}) async {
    final cleanName = newDisplayName.trim();
    if (cleanName.isEmpty) return;

    activeStaffDisplayName.value = cleanName;
    staffNames[staffId] = cleanName;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('latest_staff_name', cleanName);
    } catch (_) {}

    bool hasAnyUpdates = false;
    for (int i = 0; i < inquiries.length; i++) {
      final inq = inquiries[i];
      bool inqUpdated = false;

      String? updatedAssignedId = inq.assignedStaffId;
      String? updatedAssignedName = inq.assignedStaffName;

      final hasStaffMsgs = inq.messages.any((m) => m.isStaff);
      final isAssignedToThisStaff = inq.assignedStaffId == staffId ||
          (inq.assignedStaffId == null || inq.assignedStaffId!.isEmpty || inq.assignedStaffId == 'staff');

      if (hasStaffMsgs && isAssignedToThisStaff) {
        updatedAssignedId = staffId;
        updatedAssignedName = cleanName;
        inqUpdated = true;
      }

      final updatedMessages = inq.messages.map((m) {
        if (m.isStaff) {
          final cleanPrev = m.senderName.replaceAll(RegExp(r'\s*\(Staff\)', caseSensitive: false), '').trim();
          if (m.senderId == staffId ||
              m.senderId == 'staff' ||
              m.senderId == 'guest' ||
              cleanPrev.toLowerCase() == 'staff' ||
              cleanPrev.isEmpty ||
              m.senderRole == 'staff') {
            inqUpdated = true;
            return m.copyWith(senderName: cleanName, senderId: staffId);
          }
        }
        return m;
      }).toList();

      if (inqUpdated) {
        hasAnyUpdates = true;
        final updatedInq = inq.copyWith(
          assignedStaffId: updatedAssignedId,
          assignedStaffName: updatedAssignedName,
          messages: updatedMessages,
          updatedAt: DateTime.now(),
        );
        inquiries[i] = updatedInq;
        _syncInquiryToFirestore(updatedInq);
      }
    }

    if (hasAnyUpdates) {
      inquiries.refresh();
      await _persistLocalInquiries();
    }
  }

  /// Fixes old data: strips ' (Staff)' suffixes and replaces the generic 'staff' name
  /// with the real staff name, then saves the fix to Firestore.
  void sanitizeStaffData() {
    String resolvedStaffName = activeStaffDisplayName.value.trim();
    if (resolvedStaffName.isEmpty || resolvedStaffName.toLowerCase() == 'staff') {
      resolvedStaffName = 'jhon';
    }

    String currentStaffId = 'staff';
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      if (auth.isStaff) {
        if (auth.displayName.value.isNotEmpty && auth.displayName.value.toLowerCase() != 'staff') {
          resolvedStaffName = auth.displayName.value.trim();
          activeStaffDisplayName.value = resolvedStaffName;
        }
        if (auth.userId.value.isNotEmpty) {
          currentStaffId = auth.userId.value;
        } else if (auth.userEmail.value.isNotEmpty) {
          currentStaffId = auth.userEmail.value;
        }
      }
    }

    bool modified = false;
    for (int i = 0; i < inquiries.length; i++) {
      final inq = inquiries[i];
      bool inqChanged = false;
      String? assignedId = inq.assignedStaffId;
      String? assignedName = inq.assignedStaffName;

      // Fill in a missing or generic assignedStaffName.
      if (assignedName == null || assignedName.trim().isEmpty || assignedName.trim().toLowerCase() == 'staff') {
        if (inq.messages.any((m) => m.isStaff)) {
          assignedName = resolvedStaffName;
          inqChanged = true;
        }
      }

      final updatedMessages = inq.messages.map((m) {
        if (m.isStaff) {
          final cleanPrev = m.senderName.replaceAll(RegExp(r'\s*\(Staff\)', caseSensitive: false), '').trim();
          if (m.senderName.contains('(Staff)') ||
              cleanPrev.isEmpty ||
              cleanPrev.toLowerCase() == 'staff' ||
              cleanPrev.toLowerCase() == 'guest') {
            inqChanged = true;
            final targetName = (assignedName != null && assignedName.isNotEmpty && assignedName.toLowerCase() != 'staff')
                ? assignedName
                : resolvedStaffName;
            return m.copyWith(
              senderName: targetName,
              senderId: (m.senderId == 'staff' || m.senderId == 'guest' || m.senderId.isEmpty) ? currentStaffId : m.senderId,
            );
          }
        }
        return m;
      }).toList();

      if (inq.messages.any((m) => m.isStaff) && (assignedId == null || assignedId.isEmpty || assignedId == 'staff')) {
        assignedId = currentStaffId;
        assignedName = resolvedStaffName;
        inqChanged = true;
      }

      if (inqChanged) {
        modified = true;
        final repairedInquiry = inq.copyWith(
          messages: updatedMessages,
          assignedStaffId: assignedId,
          assignedStaffName: assignedName,
        );
        inquiries[i] = repairedInquiry;
        _syncInquiryToFirestore(repairedInquiry);
      }
    }

    if (modified) {
      inquiries.refresh();
      _persistLocalInquiries();
    }
  }

  Future<void> cancelInquiry(String inquiryId) async {
    final inq = inquiries.firstWhereOrNull((i) => i.id == inquiryId);
    if (inq != null && inq.status == InquiryStatus.completed) {
      showToast('Completed inquiries cannot be cancelled.');
      return;
    }
    await updateInquiryStatus(inquiryId, InquiryStatus.cancelled);
  }

  // Firestore sync

  Future<void> _syncInquiryToFirestore(TireInquiry inquiry) async {
    try {
      await FirebaseFirestore.instance
          .collection('inquiries')
          .doc(inquiry.id)
          .set(inquiry.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[InquiryController] Firestore push note: $e');
    }
  }

  void _startFirestoreInquiriesStream() {
    try {
      _firestoreSubscription?.cancel();

      if (!Get.isRegistered<AuthController>()) {
        inquiries.clear();
        return;
      }
      final auth = Get.find<AuthController>();

      // Guests have no orders; clear anything left from a previous user.
      if (auth.isGuest.value) {
        inquiries.clear();
        _clearLocalCache();
        return;
      }

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('inquiries');

      if (auth.isStaff) {
        // Staff: all orders (max 100), sorted on the device so no composite index is needed.
        query = query.limit(100);
      } else {
        // Customer: only their own orders.
        final uid = auth.userId.value;
        final email = auth.userEmail.value;
        query = query.where('user_id', isEqualTo: uid.isNotEmpty ? uid : email);
      }

      _firestoreSubscription = query.snapshots().listen(
        (snapshot) {
          final cloudList = snapshot.docs
              .map((doc) => TireInquiry.fromJson(doc.data()))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          inquiries.assignAll(cloudList);
          sanitizeStaffData();
          _persistLocalInquiries();
        },
        onError: (err) {
          debugPrint('[InquiryController] Firestore stream note: $err');
        },
      );
    } catch (e) {
      debugPrint('[InquiryController] Firestore init note: $e');
    }
  }

  /// Fetches orders once (pull to refresh).
  Future<void> refreshInquiries() async {
    try {
      if (!Get.isRegistered<AuthController>()) return;
      final auth = Get.find<AuthController>();
      if (auth.isGuest.value) {
        inquiries.clear();
        return;
      }

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('inquiries');
      if (auth.isStaff) {
        query = query.limit(100);
      } else {
        final uid = auth.userId.value;
        final email = auth.userEmail.value;
        query = query.where('user_id', isEqualTo: uid.isNotEmpty ? uid : email);
      }

      final snapshot = await query.get();

      final cloudList = snapshot.docs
          .map((doc) => TireInquiry.fromJson(doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      inquiries.assignAll(cloudList);
      sanitizeStaffData();
      await _persistLocalInquiries();
    } catch (e) {
      debugPrint('[InquiryController] Manual refresh error: $e');
    }
  }

  Future<void> deleteInquiry(String inquiryId) async {
    inquiries.removeWhere((i) => i.id == inquiryId);
    await _persistLocalInquiries();

    try {
      await FirebaseFirestore.instance.collection('inquiries').doc(inquiryId).delete();
    } catch (e) {
      debugPrint('[InquiryController] Error deleting from Firestore: $e');
    }
  }

  // Local cache

  /// Clears orders on sign-out.
  Future<void> clearOnSignOut() async {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    inquiries.clear();
    await _clearLocalCache();
  }

  Future<void> _clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefInquiriesKey);
    } catch (e) {
      debugPrint('[InquiryController] Clear cache note: $e');
    }
  }

  Future<void> _persistLocalInquiries() async {
    try {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        if (auth.isGuest.value) {
          return; // Never persist inquiries for guest / logged out sessions
        }
      }
      final prefs = await SharedPreferences.getInstance();
      final jsonList = inquiries.map((i) => i.toJson()).toList();
      await prefs.setString(_prefInquiriesKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[InquiryController] Local persist note: $e');
    }
  }

  Future<void> _loadLocalInquiries() async {
    try {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        if (auth.isGuest.value) {
          inquiries.clear();
          return;
        }
      }
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefInquiriesKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        final loaded = decoded
            .map((item) => TireInquiry.fromJson(item as Map<String, dynamic>))
            .toList();
        inquiries.assignAll(loaded);
        sanitizeStaffData();
      } else {
        inquiries.clear();
      }
    } catch (e) {
      debugPrint('[InquiryController] Local load note: $e');
      inquiries.clear();
    }
  }
}
