import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../controllers/auth_controller.dart';
import '../controllers/inquiry/inquiry_controller.dart';
import '../controllers/navigation_controller.dart';
import '../core/app_theme.dart';
import '../models/inquiry.dart';
import 'auth/sign_in_view.dart';
import 'inquiry_chat_view.dart';

class InquiriesView extends StatefulWidget {
  final String initialFilter;

  const InquiriesView({super.key, this.initialFilter = 'All'});

  @override
  State<InquiriesView> createState() => _InquiriesViewState();
}

class _InquiriesViewState extends State<InquiriesView> {
  static const List<String> _filters = [
    'All',
    'Unpaid',
    'Placed',
    'Confirmed',
    'Installed',
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
                        nav.changeTab(0);
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
                      'Orders',
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
                      final unreadCount = inquiryCtrl.getCategoryUnreadCount(
                        filter,
                        isStaff: isStaff,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              inquiryCtrl.selectedFilter.value = filter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
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
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                if (unreadCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.accentOrange,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        unreadCount > 9 ? '9+' : '$unreadCount',
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppTheme.accentOrange
                                              : Colors.white,
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

            Expanded(
              child: RefreshIndicator(
                color: AppTheme.accentOrange,
                backgroundColor: AppTheme.surfaceDark,
                onRefresh: () async {
                  await inquiryCtrl.refreshInquiries();
                },
                child: Obx(() {
                  final isStaff = _isCurrentStaff();
                  final all = isStaff
                      ? inquiryCtrl.staffInquiries
                      : inquiryCtrl.customerInquiries;
                  final currentFilter = inquiryCtrl.selectedFilter.value;

                  final filtered = all.where((inq) {
                    if (currentFilter == 'Unpaid') {
                      return inq.status == InquiryStatus.unpaid;
                    }
                    if (currentFilter == 'Placed' ||
                        currentFilter == 'Submitted' ||
                        currentFilter == 'Inquiring') {
                      return inq.status == InquiryStatus.submitted;
                    }
                    if (currentFilter == 'Confirmed' ||
                        currentFilter == 'Responded') {
                      return inq.status == InquiryStatus.responded;
                    }
                    if (currentFilter == 'Installed' ||
                        currentFilter == 'Completed') {
                      return inq.status == InquiryStatus.completed;
                    }
                    if (currentFilter == 'Cancelled') {
                      return inq.status == InquiryStatus.cancelled;
                    }
                    return inq.status != InquiryStatus.completed &&
                        inq.status != InquiryStatus.cancelled;
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
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
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

    String title = 'No Active Orders';
    String subtitle = 'You have no active orders at the moment.';

    if (isGuest) {
      title = 'Sign In to View Orders';
      subtitle = 'Log in to track your tire orders, bay reservations, and chat updates.';
    } else if (currentFilter == 'Unpaid') {
      title = 'No Unpaid Orders';
      subtitle = 'You have no orders awaiting payment.';
    } else if (currentFilter == 'Cancelled') {
      title = 'No Cancelled Orders';
      subtitle = 'You have no cancelled orders.';
    } else if (currentFilter == 'Installed' || currentFilter == 'Completed') {
      title = 'No Installed Orders';
      subtitle = 'You have no completed drive-in installations yet.';
    } else if (currentFilter == 'Confirmed' || currentFilter == 'Responded') {
      title = 'No Confirmed Orders';
      subtitle = 'You have no orders prepped in the workshop bay yet.';
    } else if (currentFilter == 'Placed' || currentFilter == 'Submitted' || currentFilter == 'Inquiring') {
      title = 'No Placed Orders';
      subtitle = 'You have no orders awaiting initial shop confirmation.';
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
                color: AppTheme.inputBg,
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
                color: AppTheme.textPrimary,
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
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Get.to(() => const SignInView()),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
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
            color: hasUnread
                ? AppTheme.accentOrange.withValues(alpha: 0.6)
                : AppTheme.borderDark,
            width: hasUnread ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${item.orderId}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (hasUnread)
                  const Text(
                    'NEW MESSAGE',
                    style: TextStyle(
                      color: AppTheme.accentOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 58,
                    height: 58,
                    color: AppTheme.inputBg,
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
                          color: AppTheme.textPrimary,
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

            _buildPriceBreakdown(item),

            if (item.status != InquiryStatus.cancelled) ...[
              _buildProcessStepper(item),
              const SizedBox(height: 14),
            ],

            if (item.status != InquiryStatus.cancelled)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.status == InquiryStatus.unpaid)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _showPaymentSheet(context, item, controller),
                      child: const Text(
                        'Pay Now',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  if (item.status == InquiryStatus.completed)
                    const Text(
                      'Installed',
                      style: TextStyle(
                        color: AppTheme.statusCompleted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
                              side: const BorderSide(
                                color: AppTheme.borderDark,
                              ),
                            ),
                            insetPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                22,
                                22,
                                18,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Cancel Order?',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: AppTheme.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Are you sure you want to cancel #${item.orderId}?',
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
                                            foregroundColor: const Color(
                                              0xFF94A3B8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () => Get.back(),
                                          child: const Text(
                                            'Keep Order',
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
                                            backgroundColor:
                                                AppTheme.statusCancelled,
                                            foregroundColor: AppTheme.textPrimary,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () {
                                            controller.cancelInquiry(item.id);
                                            Get.back();
                                          },
                                          child: const Text(
                                            'Cancel',
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
                        'Cancel',
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

  Widget _buildPriceBreakdown(TireInquiry item) {
    final int count = item.totalTiresCount;
    final quote = item.quote;
    final double origUnit = quote.unitListPrice;
    final double origTotal = quote.listSubtotal;
    final double discountAmount = quote.discount;

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
                'Subtotal ($count × ${_formatCurrency(origUnit)})',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
              Text(
                _formatCurrency(origTotal),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: item.isSetOfFour
                      ? const Color(0xFF94A3B8)
                      : AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: item.isSetOfFour
                      ? FontWeight.normal
                      : FontWeight.bold,
                  decoration: item.isSetOfFour
                      ? TextDecoration.lineThrough
                      : null,
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
                  'Set of 4 Promo Discount',
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
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Platform Service Fee',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
              Text(
                _formatCurrency(item.serviceFee),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppTheme.borderDark, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: AppTheme.textPrimary,
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

  Widget _buildProcessStepper(TireInquiry item) {
    if (item.status == InquiryStatus.cancelled) {
      return const SizedBox.shrink();
    }

    final int currentStep = item.status.stageStep;

    final steps = [
      {'title': 'Placed', 'step': 1},
      {'title': 'Confirmed', 'step': 2},
      {'title': 'Installed', 'step': 3},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppTheme.inputBg,
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

          const brandColor = AppTheme.accentOrange;
          const inactiveColor = AppTheme.textMuted;
          const lineActiveColor = AppTheme.accentOrange;
          const lineInactiveColor = AppTheme.borderDark;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          ? const Icon(
                              Icons.check,
                              size: 11,
                              color: Colors.white,
                            )
                          : isCurrent
                          ? Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
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

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isPassedOrCurrent ? AppTheme.textPrimary : inactiveColor,
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

  void _showPaymentSheet(
    BuildContext context,
    TireInquiry item,
    InquiryController controller,
  ) {
    String selectedMethod = 'GCash';

    final paymentMethods = [
      {
        'id': 'GCash',
        'title': 'GCash',
        'subtitle': 'Fast checkout with GCash e-Wallet',
        'icon': Icons.phone_android_rounded,
      },
      {
        'id': 'Maya',
        'title': 'Maya',
        'subtitle': 'Pay seamlessly with Maya e-Wallet',
        'icon': Icons.account_balance_wallet_rounded,
      },
      {
        'id': 'Credit / Debit Card',
        'title': 'Credit / Debit Card',
        'subtitle': 'Visa, Mastercard, or JCB',
        'icon': Icons.credit_card_rounded,
      },
      {
        'id': 'Workshop Bay Counter',
        'title': 'Pay at Workshop Counter',
        'subtitle': 'Cash or card at 108 Quezon Avenue bay',
        'icon': Icons.store_mall_directory_rounded,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                border: Border(
                  top: BorderSide(color: AppTheme.borderDark, width: 1.5),
                  left: BorderSide(color: AppTheme.borderDark, width: 1),
                  right: BorderSide(color: AppTheme.borderDark, width: 1),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '#${item.orderId}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, color: Color(0xFF94A3B8), size: 20),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.tireBrand} ${item.tireModel}',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.totalTiresCount} tire${item.totalTiresCount > 1 ? 's' : ''} (incl. ₱${item.serviceFee.toInt()} platform fee) • Workshop Bay',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.formattedTotalPrice,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      'Select Payment Method',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Column(
                      children: paymentMethods.map((m) {
                        final isSelected = selectedMethod == m['id'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedMethod = m['id'] as String;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppTheme.accentOrange : AppTheme.borderDark,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    m['icon'] as IconData,
                                    color: isSelected ? AppTheme.accentOrange : const Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m['title'] as String,
                                          style: TextStyle(
                                            color: isSelected ? AppTheme.accentOrange : AppTheme.textPrimary,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          m['subtitle'] as String,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? AppTheme.accentOrange : const Color(0xFF64748B),
                                        width: 1.5,
                                      ),
                                      color: isSelected ? AppTheme.accentOrange : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? const Center(
                                            child: Icon(Icons.check, size: 12, color: Colors.white),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(sheetCtx).pop();

                          await controller.markOrderAsPaid(
                            item.id,
                            paymentMethod: selectedMethod,
                          );

                          controller.selectedFilter.value = 'Placed';
                        },
                        child: Text(
                          'Pay ${item.formattedTotalPrice}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
