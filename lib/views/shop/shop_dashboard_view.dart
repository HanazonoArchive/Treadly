import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/home/home_controller.dart';
import '../../controllers/inquiry/inquiry_controller.dart';
import '../../core/app_theme.dart';
import '../../models/inquiry.dart';
import '../../models/shop_branch.dart';
import '../../models/tire.dart';
import '../inquiry_chat_view.dart';

/// Shop Admin Dashboard View (The 2nd Portal in our 1-App Architecture)
/// Gives shop staff and store managers real-time inquiry management,
/// one-tap reservation response, and quick branch stock controls.
class ShopDashboardView extends StatefulWidget {
  const ShopDashboardView({super.key});

  @override
  State<ShopDashboardView> createState() => _ShopDashboardViewState();
}

class _ShopDashboardViewState extends State<ShopDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedInquiryFilter = 'All';

  static const List<String> _inquiryFilters = [
    'All',
    'Inquiries',
    'Responded',
    'Completed',
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
            // Top Shop Header Bar
            _buildShopHeader(context, inquiryCtrl),

            // Tab Views (Full Height)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLiveInquiriesTab(context, inquiryCtrl),
                  _buildQuickInventoryTab(context),
                  _buildBranchInfoTab(context, inquiryCtrl),
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
        border: Border(bottom: BorderSide(color: AppTheme.borderDark, width: 1.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Treadly Desk',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),

              // Sign Out Button (consistent with user profile logout: no bg, no border, white icon)
              IconButton(
                tooltip: 'Sign Out',
                icon: const Icon(
                  LucideIcons.logOut,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  if (Get.isRegistered<AuthController>()) {
                    Get.find<AuthController>().signOut();
                  }
                },
              ),

              // Staff Settings Button (on the right side of the logout button)
              IconButton(
                tooltip: 'Staff Settings',
                icon: const Icon(
                  LucideIcons.settings,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => _showStaffSettingsDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metric Counters Row (Interactive filter shortcuts)
          Obx(
            () => Row(
              children: [
                _buildMetricBox(
                  'Submitted',
                  '${inquiryCtrl.submittedCount}',
                  AppTheme.accentOrange,
                  isSelected: _selectedInquiryFilter == 'Inquiries',
                  onTap: () {
                    setState(() {
                      _selectedInquiryFilter = _selectedInquiryFilter == 'Inquiries' ? 'All' : 'Inquiries';
                    });
                    if (_tabController.index != 0) _tabController.animateTo(0);
                  },
                ),
                const SizedBox(width: 8),
                _buildMetricBox(
                  'Responded',
                  '${inquiryCtrl.respondedCount}',
                  AppTheme.statusResponded,
                  isSelected: _selectedInquiryFilter == 'Responded',
                  onTap: () {
                    setState(() {
                      _selectedInquiryFilter = _selectedInquiryFilter == 'Responded' ? 'All' : 'Responded';
                    });
                    if (_tabController.index != 0) _tabController.animateTo(0);
                  },
                ),
                const SizedBox(width: 8),
                _buildMetricBox(
                  'Completed',
                  '${inquiryCtrl.completedCount}',
                  AppTheme.statusCompleted,
                  isSelected: _selectedInquiryFilter == 'Completed',
                  onTap: () {
                    setState(() {
                      _selectedInquiryFilter = _selectedInquiryFilter == 'Completed' ? 'All' : 'Completed';
                    });
                    if (_tabController.index != 0) _tabController.animateTo(0);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(
    String label,
    String value,
    Color color, {
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppTheme.borderDark,
              width: isSelected ? 1.5 : 1.0,
            ),
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
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF8E9BAE),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: LIVE INQUIRIES FEED (SHOP STAFF REAL-TIME ACTIONS)
  // ===========================================================================

  Widget _buildLiveInquiriesTab(BuildContext context, InquiryController inquiryCtrl) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Filter Chips for All, Inquiries, Responded, Completed
        _buildInquiryFilterChips(inquiryCtrl),
        const SizedBox(height: 4),

        Expanded(
          child: Obx(() {
            final allList = inquiryCtrl.staffInquiries;

            if (allList.isEmpty) {
              return const Center(
                child: Text('No inquiries in the shop inbox yet', style: TextStyle(color: AppTheme.textSecondary)),
              );
            }

            // Apply filter
            final filteredList = allList.where((inq) {
              if (_selectedInquiryFilter == 'Inquiries') {
                return inq.status == InquiryStatus.submitted;
              } else if (_selectedInquiryFilter == 'Responded') {
                return inq.status == InquiryStatus.responded;
              } else if (_selectedInquiryFilter == 'Completed') {
                return inq.status == InquiryStatus.completed;
              }
              return true; // 'All'
            }).toList();

            if (filteredList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.filterX, size: 36, color: Color(0xFF64748B)),
                      const SizedBox(height: 12),
                      Text(
                        'No $_selectedInquiryFilter inquiries found',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select "All" to view all active customer conversations.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
                        label: const Text('Reset Filter to All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
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
    return Obx(() {
      final staffInqs = inquiryCtrl.staffInquiries;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _inquiryFilters.map((filter) {
            final isSelected = _selectedInquiryFilter == filter;
            int count = 0;
            Color filterAccentColor = AppTheme.accentOrange;

            switch (filter) {
              case 'All':
                count = staffInqs.length;
                filterAccentColor = AppTheme.accentOrange;
                break;
              case 'Inquiries':
                count = staffInqs.where((i) => i.status == InquiryStatus.submitted).length;
                filterAccentColor = AppTheme.accentOrange;
                break;
              case 'Responded':
                count = staffInqs.where((i) => i.status == InquiryStatus.responded).length;
                filterAccentColor = AppTheme.statusResponded;
                break;
              case 'Completed':
                count = staffInqs.where((i) => i.status == InquiryStatus.completed).length;
                filterAccentColor = AppTheme.statusCompleted;
                break;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedInquiryFilter = filter;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? filterAccentColor.withValues(alpha: 0.18)
                        : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? filterAccentColor : AppTheme.borderDark,
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected ? filterAccentColor : AppTheme.inputBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected ? Colors.black : const Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildShopInquiryCard(
    BuildContext context,
    TireInquiry inq,
    InquiryController controller,
  ) {
    Color statusColor;
    String statusLabel;

    switch (inq.status) {
      case InquiryStatus.submitted:
        statusColor = AppTheme.statusSubmitted;
        statusLabel = 'Submitted';
        break;
      case InquiryStatus.responded:
        statusColor = AppTheme.statusResponded;
        statusLabel = 'Responded';
        break;
      case InquiryStatus.completed:
        statusColor = AppTheme.statusCompleted;
        statusLabel = 'Completed';
        break;
      case InquiryStatus.cancelled:
        statusColor = AppTheme.statusCancelled;
        statusLabel = 'Cancelled';
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
          // Header: ID + Time + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.user, size: 14, color: AppTheme.accentOrange),
                  const SizedBox(width: 6),
                  Text(
                    inq.customerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tire & Order Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.white.withValues(alpha: 0.04),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${inq.tireSize} • ${inq.isSetOfFour ? 'Set of 4' : '${inq.quantity} Tire(s)'}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    Text(
                      'Vehicle: ${inq.vehicleModel} • Visit: ${inq.preferredDate}',
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
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
                color: Colors.white.withValues(alpha: 0.03),
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

          // Shop Action Buttons based on current inquiry status
          _buildShopActionRow(inq, controller),
        ],
      ),
    );
  }

  Widget _buildShopActionRow(TireInquiry inq, InquiryController controller) {
    if (inq.status == InquiryStatus.submitted) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                controller.updateInquiryStatus(inq.id, InquiryStatus.cancelled);
                Get.snackbar(
                  'Inquiry Declined',
                  'Inquiry #${inq.id} marked as unavailable.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppTheme.surfaceElevated,
                  colorText: AppTheme.statusCancelled,
                );
              },
              child: const Text('Decline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                Get.to(() => InquiryChatView(inquiryId: inq.id));
              },
              child: const Text('Reply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(LucideIcons.messageSquare, size: 15),
              label: Text(
                inq.messages.isEmpty ? 'Chat' : 'Chat (${inq.messages.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              onPressed: () {
                Get.to(() => InquiryChatView(inquiryId: inq.id));
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusCompleted,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('Complete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () {
                controller.updateInquiryStatus(inq.id, InquiryStatus.completed);
                Get.snackbar(
                  'Inquiry Completed',
                  'Inquiry #${inq.id} marked as completed!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppTheme.surfaceElevated,
                  colorText: AppTheme.statusCompleted,
                );
              },
            ),
          ),
        ],
      );
    } else if (inq.status == InquiryStatus.completed) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 15),
                SizedBox(width: 6),
                Text(
                  'Completed',
                  style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(LucideIcons.messageSquare, size: 13, color: AppTheme.accentOrange),
              label: const Text(
                'View Chat',
                style: TextStyle(color: AppTheme.accentOrange, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Get.to(() => InquiryChatView(inquiryId: inq.id));
              },
            ),
          ],
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Archived (${inq.status.label})',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      );
    }
  }

  // ===========================================================================
  // TAB 2: QUICK INVENTORY ADJUSTMENT FOR SHOP DESK
  // ===========================================================================

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
                      color: Colors.white.withValues(alpha: 0.03),
                      child: Image.asset(
                        tire.imageAsset,
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
                          tire.fullName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${tire.size} • ${tire.formattedPrice}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Plain text and color for stock quantity (no border, no background)
                  Text(
                    tire.isOutOfStock ? 'OUT OF STOCK' : '${tire.stock} IN STOCK',
                    style: TextStyle(
                      color: tire.isOutOfStock ? const Color(0xFFEF4444) : const Color(0xFF10B981),
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

  // ===========================================================================
  // TAB 3: BRANCH DETAILS (FULL CRUD)
  // ===========================================================================

  Widget _buildBranchInfoTab(BuildContext context, InquiryController inquiryCtrl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Obx(() {
        final branches = inquiryCtrl.branches;
        final current = inquiryCtrl.activeBranch.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Row with Add Branch action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shop Locations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${branches.length} ${branches.length == 1 ? 'branch' : 'branches'} configured',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _showBranchDialog(context, inquiryCtrl),
                  icon: const Icon(LucideIcons.plus, size: 15),
                  label: const Text(
                    'Add Branch',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...branches.map((b) {
              final isCurrent = b.id == current.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrent ? AppTheme.accentOrange : AppTheme.borderDark,
                    width: isCurrent ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  b.name,
                                  style: TextStyle(
                                    color: isCurrent ? AppTheme.accentOrange : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (b.isMainBranch) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentOrange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Flagship',
                                    style: TextStyle(
                                      color: AppTheme.accentOrange,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.accentOrange, width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppTheme.accentOrange, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'ACTIVE DESK',
                                  style: TextStyle(
                                    color: AppTheme.accentOrange,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          InkWell(
                            onTap: () => inquiryCtrl.setActiveBranch(b),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.borderDark),
                              ),
                              child: const Text(
                                'Set as Active',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${b.address}, ${b.city}',
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phone: ${b.phone} • Hours: ${b.operatingHours}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    if (b.availableServices.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: b.availableServices.take(3).map((service) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.inputBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.borderDark),
                            ),
                            child: Text(
                              service,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF1E293B), height: 1),
                    const SizedBox(height: 10),
                    // Action Buttons: Switch Desk / Edit / Delete
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isCurrent)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.accentOrange,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => inquiryCtrl.setActiveBranch(b),
                            icon: const Icon(LucideIcons.check, size: 14),
                            label: const Text('Use Branch', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        const Spacer(),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFCBD5E1),
                            side: const BorderSide(color: AppTheme.borderDark),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _showBranchDialog(context, inquiryCtrl, branchToEdit: b),
                          icon: const Icon(LucideIcons.pencil, size: 12.5),
                          label: const Text('Edit', style: TextStyle(fontSize: 11.5)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _confirmDeleteBranch(context, inquiryCtrl, b),
                          icon: const Icon(LucideIcons.trash2, size: 12.5),
                          label: const Text('Delete', style: TextStyle(fontSize: 11.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  Widget _buildBottomNavigationBar(InquiryController inquiryCtrl) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.headerDark,
        border: Border(
          top: BorderSide(color: AppTheme.borderDark, width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Obx(() => _buildBottomNavItem(
                    index: 0,
                    icon: LucideIcons.inbox,
                    label: 'Live Inquiries',
                    badgeCount: inquiryCtrl.unreadCustomerMessagesCount,
                  )),
              _buildBottomNavItem(
                index: 1,
                icon: LucideIcons.package,
                label: 'Shop Inventory',
              ),
              _buildBottomNavItem(
                index: 2,
                icon: LucideIcons.store,
                label: 'Branch Info',
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentOrange.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? AppTheme.accentOrange : const Color(0xFF8E9BAE),
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.headerDark, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.black,
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
                color: isSelected ? AppTheme.accentOrange : const Color(0xFF8E9BAE),
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
    final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
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
                // Header
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
                              color: Colors.white,
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
                      icon: const Icon(LucideIcons.x, color: Color(0xFF94A3B8), size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Display Name Field
                const Text(
                  'Display Name',
                  style: TextStyle(
                    color: Colors.white,
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
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: const InputDecoration(
                      icon: Icon(LucideIcons.user, size: 16, color: Color(0xFF64748B)),
                      hintText: 'Enter your name (e.g. Mark Santos)',
                      hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'This name appears on chat messages sent to customers.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons: Cancel + Save
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
                          foregroundColor: Colors.black,
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
                            colorText: Colors.white,
                            icon: const Icon(LucideIcons.checkCheck, color: AppTheme.accentOrange),
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

  // ===========================================================================
  // TIRE INVENTORY & SPECIFICATIONS EDIT DIALOG
  // ===========================================================================

  void _showEditTireDialog(BuildContext context, Tire tire, HomeController homeCtrl) {
    int stock = tire.stock;
    final priceCtrl = TextEditingController(text: tire.priceInPhp.toInt().toString());
    final origPriceCtrl = TextEditingController(
      text: tire.originalPriceInPhp != null ? tire.originalPriceInPhp!.toInt().toString() : '',
    );
    final widthCtrl = TextEditingController(text: tire.width.toString());
    final aspectCtrl = TextEditingController(text: tire.aspectRatio.toString());
    final rimCtrl = TextEditingController(text: tire.rimSize.toString());
    final speedCtrl = TextEditingController(text: tire.speedRating ?? '');
    final loadCtrl = TextEditingController(text: tire.loadIndex?.toString() ?? '');
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
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                  // Dialog Header
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 44,
                            height: 44,
                            color: Colors.white.withValues(alpha: 0.05),
                            child: Image.asset(
                              tire.imageAsset,
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
                                tire.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
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
                          icon: const Icon(LucideIcons.x, color: Color(0xFF94A3B8), size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF1E293B), height: 1),

                  // Scrollable Form Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Stock Adjustment Box
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      isOut ? 'OUT OF STOCK' : '$stock IN STOCK',
                                      style: TextStyle(
                                        color: isOut ? const Color(0xFFEF4444) : const Color(0xFF10B981),
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
                                          ? () => setModalState(() => stock = (stock - 1).clamp(0, 99999))
                                          : null,
                                    ),
                                    const SizedBox(width: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.inputBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppTheme.borderDark),
                                      ),
                                      child: Text(
                                        '$stock',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    _buildCircleStepperButton(
                                      icon: LucideIcons.plus,
                                      onPressed: () => setModalState(() => stock++),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Quick stock presets
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildQuickStockChip(
                                      label: 'Zero (0)',
                                      color: const Color(0xFFEF4444),
                                      onTap: () => setModalState(() => stock = 0),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQuickStockChip(
                                      label: '+4 Set',
                                      color: AppTheme.accentOrange,
                                      onTap: () => setModalState(() => stock += 4),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQuickStockChip(
                                      label: '+8 Set',
                                      color: AppTheme.accentOrange,
                                      onTap: () => setModalState(() => stock += 8),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQuickStockChip(
                                      label: '+20 Bulk',
                                      color: const Color(0xFF10B981),
                                      onTap: () => setModalState(() => stock += 20),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Pricing Fields
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

                          // 3. Size Specifications
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

                          // 4. Description Field
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

                  // Bottom Action Buttons
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentOrange,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final double newPrice = double.tryParse(priceCtrl.text.replaceAll(',', '').trim()) ?? tire.price;
                              final double? newOrigPrice = origPriceCtrl.text.trim().isNotEmpty
                                  ? double.tryParse(origPriceCtrl.text.replaceAll(',', '').trim())
                                  : null;
                              final int newWidth = int.tryParse(widthCtrl.text.trim()) ?? tire.width;
                              final int newAspect = int.tryParse(aspectCtrl.text.trim()) ?? tire.aspectRatio;
                              final int newRim = int.tryParse(rimCtrl.text.trim()) ?? tire.rimSize;
                              final String? newSpeed = speedCtrl.text.trim().isNotEmpty ? speedCtrl.text.trim() : tire.speedRating;
                              final int? newLoad = int.tryParse(loadCtrl.text.trim()) ?? tire.loadIndex;
                              final String newCategory = categoryCtrl.text.trim().isNotEmpty ? categoryCtrl.text.trim() : tire.category;
                              final String newSeason = seasonCtrl.text.trim().isNotEmpty ? seasonCtrl.text.trim() : tire.season;
                              final String? newDesc = descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : tire.description;

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
                                colorText: Colors.white,
                                icon: const Icon(LucideIcons.checkCheck, color: AppTheme.accentOrange),
                              );
                            },
                            child: const Text('Save Changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
          color: isEnabled ? AppTheme.accentOrange.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
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
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
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
            color: Color(0xFFCBD5E1),
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
            style: const TextStyle(color: Colors.white, fontSize: 12.5),
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

  // ===========================================================================
  // BRANCH CRUD DIALOGS
  // ===========================================================================

  void _showBranchDialog(BuildContext context, InquiryController inquiryCtrl, {ShopBranch? branchToEdit}) {
    final isEditing = branchToEdit != null;
    final nameCtrl = TextEditingController(text: branchToEdit?.name ?? '');
    final addressCtrl = TextEditingController(text: branchToEdit?.address ?? '');
    final cityCtrl = TextEditingController(text: branchToEdit?.city ?? '');
    final phoneCtrl = TextEditingController(text: branchToEdit?.phone ?? '');
    final hoursCtrl = TextEditingController(text: branchToEdit?.operatingHours ?? 'Mon - Sat: 8:00 AM - 6:00 PM');
    final distanceCtrl = TextEditingController(text: branchToEdit?.distanceText ?? 'Nearby');
    final servicesCtrl = TextEditingController(
      text: branchToEdit?.availableServices.join(', ') ?? 'Tire Mounting, Wheel Alignment, High-Speed Balancing',
    );
    bool isMain = branchToEdit?.isMainBranch ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              width: 500,
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
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.store, color: AppTheme.accentOrange, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'Edit Shop Location' : 'Add Shop Location',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEditing ? 'Update branch address and desk information' : 'Register a new active shop branch',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, color: Color(0xFF94A3B8), size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF1E293B), height: 1),

                  // Form Fields
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDialogInput(
                            label: 'Branch Name',
                            controller: nameCtrl,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogInput(
                            label: 'Street Address',
                            controller: addressCtrl,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogInput(
                                  label: 'City',
                                  controller: cityCtrl,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDialogInput(
                                  label: 'Distance Text',
                                  controller: distanceCtrl,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDialogInput(
                            label: 'Phone Contact',
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogInput(
                            label: 'Operating Hours',
                            controller: hoursCtrl,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogInput(
                            label: 'Available Services (comma-separated)',
                            controller: servicesCtrl,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          // Flagship Toggle
                          InkWell(
                            onTap: () => setModalState(() => isMain = !isMain),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.inputBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderDark),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isMain ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                    color: isMain ? AppTheme.accentOrange : const Color(0xFF64748B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Main Flagship Hub',
                                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Mark this branch as the primary Treadly hub',
                                          style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actions
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentOrange,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              final addr = addressCtrl.text.trim();
                              if (name.isEmpty || addr.isEmpty) {
                                Get.snackbar(
                                  'Missing Info',
                                  'Branch name and address cannot be empty',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppTheme.surfaceElevated,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              final services = servicesCtrl.text
                                  .split(',')
                                  .map((s) => s.trim())
                                  .where((s) => s.isNotEmpty)
                                  .toList();

                              Navigator.of(ctx).pop();

                              if (isEditing) {
                                final updated = branchToEdit.copyWith(
                                  name: name,
                                  address: addr,
                                  city: cityCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  operatingHours: hoursCtrl.text.trim(),
                                  distanceText: distanceCtrl.text.trim().isNotEmpty ? distanceCtrl.text.trim() : 'Nearby',
                                  availableServices: services,
                                  isMainBranch: isMain,
                                );
                                await inquiryCtrl.updateBranch(updated);
                                Get.snackbar(
                                  'Branch Updated',
                                  '${updated.name} has been updated.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppTheme.surfaceElevated,
                                  colorText: Colors.white,
                                  icon: const Icon(LucideIcons.checkCheck, color: AppTheme.accentOrange),
                                );
                              } else {
                                final newBranch = ShopBranch(
                                  id: 'branch-${DateTime.now().millisecondsSinceEpoch}',
                                  name: name,
                                  address: addr,
                                  city: cityCtrl.text.trim().isNotEmpty ? cityCtrl.text.trim() : 'Metro Manila',
                                  distanceText: distanceCtrl.text.trim().isNotEmpty ? distanceCtrl.text.trim() : 'Nearby',
                                  phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : '+63 (02) 8000-0000',
                                  operatingHours: hoursCtrl.text.trim().isNotEmpty ? hoursCtrl.text.trim() : 'Mon - Sat: 8:00 AM - 6:00 PM',
                                  availableServices: services.isNotEmpty
                                      ? services
                                      : const ['Tire Mounting', 'Wheel Alignment', 'High-Speed Balancing'],
                                  isMainBranch: isMain,
                                );
                                await inquiryCtrl.addBranch(newBranch);
                                Get.snackbar(
                                  'Branch Created',
                                  '${newBranch.name} added to Treadly.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppTheme.surfaceElevated,
                                  colorText: Colors.white,
                                  icon: const Icon(LucideIcons.checkCheck, color: AppTheme.accentOrange),
                                );
                              }
                            },
                            child: Text(
                              isEditing ? 'Save Changes' : 'Create Branch',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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

  void _confirmDeleteBranch(BuildContext context, InquiryController inquiryCtrl, ShopBranch branch) {
    if (inquiryCtrl.branches.length <= 1) {
      Get.snackbar(
        'Action Prohibited',
        'Cannot delete the only remaining shop branch. Treadly requires at least one active location.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceElevated,
        colorText: Colors.white,
        icon: const Icon(LucideIcons.alertTriangle, color: Color(0xFFEF4444)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Delete Branch?',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to remove "${branch.name}"? If this is the active desk, the active location will switch to another branch.',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await inquiryCtrl.deleteBranch(branch.id);
                        Get.snackbar(
                          'Branch Removed',
                          '${branch.name} has been deleted.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppTheme.surfaceElevated,
                          colorText: Colors.white,
                          icon: const Icon(LucideIcons.checkCheck, color: Color(0xFFEF4444)),
                        );
                      },
                      child: const Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
