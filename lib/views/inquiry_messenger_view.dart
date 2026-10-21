import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../controllers/auth_controller.dart';
import '../controllers/inquiry/inquiry_controller.dart';
import '../core/app_theme.dart';
import '../models/inquiry.dart';
import 'auth/sign_in_view.dart';
import 'inquiry_chat_view.dart';

/// Messenger View (Facebook Messenger style for Inquiries)
/// Displays active inquiry conversations with search and filters:
/// - Inquired
/// - Responded
/// - Completed
/// Cancelled inquiries automatically disappear to keep chats clean and organized.
class InquiryMessengerView extends StatefulWidget {
  const InquiryMessengerView({super.key});

  @override
  State<InquiryMessengerView> createState() => _InquiryMessengerViewState();
}

class _InquiryMessengerViewState extends State<InquiryMessengerView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  static const List<String> _filters = [
    'All',
    'Inquired',
    'Responded',
    'Completed',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

    final isStaff = _isCurrentStaff();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Messenger Top Bar Header: Back button + "Chats" title + Total count
            _buildMessengerHeader(context, inquiryCtrl, isStaff),

            // Search Bar (Messenger style)
            _buildSearchBar(),

            // Filter Chips Bar (All, Inquired, Responded, Completed) with Smart Unread Badges
            _buildFilterChips(inquiryCtrl, isStaff),

            const SizedBox(height: 6),

            // Conversations List (Messenger Threads)
            Expanded(
              child: Obx(() {
                final allInquiries = isStaff ? inquiryCtrl.staffInquiries : inquiryCtrl.customerInquiries;

                // Rule: Cancelled inquiries automatically disappear from conversations
                final activeInquiries = allInquiries.where((i) => i.status != InquiryStatus.cancelled).toList();

                // Apply status filter
                final filteredByStatus = activeInquiries.where((i) {
                  if (_selectedFilter == 'Inquired') {
                    return i.status == InquiryStatus.submitted;
                  }
                  if (_selectedFilter == 'Responded') {
                    return i.status == InquiryStatus.responded;
                  }
                  if (_selectedFilter == 'Completed') {
                    return i.status == InquiryStatus.completed;
                  }
                  return true; // 'All'
                }).toList();

                // Apply search filter (by inquiry ID, tire brand, tire model)
                final list = filteredByStatus.where((i) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  final idMatch = i.id.toLowerCase().contains(q);
                  final brandMatch = i.tireBrand.toLowerCase().contains(q);
                  final modelMatch = i.tireModel.toLowerCase().contains(q);
                  return idMatch || brandMatch || modelMatch;
                }).toList();

                if (list.isEmpty) {
                  return _buildEmptyMessengerState();
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: AppTheme.borderSubtle,
                    height: 1,
                    indent: 68,
                  ),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _buildConversationRow(context, item, isStaff);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessengerHeader(BuildContext context, InquiryController controller, bool isStaff) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 4),
          const Text(
            'Chats',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          // Unread summary pill (reactive)
          Obx(() {
            final unread = isStaff
                ? controller.unreadCustomerMessagesCount
                : controller.unreadResponsesCount;
            if (unread == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.5)),
              ),
              child: Text(
                '$unread new',
                style: const TextStyle(
                  color: AppTheme.accentOrange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.inputBg,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: AppTheme.borderDark),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(LucideIcons.search, size: 17, color: Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'Search chats or inquiry ID...',
                  hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: const Icon(LucideIcons.x, size: 16, color: Color(0xFF94A3B8)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(InquiryController inquiryCtrl, bool isStaff) {
    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            final unreadCount = inquiryCtrl.getCategoryUnreadCount(filter, isStaff: isStaff);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accentOrange : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppTheme.accentOrange : AppTheme.borderDark,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.black : const Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
    });
  }

  Widget _buildConversationRow(BuildContext context, TireInquiry item, bool isStaff) {
    final isDone = item.status == InquiryStatus.completed || item.status == InquiryStatus.cancelled;
    final unreadMsgs = isDone ? 0 : (isStaff ? item.unreadCountForStaff : item.unreadCountForCustomer);
    final isUnviewed = isDone ? false : (isStaff ? !item.isStaffViewed : !item.isCustomerViewed);
    final hasUnread = !isDone && (isStaff ? item.hasStaffUnread : item.hasCustomerUnread);
    final displayUnreadCount = isDone ? 0 : (unreadMsgs > 0 ? unreadMsgs : (isUnviewed ? 1 : 0));
    final latestMsg = item.latestMessage;

    // Status colors and labels
    Color statusColor;
    String statusLabel;
    switch (item.status) {
      case InquiryStatus.submitted:
        statusColor = AppTheme.statusSubmitted;
        statusLabel = 'Inquired';
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

    // Snippet preview
    String previewText;
    if (latestMsg != null) {
      String staffName = item.assignedStaffName?.isNotEmpty == true ? item.assignedStaffName! : '';
      if (staffName.isEmpty || staffName.toLowerCase() == 'staff') {
        if (Get.isRegistered<InquiryController>()) {
          final inqCtrl = Get.find<InquiryController>();
          if (inqCtrl.activeStaffDisplayName.value.isNotEmpty &&
              inqCtrl.activeStaffDisplayName.value.toLowerCase() != 'staff') {
            staffName = inqCtrl.activeStaffDisplayName.value;
          } else {
            staffName = 'jhon';
          }
        } else {
          staffName = 'jhon';
        }
      }
      final senderPrefix = latestMsg.isStaff
          ? (isStaff ? 'You: ' : '$staffName: ')
          : (isStaff ? '${item.customerName}: ' : 'You: ');
      final cleanSnippet = latestMsg.text.replaceAll('\n', ' ').trim();
      previewText = '$senderPrefix$cleanSnippet';
    } else {
      previewText = 'Inquiry submitted';
    }

    final formattedTime = latestMsg != null
        ? _formatMessengerTime(latestMsg.timestamp)
        : _formatMessengerTime(item.createdAt);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InquiryChatView(inquiryId: item.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            // Avatar with Status indicator dot (Messenger style)
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: AppTheme.surfaceElevated,
                    padding: const EdgeInsets.all(5),
                    child: Image.asset(
                      item.tireImage,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.album_rounded,
                        color: AppTheme.textSecondary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                // Active status indicator pip
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.bgDark, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Content: Inquiry ID as Conversation Name, Status pill, Tire info, and Message Snippet
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Inquiry ID as Main Conversation Name
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              item.id.startsWith('#') ? item.id : '#${item.id}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: hasUnread ? FontWeight.w900 : FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Status label pill (only for Responded or Completed; "Inquired" tag removed)
                            if (item.status != InquiryStatus.submitted) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: hasUnread ? AppTheme.accentOrange : const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Product tag line (subtle context)
                  Text(
                    '${item.tireBrand} ${item.tireModel} (${item.tireSize})',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          previewText,
                          style: TextStyle(
                            color: latestMsg == null
                                ? AppTheme.accentOrange
                                : (hasUnread ? Colors.white : const Color(0xFF8E9BAE)),
                            fontSize: 12.5,
                            fontWeight: (hasUnread || latestMsg == null)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                          decoration: const BoxDecoration(
                            color: AppTheme.accentOrange,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Center(
                            child: Text(
                              displayUnreadCount > 9 ? '9+' : '$displayUnreadCount',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMessengerState() {
    bool isGuest = false;
    if (Get.isRegistered<AuthController>()) {
      isGuest = Get.find<AuthController>().isGuest.value;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: const Icon(
                LucideIcons.messageSquare,
                size: 28,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isGuest ? 'Sign In to View Chats' : 'No Conversations',
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isGuest
                  ? 'Please sign in to view your inquiry messages and chat with shop staff.'
                  : 'When you submit an inquiry for a product, a dedicated conversation will automatically be created here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8E9BAE),
                fontSize: 12.5,
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

  String _formatMessengerTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
      final minute = time.minute.toString().padLeft(2, '0');
      final amPm = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $amPm';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[time.weekday - 1];
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
