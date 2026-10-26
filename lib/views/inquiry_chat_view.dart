import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../controllers/auth_controller.dart';
import '../controllers/inquiry/inquiry_controller.dart';
import '../core/app_theme.dart';
import '../models/inquiry.dart';
import 'inquiry_messenger_view.dart';

/// Inquiry Conversation / Chat View
/// Allows real-time customer and staff communication tied directly to an Inquiry ID.
/// Staff sending a message automatically advances the status from 'submitted' to 'responded'.
/// Staff can also mark the inquiry as completed or reopen it.
class InquiryChatView extends StatefulWidget {
  final String inquiryId;

  const InquiryChatView({
    super.key,
    required this.inquiryId,
  });

  /// Universal entry point for top bar message icon button -> opens Facebook Messenger-style Chats page
  static void openConversations(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const InquiryMessengerView(),
      ),
    );
  }

  @override
  State<InquiryChatView> createState() => _InquiryChatViewState();
}

class _InquiryChatViewState extends State<InquiryChatView> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isProductDetailsExpanded = false;
  bool _hasInitialScrolled = false;
  int _lastMessageCount = 0;
  bool _showScrollToBottomButton = false;

  @override
  void initState() {
    super.initState();
    _markRead();
    _scrollCtrl.addListener(_onScrollChanged);
    // Multi-pass initial auto-scroll to bottom so conversation immediately opens at the latest chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(immediate: true);
      Future.delayed(const Duration(milliseconds: 100), () => _scrollToBottom(immediate: true));
      Future.delayed(const Duration(milliseconds: 300), () => _scrollToBottom(immediate: true));
    });
  }

  void _onScrollChanged() {
    if (!_scrollCtrl.hasClients) return;
    final maxScroll = _scrollCtrl.position.maxScrollExtent;
    final currentScroll = _scrollCtrl.offset;
    final distanceFromBottom = maxScroll - currentScroll;

    final shouldShow = distanceFromBottom > 240;
    if (shouldShow != _showScrollToBottomButton) {
      setState(() {
        _showScrollToBottomButton = shouldShow;
      });
    }
  }

  void _markRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final inquiryCtrl = Get.find<InquiryController>();
      final isStaff = _isCurrentStaff();
      inquiryCtrl.markMessagesAsRead(widget.inquiryId, isStaffViewer: isStaff);
    });
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
  void dispose() {
    _scrollCtrl.removeListener(_onScrollChanged);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      final maxScroll = _scrollCtrl.position.maxScrollExtent;
      if (maxScroll <= 0) return;

      if (immediate) {
        _scrollCtrl.jumpTo(maxScroll);
      } else {
        _scrollCtrl.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(InquiryController controller) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();
    await controller.sendInquiryMessage(
      inquiryId: widget.inquiryId,
      text: text,
    );
    _scrollToBottom();
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
        child: Obx(() {
          final inq = inquiryCtrl.inquiries.firstWhereOrNull((i) => i.id == widget.inquiryId);

          if (inq == null) {
            return Scaffold(
              backgroundColor: AppTheme.bgDark,
              appBar: AppBar(
                backgroundColor: AppTheme.bgDark,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text('Inquiry Not Found', style: TextStyle(color: AppTheme.textPrimary)),
              ),
              body: const Center(
                child: Text('This inquiry is no longer available.', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            );
          }

          // Staff segregation guard: If this inquiry was replied to/claimed by another staff member
          if (isStaff) {
            final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
            final currentStaffId = auth?.userId.value.isNotEmpty == true ? auth!.userId.value : (auth?.userEmail.value ?? '');
            final currentStaffEmail = auth?.userEmail.value ?? '';
            final currentStaffName = auth?.displayName.value ?? '';
            if (!inq.isVisibleToStaff(currentStaffId, currentStaffEmail: currentStaffEmail, currentStaffName: currentStaffName)) {
              final handlerName = inq.assignedStaffName ?? 'another staff member';
              return Scaffold(
                backgroundColor: AppTheme.bgDark,
                appBar: AppBar(
                  backgroundColor: AppTheme.bgDark,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Text('Inquiry Claimed', style: TextStyle(color: AppTheme.textPrimary)),
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.lock, size: 36, color: AppTheme.accentOrange),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Handled by $handlerName',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This inquiry has already been replied to by another staff member. Each inquiry is handled exclusively by the staff who initiated it.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          }

          // Automatically mark read if viewing active stream
          _markRead();

          final messages = inq.effectiveMessages;

          // Auto-scroll to bottom when messages load or change
          if (messages.length != _lastMessageCount) {
            final isFirst = !_hasInitialScrolled;
            _lastMessageCount = messages.length;
            _hasInitialScrolled = true;
            _scrollToBottom(immediate: isFirst);
            Future.delayed(const Duration(milliseconds: 60), () => _scrollToBottom(immediate: isFirst));
            Future.delayed(const Duration(milliseconds: 180), () => _scrollToBottom(immediate: isFirst));
          }

          return Stack(
            children: [
              Column(
                children: [
                  // Top Chat Header Bar: Only Inquiry ID as title (no tags, no shop location)
                  _buildTopBar(context, inq, inquiryCtrl, isStaff),

                  // Product Info Tag (Kept directly below header)
                  _buildProductSummaryCard(inq),

                  // Chat Messages Area
                  Expanded(
                    child: messages.isEmpty
                        ? _buildEmptyChatState(inq, isStaff)
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isMe = isStaff ? msg.isStaff : !msg.isStaff;
                              return _buildMessageBubble(msg, inq, isMe: isMe);
                            },
                          ),
                  ),

                  // Bottom Message Input Bar
                  _buildMessageInputBar(inquiryCtrl, inq),
                ],
              ),
              // Floating Scroll-To-Bottom shortcut button (visible when scrolled up)
              if (_showScrollToBottomButton)
                Positioned(
                  right: 16,
                  bottom: 74,
                  child: GestureDetector(
                    onTap: () => _scrollToBottom(immediate: false),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accentOrange, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.chevronDown,
                        color: AppTheme.accentOrange,
                        size: 18,
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

  Widget _buildTopBar(
    BuildContext context,
    TireInquiry inq,
    InquiryController controller,
    bool isStaff,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.headerDark,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderDark, width: 1.2),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.textPrimary, size: 24),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              inq.orderId.startsWith('#') ? inq.orderId : '#${inq.orderId}',
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Staff Action: Check icon button representing Completed with confirmation modal
          if (isStaff && inq.status != InquiryStatus.cancelled) ...[
            IconButton(
              tooltip: inq.status == InquiryStatus.completed ? 'Order Completed' : 'Complete Order',
              icon: Icon(
                inq.status == InquiryStatus.completed ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                color: const Color(0xFF10B981),
                size: 22,
              ),
              onPressed: () {
                if (inq.status == InquiryStatus.completed) {
                  _showReopenConfirmation(context, inq, controller);
                } else {
                  _showCompleteConfirmation(context, inq, controller);
                }
              },
            ),
          ],
          // Toggle Product Tag Details Button
          IconButton(
            tooltip: 'Product Details',
            icon: Icon(
              _isProductDetailsExpanded ? LucideIcons.chevronUp : LucideIcons.info,
              color: AppTheme.accentOrange,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isProductDetailsExpanded = !_isProductDetailsExpanded;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductSummaryCard(TireInquiry inq) {
    if (!_isProductDetailsExpanded) {
      // Compact one-line product tag
      return Container(
        color: AppTheme.surfaceDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            const Icon(LucideIcons.tag, size: 13, color: AppTheme.accentOrange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${inq.tireBrand} ${inq.tireModel} (${inq.tireSize}) • ${inq.formattedTotalPrice}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppTheme.surfaceDark,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 48,
              height: 48,
              color: AppTheme.inputBg,
              padding: const EdgeInsets.all(3),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${inq.tireBrand} ${inq.tireModel}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${inq.tireSize} • ${inq.isSetOfFour ? 'Set of 4 tires' : '${inq.quantity} tire(s)'}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            inq.formattedTotalPrice,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppTheme.accentOrange,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatState(TireInquiry inq, bool isStaff) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
              ),
              child: const Icon(LucideIcons.messageSquare, color: AppTheme.accentOrange, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              isStaff ? 'Start Staff Response' : 'Conversation Started',
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isStaff
                  ? 'Send a message below to respond to the customer. Your reply will automatically move this inquiry to "Responded".'
                  : 'Send a message below to chat directly with shop staff regarding this inquiry.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(InquiryMessage msg, TireInquiry inq, {required bool isMe}) {
    final bubbleColor = isMe
        ? AppTheme.accentOrange.withValues(alpha: 0.18)
        : AppTheme.surfaceDark;

    final borderColor = isMe
        ? AppTheme.accentOrange.withValues(alpha: 0.5)
        : AppTheme.borderDark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 2),
                  bottomRight: Radius.circular(isMe ? 2 : 14),
                ),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender badge (especially visible for official staff)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (msg.isStaff) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'STAFF',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        _resolveSenderDisplayName(msg, inq),
                        style: TextStyle(
                          color: msg.isStaff ? AppTheme.accentOrange : const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Message Text
                  Text(
                    msg.text,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Timestamp
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _formatTime(msg.timestamp),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveSenderDisplayName(InquiryMessage msg, TireInquiry inq) {
    if (!msg.isStaff) {
      return msg.senderName.isNotEmpty ? msg.senderName : inq.customerName;
    }

    // Clean any legacy '(Staff)' suffix if present in stored message
    String clean = msg.senderName.replaceAll(RegExp(r'\s*\(Staff\)', caseSensitive: false), '').trim();

    // 1. If assignedStaffName on inquiry is set to a specific name (and not generic 'staff'), use it
    if (inq.assignedStaffName != null &&
        inq.assignedStaffName!.trim().isNotEmpty &&
        inq.assignedStaffName!.trim().toLowerCase() != 'staff') {
      return inq.assignedStaffName!.trim();
    }

    // 2. If the message senderName itself is a specific name (not 'staff' or 'guest')
    if (clean.isNotEmpty &&
        clean.toLowerCase() != 'staff' &&
        clean.toLowerCase() != 'guest' &&
        clean.toLowerCase() != 'user') {
      return clean;
    }

    // 3. Check InquiryController staff directory and active staff display name
    if (Get.isRegistered<InquiryController>()) {
      final inqCtrl = Get.find<InquiryController>();
      if (msg.senderId.isNotEmpty && inqCtrl.staffNames.containsKey(msg.senderId)) {
        final name = inqCtrl.staffNames[msg.senderId]!;
        if (name.isNotEmpty && name.toLowerCase() != 'staff') return name;
      }
      if (inq.assignedStaffId != null && inqCtrl.staffNames.containsKey(inq.assignedStaffId)) {
        final name = inqCtrl.staffNames[inq.assignedStaffId]!;
        if (name.isNotEmpty && name.toLowerCase() != 'staff') return name;
      }
      if (inqCtrl.activeStaffDisplayName.value.isNotEmpty &&
          inqCtrl.activeStaffDisplayName.value.toLowerCase() != 'staff') {
        return inqCtrl.activeStaffDisplayName.value;
      }
    }

    // 4. Check if current authenticated user is staff with a name set
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      if (auth.isStaff &&
          auth.displayName.value.isNotEmpty &&
          auth.displayName.value.toLowerCase() != 'staff' &&
          auth.displayName.value.toLowerCase() != 'guest') {
        return auth.displayName.value;
      }
    }

    // 5. Fallback: staff account was named 'jhon'
    return 'jhon';
  }

  /// Modal confirmation dialog to prevent accidental completion of inquiry
  /// Modal confirmation dialog to prevent accidental completion of inquiry
  void _showCompleteConfirmation(
    BuildContext context,
    TireInquiry inq,
    InquiryController controller,
  ) {
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
                'Complete Inquiry?',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to mark inquiry #${inq.id} as completed? The customer will receive a completed update.',
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
                  // Cancel button: Clean text button with NO border
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Confirm button: Solid vibrant green, bold text, less rounder (10px radius)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.statusCompleted,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        controller.updateInquiryStatus(inq.id, InquiryStatus.completed);
                        Get.back();
                      },
                      child: const Text(
                        'Yes, Complete',
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
  }

  /// Modal confirmation dialog for reopening completed orders
  void _showReopenConfirmation(
    BuildContext context,
    TireInquiry inq,
    InquiryController controller,
  ) {
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
                'Reopen Order?',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Order #${inq.orderId} is currently completed. Would you like to reopen this order to Confirmed state?',
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
                        'Keep Completed',
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
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        controller.updateInquiryStatus(inq.id, InquiryStatus.responded);
                        Get.back();
                        Get.snackbar(
                          'Order Reopened',
                          'Order #${inq.orderId} is now open in Confirmed state.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppTheme.surfaceElevated,
                          colorText: AppTheme.textPrimary,
                        );
                      },
                      child: const Text(
                        'Reopen',
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
  }

  Widget _buildMessageInputBar(InquiryController controller, TireInquiry inq) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: const BoxDecoration(
        color: AppTheme.headerDark,
        border: Border(
          top: BorderSide(color: AppTheme.borderDark, width: 1.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.inputBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: TextField(
                controller: _textCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _handleSendMessage(controller),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _handleSendMessage(controller),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.send,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}

/// Dedicated Top Bar Message Button with Dynamic Badge
class TopBarMessageButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const TopBarMessageButton({super.key, this.onPressed});

  bool _isStaffUser() {
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

    return Obx(() {
      final isStaff = _isStaffUser();
      final unread = isStaff
          ? inquiryCtrl.unreadCustomerMessagesCount
          : inquiryCtrl.unreadResponsesCount;

      return IconButton(
        tooltip: 'Chats',
        onPressed: onPressed ?? () => InquiryChatView.openConversations(context),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              LucideIcons.messageSquare,
              color: AppTheme.textPrimary,
              size: 22,
            ),
            if (unread > 0)
              Positioned(
                top: -3,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.bgDark, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
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
      );
    });
  }
}
