import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../controllers/auth_controller.dart';
import '../controllers/inquiry/inquiry_controller.dart';
import '../controllers/navigation_controller.dart';
import '../core/app_theme.dart';
import '../models/inquiry.dart';
import '../models/shop_branch.dart';
import 'auth/sign_in_view.dart';
import 'inquiry_chat_view.dart';
import 'shop_location_view.dart';

/// Inquiries & Reservations View.
/// Features a clean header, a 3-stage visual connected progress stepper,
/// simple location button linking to the dedicated shop map view, and inquiry cancellation.
class InquiriesView extends StatefulWidget {
  final String initialFilter;

  const InquiriesView({
    super.key,
    this.initialFilter = 'All',
  });

  @override
  State<InquiriesView> createState() => _InquiriesViewState();
}

class _InquiriesViewState extends State<InquiriesView> {
  static const List<String> _filters = [
    'All',
    'Submitted',
    'Responded',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    final inquiryCtrl = Get.isRegistered<InquiryController>()
        ? Get.find<InquiryController>()
        : Get.put(InquiryController(), permanent: true);
    if (widget.initialFilter != 'All') {
      inquiryCtrl.selectedFilter.value = widget.initialFilter;
    }
  }

  bool _isCurrentStaff() {
    try {
      if (Get.isRegistered<AuthController>()) {
        return Get.find<AuthController>().isStaff;
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final inquiryCtrl = Get.isRegistered<InquiryController>()
        ? Get.find<InquiryController>()
        : Get.put(InquiryController(), permanent: true);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Nav Bar matching Profile page: Back Icon Button + Title
            Container(
              color: AppTheme.bgDark,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
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
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Inquiries',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const TopBarMessageButton(),
                ],
              ),
            ),

            // Filter Chips Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Obx(() {
                final currentFilter = inquiryCtrl.selectedFilter.value;
                final isStaff = _isCurrentStaff();
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = currentFilter == filter;
                      final unreadCount = inquiryCtrl.getCategoryUnreadCount(filter, isStaff: isStaff);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => inquiryCtrl.selectedFilter.value = filter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.accentOrange
                                  : AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.accentOrange
                                    : AppTheme.borderDark,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  filter,
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : const Color(0xFF94A3B8),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                if (unreadCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.black : AppTheme.accentOrange,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    child: Center(
                                      child: Text(
                                        unreadCount > 9 ? '9+' : '$unreadCount',
                                        style: TextStyle(
                                          color: isSelected ? AppTheme.accentOrange : Colors.black,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ),

            // Inquiries List or Empty State (with pull-to-refresh)
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.accentOrange,
                backgroundColor: AppTheme.surfaceDark,
                onRefresh: () async {
                  await inquiryCtrl.refreshInquiries();
                },
                child: Obx(() {
                  final isStaff = _isCurrentStaff();
                  final all = isStaff ? inquiryCtrl.staffInquiries : inquiryCtrl.customerInquiries;
                  final currentFilter = inquiryCtrl.selectedFilter.value;

                  final filtered = all.where((inq) {
                    if (currentFilter == 'Submitted' || currentFilter == 'Inquiring') {
                      return inq.status == InquiryStatus.submitted;
                    }
                    if (currentFilter == 'Responded') {
                      return inq.status == InquiryStatus.responded;
                    }
                    if (currentFilter == 'Completed') {
                      return inq.status == InquiryStatus.completed;
                    }
                    if (currentFilter == 'Cancelled') {
                      return inq.status == InquiryStatus.cancelled;
                    }
                    // 'All': shows active inquiries (Submitted, Responded, Completed), NOT Cancelled
                    return inq.status != InquiryStatus.cancelled;
                  }).toList();

                  if (filtered.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.65,
                        alignment: Alignment.center,
                        child: _buildEmptyState(currentFilter),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildInquiryCard(context, item, inquiryCtrl);
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String currentFilter) {
    bool isGuest = false;
    if (Get.isRegistered<AuthController>()) {
      isGuest = Get.find<AuthController>().isGuest.value;
    }

    String title = 'No Active Inquiries';
    String subtitle = 'You have no active inquiries at the moment.';

    if (isGuest) {
      title = 'Sign In to View Inquiries';
      subtitle = 'Log in to track your tire inquiries, reservations, and chat updates.';
    } else if (currentFilter == 'Cancelled') {
      title = 'No Cancelled Inquiries';
      subtitle = 'You have no cancelled inquiries.';
    } else if (currentFilter == 'Completed') {
      title = 'No Completed Inquiries';
      subtitle = 'You have no completed reservations yet.';
    } else if (currentFilter == 'Responded') {
      title = 'No Responded Inquiries';
      subtitle = 'You have no inquiries with new shop updates yet.';
    } else if (currentFilter == 'Submitted' || currentFilter == 'Inquiring') {
      title = 'No Submitted Inquiries';
      subtitle = 'You have no inquiries awaiting initial shop response.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.calendarClock,
                size: 34,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (isGuest) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Get.to(() => const SignInView()),
                child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInquiryCard(
    BuildContext context,
    TireInquiry item,
    InquiryController controller,
  ) {
    final isStaff = _isCurrentStaff();
    final hasUnread = isStaff ? item.hasStaffUnread : item.hasCustomerUnread;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InquiryChatView(inquiryId: item.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasUnread ? AppTheme.accentOrange.withValues(alpha: 0.6) : AppTheme.borderDark,
            width: hasUnread ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Inquiry ID + New Update Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.id.startsWith('#') ? item.id : '#${item.id}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.messageSquare, size: 11, color: AppTheme.accentOrange),
                        SizedBox(width: 4),
                        Text(
                          'New update',
                          style: TextStyle(
                            color: AppTheme.accentOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

          // Tire Item Details Row (Tire name and specs now have full width)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 58,
                  height: 58,
                  color: Colors.white.withValues(alpha: 0.03),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    item.tireImage,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.album_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.tireBrand} ${item.tireModel}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.tireSize} • ${item.isSetOfFour ? 'Set of 4 (${item.quantity * 4} pcs)' : '${item.quantity} Tire${item.quantity > 1 ? 's' : ''}'}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Note: ${item.notes}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price Breakdown (Placed above progress circles so tire title doesn't fight for space)
          _buildPriceBreakdown(item),

          // Process Stage Stepper (hidden if cancelled)
          if (item.status != InquiryStatus.cancelled) ...[
            _buildProcessStepper(item),
            const SizedBox(height: 14),
          ],

          // Bottom Action Row: Location Button, Chat Button, Cancel Inquiry
          if (item.status != InquiryStatus.cancelled)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: Clean Location Button
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final branch = ShopBranch.defaultBranches.firstWhere(
                      (b) => b.id == item.branchId,
                      orElse: () => ShopBranch.defaultBranches.first,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShopLocationView(branch: branch),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.accentOrange.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.mapPin, color: AppTheme.accentOrange, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),                // Right side: Completed badge (non-cancellable) or Cancel Inquiry Button
                if (item.status == InquiryStatus.completed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.statusCompleted.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.statusCompleted.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppTheme.statusCompleted, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: AppTheme.statusCompleted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      Get.dialog(
                        Dialog(
                          backgroundColor: AppTheme.surfaceElevated,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppTheme.borderDark),
                          ),
                          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Cancel Inquiry?',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Are you sure you want to cancel inquiry #${item.id}?',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(0xFF94A3B8),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () => Get.back(),
                                        child: const Text(
                                          'Keep Inquiry',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.statusCancelled,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () {
                                          controller.cancelInquiry(item.id);
                                          Get.back();
                                        },
                                        child: const Text(
                                          'Yes, Cancel',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Cancel Inquiry',
                      style: TextStyle(
                        color: AppTheme.statusCancelled,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    ),
    );
  }

  /// Price breakdown container placed directly above the progress circles
  Widget _buildPriceBreakdown(TireInquiry item) {
    final int count = item.totalTiresCount;
    final double origUnit = item.isSetOfFour ? (item.unitPrice / 0.90) : item.unitPrice;
    final double origTotal = origUnit * count;
    final double discountAmount = item.isSetOfFour ? (origTotal - item.totalPrice) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.headerDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated Subtotal ($count × ${_formatCurrency(origUnit)})',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
              Text(
                _formatCurrency(origTotal),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: item.isSetOfFour ? const Color(0xFF94A3B8) : Colors.white,
                  fontSize: 12,
                  fontWeight: item.isSetOfFour ? FontWeight.normal : FontWeight.bold,
                  decoration: item.isSetOfFour ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
          if (item.isSetOfFour) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Set of 4 In-Store Promo Est.',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '-${_formatCurrency(discountAmount)}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppTheme.borderDark, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.status == InquiryStatus.cancelled) ...[
                    const Text(
                      'Cancelled',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    item.formattedTotalPrice,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: item.status == InquiryStatus.cancelled
                          ? const Color(0xFF94A3B8)
                          : AppTheme.accentOrange,
                      decoration: item.status == InquiryStatus.cancelled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '* Estimated price only. In-store quotation and final payment are confirmed at the shop counter.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final php = amount.round();
    final formatted = php.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '₱$formatted';
  }

  /// Compact Vertical Connected Process Timeline (like the reference design)
  /// Features a continuous vertical connecting line, single consistent brand coloring,
  /// compact node dots/checks, and NO timestamps.
  Widget _buildProcessStepper(TireInquiry item) {
    if (item.status == InquiryStatus.cancelled) {
      return const SizedBox.shrink();
    }

    final int currentStep = item.status.stageStep; // 1 = inquiring, 2 = confirmed, 3 = reserved

    final steps = [
      {'title': 'Inquiry submitted', 'step': 1},
      {'title': 'Responded', 'step': 2},
      {'title': 'Completed', 'step': 3},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (index) {
          final stepNum = steps[index]['step'] as int;
          final title = steps[index]['title'] as String;
          final isCompleted = currentStep > stepNum;
          final isCurrent = currentStep == stepNum;
          final isPassedOrCurrent = currentStep >= stepNum;
          final isLast = index == steps.length - 1;

          // Single consistent brand coloring (clean, not over-the-top)
          const brandColor = AppTheme.accentOrange;
          const inactiveColor = AppTheme.textMuted;
          const lineActiveColor = AppTheme.accentOrange;
          const lineInactiveColor = AppTheme.borderDark;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vertical node & connecting line column
              Column(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isPassedOrCurrent
                          ? brandColor
                          : AppTheme.surfaceDark,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPassedOrCurrent
                            ? brandColor
                            : AppTheme.borderDark,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 11, color: Colors.black)
                          : isCurrent
                              ? Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: inactiveColor.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                    ),
                  ),

                  // Connecting line to next node
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 16,
                      color: currentStep > stepNum
                          ? lineActiveColor
                          : lineInactiveColor,
                    ),
                ],
              ),
              const SizedBox(width: 10),

              // Step Title (No timestamp)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isPassedOrCurrent ? Colors.white : inactiveColor,
                      fontSize: 12,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : (isCompleted ? FontWeight.w600 : FontWeight.normal),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
