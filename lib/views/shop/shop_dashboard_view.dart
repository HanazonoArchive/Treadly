import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/home/home_controller.dart';
import '../../controllers/inquiry/inquiry_controller.dart';
import '../../core/app_theme.dart';
import '../../models/inquiry.dart';
import '../../models/tire.dart';
import '../inquiry_chat_view.dart';

class ShopDashboardView extends StatefulWidget {
  const ShopDashboardView({super.key});

  @override
  State<ShopDashboardView> createState() => _ShopDashboardViewState();
}

class _ShopDashboardViewState extends State<ShopDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedInquiryFilter = 'All';
  String _analyticsTimeframe = 'All Time';
  String _topTiresSortBy = 'units';

  static const List<String> _inquiryFilters = [
    'All',
    'Placed',
    'Confirmed',
    'Installed',
  ];

  static const List<String> _timeframeOptions = [
    'All Time',
    'This Month',
    'This Week',
    'Today',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          children: [
            _buildShopHeader(context, inquiryCtrl),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLiveInquiriesTab(context, inquiryCtrl),
                  _buildQuickInventoryTab(context),
                  _buildAnalyticsTab(context, inquiryCtrl),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(inquiryCtrl),
    );
  }

  Widget _buildShopHeader(BuildContext context, InquiryController inquiryCtrl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: AppTheme.headerDark,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderDark, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Treadly Desk',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(LucideIcons.logOut, color: AppTheme.textPrimary, size: 20),
            onPressed: () {
              if (Get.isRegistered<AuthController>()) {
                Get.find<AuthController>().signOut();
              }
            },
          ),

          IconButton(
            tooltip: 'Staff Settings',
            icon: const Icon(
              LucideIcons.settings,
              color: AppTheme.textPrimary,
              size: 20,
            ),
            onPressed: () => _showStaffSettingsDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderDark, width: 1.0),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8E9BAE),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveInquiriesTab(
    BuildContext context,
    InquiryController inquiryCtrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Obx(
            () => Row(
              children: [
                _buildMetricBox(
                  'Placed',
                  '${inquiryCtrl.inquiringCount}',
                  AppTheme.accentOrange,
                ),
                const SizedBox(width: 8),
                _buildMetricBox(
                  'Confirmed',
                  '${inquiryCtrl.respondedCount}',
                  AppTheme.statusResponded,
                ),
                const SizedBox(width: 8),
                _buildMetricBox(
                  'Installed',
                  '${inquiryCtrl.completedCount}',
                  AppTheme.statusCompleted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        _buildInquiryFilterChips(inquiryCtrl),
        const SizedBox(height: 4),

        Expanded(
          child: Obx(() {
            final allList = inquiryCtrl.staffInquiries;

            if (allList.isEmpty) {
              return const Center(
                child: Text(
                  'No orders in the workshop inbox yet',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              );
            }

            final filteredList = allList.where((inq) {
              if (_selectedInquiryFilter == 'Placed' ||
                  _selectedInquiryFilter == 'Inquiries') {
                return inq.status == InquiryStatus.submitted;
              } else if (_selectedInquiryFilter == 'Confirmed' ||
                  _selectedInquiryFilter == 'Responded') {
                return inq.status == InquiryStatus.responded;
              } else if (_selectedInquiryFilter == 'Installed' ||
                  _selectedInquiryFilter == 'Completed') {
                return inq.status == InquiryStatus.completed;
              }
              return true;
            }).toList();

            if (filteredList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.filterX,
                        size: 36,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No $_selectedInquiryFilter inquiries found',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select "All" to view all active customer conversations.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accentOrange,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedInquiryFilter = 'All';
                          });
                        },
                        icon: const Icon(LucideIcons.rotateCcw, size: 14),
                        label: const Text(
                          'Reset Filter to All',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final inq = filteredList[index];
                return _buildShopInquiryCard(context, inq, inquiryCtrl);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildInquiryFilterChips(InquiryController inquiryCtrl) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: _inquiryFilters.map((filter) {
            final isSelected = _selectedInquiryFilter == filter;

            return Padding(
              padding: const EdgeInsets.only(right: 18),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedInquiryFilter = filter;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.accentOrange
                          : const Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildShopInquiryCard(
    BuildContext context,
    TireInquiry inq,
    InquiryController controller,
  ) {
    Color statusColor;
    String statusLabel;

    switch (inq.status) {
      case InquiryStatus.unpaid:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = inq.status.label;
        break;
      case InquiryStatus.submitted:
        statusColor = AppTheme.statusSubmitted;
        statusLabel = inq.status.label;
        break;
      case InquiryStatus.responded:
        statusColor = AppTheme.statusResponded;
        statusLabel = inq.status.label;
        break;
      case InquiryStatus.completed:
        statusColor = AppTheme.statusCompleted;
        statusLabel = inq.status.label;
        break;
      case InquiryStatus.cancelled:
        statusColor = AppTheme.statusCancelled;
        statusLabel = inq.status.label;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: inq.status == InquiryStatus.submitted
              ? AppTheme.accentOrange.withValues(alpha: 0.6)
              : AppTheme.borderDark,
          width: inq.status == InquiryStatus.submitted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.user,
                    size: 14,
                    color: AppTheme.accentOrange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    inq.customerName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (inq.status != InquiryStatus.completed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 50,
                  height: 50,
                  color: AppTheme.inputBg,
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    inq.tireImage,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.album_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${inq.tireBrand} ${inq.tireModel}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${inq.tireSize} • ${inq.isSetOfFour ? 'Set of 4' : '${inq.quantity} Tire(s)'}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Vehicle: ${inq.vehicleModel} • Visit: ${inq.preferredDate}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                inq.formattedTotalPrice,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppTheme.accentOrange,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          if (inq.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.inputBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Customer Note: ${inq.notes}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(color: AppTheme.borderDark, height: 1),
          const SizedBox(height: 12),

          _buildShopActionRow(inq, controller),
        ],
      ),
    );
  }

  Widget _buildShopActionRow(TireInquiry inq, InquiryController controller) {
    if (inq.status == InquiryStatus.unpaid) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                controller.updateInquiryStatus(inq.id, InquiryStatus.cancelled);
                Get.snackbar(
                  'Order Cancelled',
                  'Order #${inq.orderId} cancelled.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppTheme.surfaceElevated,
                  colorText: AppTheme.statusCancelled,
                );
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentOrange,
                side: const BorderSide(color: AppTheme.accentOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                Get.to(() => InquiryChatView(inquiryId: inq.id));
              },
              child: const Text(
                'Chat (Awaiting Payment)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
        ],
      );
    } else if (inq.status == InquiryStatus.submitted) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                controller.updateInquiryStatus(inq.id, InquiryStatus.cancelled);
                Get.snackbar(
                  'Order Declined',
                  'Order #${inq.orderId} marked as unavailable.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppTheme.surfaceElevated,
                  colorText: AppTheme.statusCancelled,
                );
              },
              child: const Text(
                'Decline',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentOrange,
                side: const BorderSide(color: AppTheme.accentOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                Get.to(() => InquiryChatView(inquiryId: inq.id));
              },
              child: const Text(
                'Chat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                controller.updateInquiryStatus(inq.id, InquiryStatus.responded);
                Get.snackbar(
                  'Order Confirmed',
                  'Order #${inq.orderId} confirmed and queued for bay.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppTheme.surfaceElevated,
                  colorText: AppTheme.statusResponded,
                );
              },
              child: const Text(
                'Confirm Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
        ],
      );
    } else if (inq.status == InquiryStatus.responded) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.statusResponded,
                side: const BorderSide(color: AppTheme.statusResponded),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(LucideIcons.messageSquare, size: 15),
              label: Text(
                inq.messages.isEmpty ? 'Chat' : 'Chat (${inq.messages.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              onPressed: () {
                Get.to(() => InquiryChatView(inquiryId: inq.id));
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusCompleted,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                controller.updateInquiryStatus(inq.id, InquiryStatus.completed);
              },
              child: const Text(
                'Complete',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    } else if (inq.status == InquiryStatus.completed) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Completed',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(
              LucideIcons.messageSquare,
              size: 13,
              color: AppTheme.accentOrange,
            ),
            label: const Text(
              'View Chat',
              style: TextStyle(
                color: AppTheme.accentOrange,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Get.to(() => InquiryChatView(inquiryId: inq.id));
            },
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Archived (${inq.status.label})',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildQuickInventoryTab(BuildContext context) {
    final homeCtrl = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController(), permanent: true);

    return Obx(() {
      final tires = homeCtrl.tires;

      if (tires.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.accentOrange),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tires.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tire = tires[index];
          return InkWell(
            onTap: () => _showEditTireDialog(context, tire, homeCtrl),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: AppTheme.inputBg,
                      child: Image.asset(
                        tire.imageAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
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
                          tire.fullName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${tire.size} • ${tire.formattedPrice}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    tire.isOutOfStock
                        ? 'OUT OF STOCK'
                        : '${tire.stock} IN STOCK',
                    style: TextStyle(
                      color: tire.isOutOfStock
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF64748B),
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildAnalyticsTab(
    BuildContext context,
    InquiryController inquiryCtrl,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Obx(() {
        final timeframeRevenue = inquiryCtrl.getTimeframeRevenue(
          _analyticsTimeframe,
        );
        final timeframeUnits = inquiryCtrl.getTimeframeUnitsFitted(
          _analyticsTimeframe,
        );
        final timeframeCompleted = inquiryCtrl.getTimeframeCompletedCount(
          _analyticsTimeframe,
        );
        final timeframeAov = inquiryCtrl.getTimeframeAov(_analyticsTimeframe);
        final timeframeInqs = inquiryCtrl.getInquiriesForTimeframe(
          _analyticsTimeframe,
        );
        final setOfFourPct = (inquiryCtrl.setOfFourRatio * 100)
            .clamp(0, 100)
            .toInt();
        final singlePct = 100 - setOfFourPct;

        final topTires = inquiryCtrl.getTopSellingTiresWithSort(
          sortBy: _topTiresSortBy,
          timeframe: _analyticsTimeframe,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _timeframeOptions.map((timeframe) {
                        final isSelected = _analyticsTimeframe == timeframe;
                        return Padding(
                          padding: const EdgeInsets.only(right: 18),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _analyticsTimeframe = timeframe;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    timeframe,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.accentOrange
                                          : AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 2,
                                    width: isSelected ? 22 : 0,
                                    color: isSelected
                                        ? AppTheme.accentOrange
                                        : Colors.transparent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showExportSheet(context, inquiryCtrl),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentOrange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.download, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Export',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GROSS REVENUE (${_analyticsTimeframe.toUpperCase()})',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${_formatAmount(timeframeRevenue)}',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_analyticsTimeframe completed bay installations & scheduled orders',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildSimpleMetricCard(
                    label: 'Completed Orders',
                    value: '$timeframeCompleted',
                    color: AppTheme.statusCompleted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSimpleMetricCard(
                    label: 'Units Installed',
                    value: '$timeframeUnits pcs',
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSimpleMetricCard(
                    label: 'In Bay Preparation',
                    value:
                        '${inquiryCtrl.pendingPrepsCount + inquiryCtrl.bayReadyCount}',
                    color: AppTheme.accentOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSimpleMetricCard(
                    label: 'Avg. Order Ticket',
                    value: '₱${_formatAmount(timeframeAov)}',
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Order Pipeline & Conversion',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Overall Conversion Rate',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${inquiryCtrl.conversionRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: AppTheme.statusCompleted,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildPipelineStageItem(
                        'Placed',
                        timeframeInqs
                            .where((i) => i.status == InquiryStatus.submitted)
                            .length,
                        AppTheme.accentOrange,
                      ),
                      _buildPipelineStageItem(
                        'Confirmed',
                        timeframeInqs
                            .where((i) => i.status == InquiryStatus.responded)
                            .length,
                        AppTheme.statusResponded,
                      ),
                      _buildPipelineStageItem(
                        'Installed',
                        timeframeInqs
                            .where((i) => i.status == InquiryStatus.completed)
                            .length,
                        AppTheme.statusCompleted,
                      ),
                      _buildPipelineStageItem(
                        'Cancelled',
                        timeframeInqs
                            .where((i) => i.status == InquiryStatus.cancelled)
                            .length,
                        const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Sales Distribution',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: [
                          Expanded(
                            flex: setOfFourPct,
                            child: Container(color: AppTheme.accentOrange),
                          ),
                          Expanded(
                            flex: singlePct,
                            child: Container(color: const Color(0xFF38BDF8)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.accentOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Set of 4 ($setOfFourPct%)',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF38BDF8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Single Replacements ($singlePct%)',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Selling Tires',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSortOption('units', 'Units'),
                    const Text(
                      ' • ',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    _buildSortOption('revenue', 'Revenue'),
                    const Text(
                      ' • ',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    _buildSortOption('brand', 'Brand'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: topTires.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No completed sales yet',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: List.generate(topTires.length, (idx) {
                        final item = topTires[idx];
                        final isLast = idx == topTires.length - 1;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${idx + 1}',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentOrange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item['brand']} ${item['model']}',
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item['unitsSold']} units fitted  •  ₱${_formatAmount(item['revenue'] as double)}',
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              const Divider(
                                color: AppTheme.borderDark,
                                height: 1,
                              ),
                          ],
                        );
                      }),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        );
      }),
    );
  }

  Widget _buildSortOption(String id, String label) {
    final isSelected = _topTiresSortBy == id;
    return InkWell(
      onTap: () {
        setState(() {
          _topTiresSortBy = id;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accentOrange : const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            decoration: isSelected
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: AppTheme.accentOrange,
          ),
        ),
      ),
    );
  }

  Widget _buildPipelineStageItem(String label, int count, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportSheet(BuildContext context, InquiryController inquiryCtrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Export Workshop Data',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                Text(
                  'Time Horizon: $_analyticsTimeframe',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    LucideIcons.fileSpreadsheet,
                    color: AppTheme.accentOrange,
                  ),
                  title: const Text(
                    'Copy CSV Dataset',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Full transactional dataset with KPIs & tire sales formatted for Excel or Google Sheets',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    final csv = inquiryCtrl.generateCsvExport(
                      timeframe: _analyticsTimeframe,
                    );
                    Clipboard.setData(ClipboardData(text: csv));
                    Get.snackbar(
                      'CSV Export Copied',
                      'Dataset copied to clipboard. Ready to paste into Excel or Google Sheets.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppTheme.surfaceDark,
                      colorText: AppTheme.textPrimary,
                      duration: const Duration(seconds: 3),
                    );
                  },
                ),
                const Divider(color: AppTheme.borderDark, height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    LucideIcons.fileText,
                    color: Color(0xFF38BDF8),
                  ),
                  title: const Text(
                    'Copy Executive Summary',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Human-readable overview ready for email, messaging, or store reviews',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    final summary = inquiryCtrl.generateExecutiveTextSummary(
                      timeframe: _analyticsTimeframe,
                    );
                    Clipboard.setData(ClipboardData(text: summary));
                    Get.snackbar(
                      'Executive Summary Copied',
                      'Summary copied to clipboard. Ready to paste.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppTheme.surfaceDark,
                      colorText: AppTheme.textPrimary,
                      duration: const Duration(seconds: 3),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimpleMetricCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final php = amount.toInt();
    final formatted = php.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return formatted;
  }

  Widget _buildBottomNavigationBar(InquiryController inquiryCtrl) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.headerDark,
        border: Border(top: BorderSide(color: AppTheme.borderDark, width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Obx(
                () => _buildBottomNavItem(
                  index: 0,
                  icon: LucideIcons.inbox,
                  label: 'Live Orders',
                  badgeCount: inquiryCtrl.unreadCustomerMessagesCount,
                ),
              ),
              _buildBottomNavItem(
                index: 1,
                icon: LucideIcons.package,
                label: 'Inventory',
              ),
              _buildBottomNavItem(
                index: 2,
                icon: LucideIcons.barChart2,
                label: 'Analytics',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = _tabController.index == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _tabController.animateTo(index);
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentOrange.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? AppTheme.accentOrange
                        : const Color(0xFF8E9BAE),
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.headerDark,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.accentOrange
                    : const Color(0xFF8E9BAE),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStaffSettingsDialog(BuildContext context) {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final initialName = auth?.displayName.value ?? 'Staff';
    final nameCtrl = TextEditingController(text: initialName);

    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.borderDark),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Staff Settings',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Customize your Treadly Desk identity',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        color: Color(0xFF94A3B8),
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                const Text(
                  'Display Name',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.inputBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
                    decoration: const InputDecoration(
                      icon: Icon(
                        LucideIcons.user,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      hintText: 'Enter your name (e.g. Mark Santos)',
                      hintStyle: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'This name appears on chat messages sent to customers.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                const SizedBox(height: 20),

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
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          final newName = nameCtrl.text.trim();
                          if (newName.isNotEmpty && auth != null) {
                            auth.updateDisplayName(newName);
                          }
                          Get.back();
                          Get.snackbar(
                            'Settings Saved',
                            'Staff name updated to "$newName"',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppTheme.surfaceElevated,
                            colorText: AppTheme.textPrimary,
                            icon: const Icon(
                              LucideIcons.checkCheck,
                              color: AppTheme.accentOrange,
                            ),
                          );
                        },
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 13,
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
      ),
    );
  }

  void _showEditTireDialog(
    BuildContext context,
    Tire tire,
    HomeController homeCtrl,
  ) {
    int stock = tire.stock;
    final priceCtrl = TextEditingController(
      text: tire.priceInPhp.toInt().toString(),
    );
    final origPriceCtrl = TextEditingController(
      text: tire.originalPriceInPhp != null
          ? tire.originalPriceInPhp!.toInt().toString()
          : '',
    );
    final widthCtrl = TextEditingController(text: tire.width.toString());
    final aspectCtrl = TextEditingController(text: tire.aspectRatio.toString());
    final rimCtrl = TextEditingController(text: tire.rimSize.toString());
    final speedCtrl = TextEditingController(text: tire.speedRating ?? '');
    final loadCtrl = TextEditingController(
      text: tire.loadIndex?.toString() ?? '',
    );
    final categoryCtrl = TextEditingController(text: tire.category);
    final seasonCtrl = TextEditingController(text: tire.season);
    final descCtrl = TextEditingController(text: tire.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isOut = stock <= 0;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: Container(
              width: 520,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.borderDark),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 44,
                            height: 44,
                            color: AppTheme.inputBg,
                            child: Image.asset(
                              tire.imageAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
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
                                tire.fullName,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Modify Stock & Specifications',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF1E293B), height: 1),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderDark),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'STOCK QUANTITY',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      isOut
                                          ? 'OUT OF STOCK'
                                          : '$stock IN STOCK',
                                      style: TextStyle(
                                        color: isOut
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF10B981),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildCircleStepperButton(
                                      icon: LucideIcons.minus,
                                      onPressed: stock > 0
                                          ? () => setModalState(
                                              () => stock = (stock - 1).clamp(
                                                0,
                                                99999,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.inputBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppTheme.borderDark,
                                        ),
                                      ),
                                      child: Text(
                                        '$stock',
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    _buildCircleStepperButton(
                                      icon: LucideIcons.plus,
                                      onPressed: () =>
                                          setModalState(() => stock++),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildQuickStockChip(
                                      label: 'Zero (0)',
                                      color: const Color(0xFFEF4444),
                                      onTap: () =>
                                          setModalState(() => stock = 0),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQuickStockChip(
                                      label: '+4 Set',
                                      color: AppTheme.accentOrange,
                                      onTap: () =>
                                          setModalState(() => stock += 4),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQuickStockChip(
                                      label: '+8 Set',
                                      color: AppTheme.accentOrange,
                                      onTap: () =>
                                          setModalState(() => stock += 8),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQuickStockChip(
                                      label: '+20 Bulk',
                                      color: const Color(0xFF10B981),
                                      onTap: () =>
                                          setModalState(() => stock += 20),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'PRICING (PHP)',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogInput(
                                  label: 'Selling Price (₱)',
                                  controller: priceCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDialogInput(
                                  label: 'Original Price (₱)',
                                  controller: origPriceCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'SIZE SPECIFICATIONS',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogInput(
                                  label: 'Width (mm)',
                                  controller: widthCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDialogInput(
                                  label: 'Aspect Ratio',
                                  controller: aspectCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDialogInput(
                                  label: 'Rim (inch)',
                                  controller: rimCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogInput(
                                  label: 'Speed Rating (e.g. Y, W)',
                                  controller: speedCtrl,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDialogInput(
                                  label: 'Load Index (e.g. 98)',
                                  controller: loadCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogInput(
                                  label: 'Category',
                                  controller: categoryCtrl,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDialogInput(
                                  label: 'Season',
                                  controller: seasonCtrl,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'DESCRIPTION',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildDialogInput(
                            label: 'Product Description',
                            controller: descCtrl,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(color: Color(0xFF1E293B), height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
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
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentOrange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              final double newPrice =
                                  double.tryParse(
                                    priceCtrl.text.replaceAll(',', '').trim(),
                                  ) ??
                                  tire.price;
                              final double? newOrigPrice =
                                  origPriceCtrl.text.trim().isNotEmpty
                                  ? double.tryParse(
                                      origPriceCtrl.text
                                          .replaceAll(',', '')
                                          .trim(),
                                    )
                                  : null;
                              final int newWidth =
                                  int.tryParse(widthCtrl.text.trim()) ??
                                  tire.width;
                              final int newAspect =
                                  int.tryParse(aspectCtrl.text.trim()) ??
                                  tire.aspectRatio;
                              final int newRim =
                                  int.tryParse(rimCtrl.text.trim()) ??
                                  tire.rimSize;
                              final String? newSpeed =
                                  speedCtrl.text.trim().isNotEmpty
                                  ? speedCtrl.text.trim()
                                  : tire.speedRating;
                              final int? newLoad =
                                  int.tryParse(loadCtrl.text.trim()) ??
                                  tire.loadIndex;
                              final String newCategory =
                                  categoryCtrl.text.trim().isNotEmpty
                                  ? categoryCtrl.text.trim()
                                  : tire.category;
                              final String newSeason =
                                  seasonCtrl.text.trim().isNotEmpty
                                  ? seasonCtrl.text.trim()
                                  : tire.season;
                              final String? newDesc =
                                  descCtrl.text.trim().isNotEmpty
                                  ? descCtrl.text.trim()
                                  : tire.description;

                              final updatedTire = tire.copyWith(
                                stock: stock,
                                price: newPrice,
                                originalPrice: newOrigPrice,
                                width: newWidth,
                                aspectRatio: newAspect,
                                rimSize: newRim,
                                speedRating: newSpeed,
                                loadIndex: newLoad,
                                category: newCategory,
                                season: newSeason,
                                description: newDesc,
                              );

                              Navigator.of(ctx).pop();
                              await homeCtrl.updateTire(updatedTire);

                              Get.snackbar(
                                'Inventory Updated',
                                '${updatedTire.fullName} updated ($stock in stock)',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppTheme.surfaceElevated,
                                colorText: AppTheme.textPrimary,
                                icon: const Icon(
                                  LucideIcons.checkCheck,
                                  color: AppTheme.accentOrange,
                                ),
                              );
                            },
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCircleStepperButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isEnabled
              ? AppTheme.accentOrange.withValues(alpha: 0.15)
              : AppTheme.inputBg,
          shape: BoxShape.circle,
          border: Border.all(
            color: isEnabled ? AppTheme.accentOrange : AppTheme.borderDark,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? AppTheme.accentOrange : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildQuickStockChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDialogInput({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.inputBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderDark),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12.5),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 9),
            ),
          ),
        ),
      ],
    );
  }
}
