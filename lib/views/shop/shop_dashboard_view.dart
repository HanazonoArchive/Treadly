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
import '../../core/toast.dart';

class ShopDashboardView extends StatefulWidget {
  const ShopDashboardView({super.key});

  @override
  State<ShopDashboardView> createState() => _ShopDashboardViewState();
}

class _ShopDashboardViewState extends State<ShopDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedInquiryFilter = 'All';
  String _orderQuery = '';
  String _inventoryQuery = '';
  String _inventoryFilter = 'All';
  final TextEditingController _orderSearchCtrl = TextEditingController();
  final TextEditingController _inventorySearchCtrl = TextEditingController();
  String _analyticsTimeframe = 'All Time';
  String _topTiresSortBy = 'units';

  static const List<String> _inquiryFilters = [
    'All',
    'Unpaid',
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
    _orderSearchCtrl.dispose();
    _inventorySearchCtrl.dispose();
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

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildShopHeader(BuildContext context, InquiryController inquiryCtrl) {
    final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: const BoxDecoration(
        color: AppTheme.headerDark,
        border: Border(bottom: BorderSide(color: AppTheme.borderDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Treadly Desk',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (auth != null)
                  Obx(
                    () => Text(
                      'Signed in as ${auth.displayName.value}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Staff settings',
            icon: const Icon(LucideIcons.settings, color: AppTheme.textPrimary, size: 20),
            onPressed: () => _showStaffSettingsDialog(context),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(LucideIcons.logOut, color: AppTheme.textPrimary, size: 20),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------------

  ButtonStyle get _primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      );

  ButtonStyle get _secondaryButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        side: const BorderSide(color: AppTheme.borderDark),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );

  ButtonStyle get _dangerTextButtonStyle => TextButton.styleFrom(
        foregroundColor: AppTheme.statusCancelled,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          filled: true,
          fillColor: AppTheme.surfaceDark,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }

  /// Filter chip with a count. The selected chip is the only orange one.
  Widget _buildCountChip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accentOrange : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppTheme.accentOrange : AppTheme.borderDark),
          ),
          child: Text(
            '$label  $count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChipRow(List<Widget> chips) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
        children: chips,
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppTheme.accentOrange),
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String asset) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        color: AppTheme.inputBg,
        padding: const EdgeInsets.all(3),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.album_rounded, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Back', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              action,
              style: TextStyle(
                color: destructive ? AppTheme.statusCancelled : AppTheme.accentOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to open the Treadly Desk.',
      action: 'Sign out',
    );
    if (ok && Get.isRegistered<AuthController>()) {
      await Get.find<AuthController>().signOut();
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.month}/${time.day}/${time.year}';
  }

  // ---------------------------------------------------------------------------
  // Orders tab
  // ---------------------------------------------------------------------------

  bool _matchesStatusFilter(TireInquiry inq, String filter) {
    if (filter == 'Unpaid') return inq.status == InquiryStatus.unpaid;
    if (filter == 'Placed') return inq.status == InquiryStatus.submitted;
    if (filter == 'Confirmed') return inq.status == InquiryStatus.responded;
    if (filter == 'Installed') return inq.status == InquiryStatus.completed;
    return true;
  }

  bool _matchesOrderSearch(TireInquiry inq) {
    final q = _orderQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    return inq.orderId.toLowerCase().contains(q) ||
        inq.customerName.toLowerCase().contains(q) ||
        '${inq.tireBrand} ${inq.tireModel} ${inq.tireSize}'.toLowerCase().contains(q);
  }

  Color _statusColor(InquiryStatus status) {
    if (status == InquiryStatus.unpaid) return const Color(0xFFD97706);
    if (status == InquiryStatus.submitted) return const Color(0xFF2563EB);
    if (status == InquiryStatus.responded) return const Color(0xFF7C3AED);
    if (status == InquiryStatus.completed) return const Color(0xFF059669);
    return AppTheme.statusCancelled;
  }

  Widget _buildLiveInquiriesTab(
    BuildContext context,
    InquiryController inquiryCtrl,
  ) {
    return Obx(() {
      final all = inquiryCtrl.staffInquiries.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final visible = all
          .where((inq) => _matchesStatusFilter(inq, _selectedInquiryFilter) && _matchesOrderSearch(inq))
          .toList();

      Widget body;
      if (all.isEmpty) {
        body = _buildEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No orders yet',
          message: 'New orders from customers will show up here.',
        );
      } else if (visible.isEmpty && _orderQuery.trim().isNotEmpty) {
        body = _buildEmptyState(
          icon: Icons.search_off,
          title: 'No orders match "${_orderQuery.trim()}"',
          message: 'Try an order number, a customer name or a tire.',
          actionLabel: 'Clear search',
          onAction: () => setState(() {
            _orderSearchCtrl.clear();
            _orderQuery = '';
          }),
        );
      } else if (visible.isEmpty) {
        body = _buildEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No ${_selectedInquiryFilter.toLowerCase()} orders',
          message: 'Orders move between these lists as their status changes.',
          actionLabel: 'Show all orders',
          onAction: () => setState(() => _selectedInquiryFilter = 'All'),
        );
      } else {
        body = ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: visible.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _buildShopInquiryCard(context, visible[index], inquiryCtrl),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchField(
            controller: _orderSearchCtrl,
            hint: 'Search order #, customer or tire',
            onChanged: (value) => setState(() => _orderQuery = value),
          ),
          _buildChipRow([
            for (final filter in _inquiryFilters)
              _buildCountChip(
                label: filter,
                count: all.where((inq) => _matchesStatusFilter(inq, filter)).length,
                selected: _selectedInquiryFilter == filter,
                onTap: () => setState(() => _selectedInquiryFilter = filter),
              ),
          ]),
          Expanded(child: body),
        ],
      );
    });
  }

  Widget _buildShopInquiryCard(
    BuildContext context,
    TireInquiry inq,
    InquiryController controller,
  ) {
    final tireCount = inq.totalTiresCount;
    final quantityText = inq.isSetOfFour
        ? 'Set of 4 ($tireCount tires)'
        : '$tireCount tire${tireCount == 1 ? '' : 's'}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${inq.orderId}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _timeAgo(inq.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
              _buildStatusPill(inq.status.label, _statusColor(inq.status)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 15, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  inq.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildThumbnail(inq.tireImage),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${inq.tireBrand} ${inq.tireModel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${inq.tireSize} · $quantityText',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                inq.formattedTotalPrice,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          if (inq.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.inputBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Note: ${inq.notes}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildShopActionRow(context, inq, controller),
        ],
      ),
    );
  }

  /// One clear main action per status; destructive actions ask first.
  Widget _buildShopActionRow(
    BuildContext context,
    TireInquiry inq,
    InquiryController controller,
  ) {
    final unread = inq.unreadCountForStaff;
    final chatButton = OutlinedButton(
      style: _secondaryButtonStyle,
      onPressed: () => Get.to(() => InquiryChatView(inquiryId: inq.id)),
      child: Text(unread > 0 ? 'Chat ($unread new)' : 'Chat'),
    );

    if (inq.status == InquiryStatus.unpaid) {
      return Row(
        children: [
          const Expanded(
            child: Text(
              'Waiting for payment',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            style: _dangerTextButtonStyle,
            onPressed: () => _cancelOrder(context, inq, controller, declined: false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 4),
          chatButton,
        ],
      );
    }

    if (inq.status == InquiryStatus.submitted) {
      return Row(
        children: [
          TextButton(
            style: _dangerTextButtonStyle,
            onPressed: () => _cancelOrder(context, inq, controller, declined: true),
            child: const Text('Decline'),
          ),
          const Spacer(),
          chatButton,
          const SizedBox(width: 8),
          ElevatedButton(
            style: _primaryButtonStyle,
            onPressed: () {
              controller.updateInquiryStatus(inq.id, InquiryStatus.responded);
              showToast('#${inq.orderId} confirmed');
            },
            child: const Text('Confirm'),
          ),
        ],
      );
    }

    if (inq.status == InquiryStatus.responded) {
      return Row(
        children: [
          const Expanded(
            child: Text(
              'In the bay',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          chatButton,
          const SizedBox(width: 8),
          ElevatedButton(
            style: _primaryButtonStyle,
            onPressed: () => _markInstalled(context, inq, controller),
            child: const Text('Mark Installed'),
          ),
        ],
      );
    }

    if (inq.status == InquiryStatus.completed) {
      return Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF059669)),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Installed',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.textPrimary),
            onPressed: () => Get.to(() => InquiryChatView(inquiryId: inq.id)),
            child: const Text('View chat'),
          ),
        ],
      );
    }

    return const Text(
      'Cancelled',
      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
    );
  }

  Future<void> _cancelOrder(
    BuildContext context,
    TireInquiry inq,
    InquiryController controller, {
    required bool declined,
  }) async {
    final ok = await _confirm(
      context,
      title: declined ? 'Decline this order?' : 'Cancel this order?',
      message: declined
          ? '#${inq.orderId} will be cancelled. The customer will see it as Cancelled.'
          : '#${inq.orderId} has not been paid yet. Cancelling removes it from the list.',
      action: declined ? 'Decline' : 'Cancel order',
      destructive: true,
    );
    if (!ok) return;
    await controller.updateInquiryStatus(inq.id, InquiryStatus.cancelled);
    showToast('#${inq.orderId} ${declined ? 'declined' : 'cancelled'}');
  }

  Future<void> _markInstalled(
    BuildContext context,
    TireInquiry inq,
    InquiryController controller,
  ) async {
    final ok = await _confirm(
      context,
      title: 'Mark as installed?',
      message: 'Do this after the tires for #${inq.orderId} are fitted. Installed orders cannot be cancelled.',
      action: 'Mark installed',
    );
    if (!ok) return;
    await controller.updateInquiryStatus(inq.id, InquiryStatus.completed);
    showToast('#${inq.orderId} marked as installed');
  }

  // ---------------------------------------------------------------------------
  // Inventory tab
  // ---------------------------------------------------------------------------

  /// Fewer than this many left is "low": not enough for a Set of 4.
  static const int _lowStockThreshold = 4;

  bool _isLowStock(Tire tire) => tire.stock > 0 && tire.stock < _lowStockThreshold;

  Widget _buildQuickInventoryTab(BuildContext context) {
    final homeCtrl = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController(), permanent: true);

    return Obx(() {
      final tires = homeCtrl.tires.toList();

      if (tires.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.accentOrange),
        );
      }

      final lowCount = tires.where(_isLowStock).length;
      final outCount = tires.where((tire) => tire.isOutOfStock).length;
      final q = _inventoryQuery.trim().toLowerCase();
      final visible = tires.where((tire) {
        if (_inventoryFilter == 'Low stock' && !_isLowStock(tire)) return false;
        if (_inventoryFilter == 'Out of stock' && !tire.isOutOfStock) return false;
        if (q.isEmpty) return true;
        return tire.fullName.toLowerCase().contains(q) || tire.size.toLowerCase().contains(q);
      }).toList();

      Widget body;
      if (visible.isEmpty && q.isNotEmpty) {
        body = _buildEmptyState(
          icon: Icons.search_off,
          title: 'No tires match "${_inventoryQuery.trim()}"',
          message: 'Try a brand, a model or a size like 225/45 R18.',
          actionLabel: 'Clear search',
          onAction: () => setState(() {
            _inventorySearchCtrl.clear();
            _inventoryQuery = '';
          }),
        );
      } else if (visible.isEmpty) {
        body = _buildEmptyState(
          icon: Icons.inventory_2_outlined,
          title: _inventoryFilter == 'Low stock' ? 'Nothing is running low' : 'Nothing is out of stock',
          message: 'Tires with fewer than $_lowStockThreshold left are listed under Low stock.',
          actionLabel: 'Show all tires',
          onAction: () => setState(() => _inventoryFilter = 'All'),
        );
      } else {
        body = ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: visible.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _buildInventoryTile(context, visible[index], homeCtrl),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchField(
            controller: _inventorySearchCtrl,
            hint: 'Search brand, model or size',
            onChanged: (value) => setState(() => _inventoryQuery = value),
          ),
          _buildChipRow([
            _buildCountChip(
              label: 'All',
              count: tires.length,
              selected: _inventoryFilter == 'All',
              onTap: () => setState(() => _inventoryFilter = 'All'),
            ),
            _buildCountChip(
              label: 'Low stock',
              count: lowCount,
              selected: _inventoryFilter == 'Low stock',
              onTap: () => setState(() => _inventoryFilter = 'Low stock'),
            ),
            _buildCountChip(
              label: 'Out of stock',
              count: outCount,
              selected: _inventoryFilter == 'Out of stock',
              onTap: () => setState(() => _inventoryFilter = 'Out of stock'),
            ),
          ]),
          Expanded(child: body),
        ],
      );
    });
  }

  Widget _buildInventoryTile(BuildContext context, Tire tire, HomeController homeCtrl) {
    Widget stockLabel;
    if (tire.isOutOfStock) {
      stockLabel = _buildStatusPill('Out of stock', AppTheme.statusCancelled);
    } else if (_isLowStock(tire)) {
      stockLabel = _buildStatusPill('${tire.stock} left', const Color(0xFFD97706));
    } else {
      stockLabel = Text(
        '${tire.stock} in stock',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
      );
    }

    return InkWell(
      onTap: () => _showEditTireDialog(context, tire, homeCtrl),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Row(
          children: [
            _buildThumbnail(tire.imageAsset),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tire.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tire.size} · ${tire.formattedPrice}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            stockLabel,
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
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
        final hasMixData = timeframeInqs.isNotEmpty;
        final setOfFourPct = hasMixData
            ? (timeframeInqs.where((i) => i.isSetOfFour).length *
                      100 /
                      timeframeInqs.length)
                  .round()
            : 0;
        final singlePct = hasMixData ? 100 - setOfFourPct : 0;

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
                    'From installed orders',
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
                    label: 'Installed Orders',
                    value: '$timeframeCompleted',
                    color: AppTheme.textPrimary,
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
                    label: 'Open Orders',
                    value: '${inquiryCtrl.openOrdersCount}',
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSimpleMetricCard(
                    label: 'Avg. Order Ticket',
                    value: '₱${_formatAmount(timeframeAov)}',
                    color: AppTheme.textPrimary,
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
                          color: AppTheme.textPrimary,
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
                        const Color(0xFF2563EB),
                      ),
                      _buildPipelineStageItem(
                        'Confirmed',
                        timeframeInqs
                            .where((i) => i.status == InquiryStatus.responded)
                            .length,
                        const Color(0xFF7C3AED),
                      ),
                      _buildPipelineStageItem(
                        'Installed',
                        timeframeInqs
                            .where((i) => i.status == InquiryStatus.completed)
                            .length,
                        const Color(0xFF059669),
                      ),
                      _buildPipelineStageItem(
                        'Cancelled',
                        inquiryCtrl.getTimeframeCancelledCount(_analyticsTimeframe),
                        AppTheme.statusCancelled,
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
                      child: !hasMixData
                          ? Container(color: const Color(0xFFE2E8F0))
                          : Row(
                            children: [
                              Expanded(
                                flex: setOfFourPct,
                                child: Container(color: AppTheme.accentOrange),
                              ),
                              Expanded(
                                flex: singlePct,
                                child: Container(color: const Color(0xFFCBD5E1)),
                              ),
                            ],
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!hasMixData)
                    const Text(
                      'No orders in this period',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    )
                  else
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
                                color: Color(0xFFCBD5E1),
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
                    showToast('CSV copied to clipboard');
                  },
                ),
                const Divider(color: AppTheme.borderDark, height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    LucideIcons.fileText,
                    color: AppTheme.textSecondary,
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
                    showToast('Summary copied to clipboard');
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
                  label: 'Orders',
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
                          showToast('Staff name updated to "$newName"');
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

                              showToast('${updatedTire.fullName} updated ($stock in stock)');
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
