import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_theme.dart';

/// Modal bottom sheet for Help Center, Customer Support, and FAQs.
class HelpCenterModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.82,
        child: const _HelpCenterSheetContent(),
      ),
    );
  }
}

class _HelpCenterSheetContent extends StatelessWidget {
  const _HelpCenterSheetContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildHandle(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildHeader(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildSupportChannels(),
                const SizedBox(height: 20),
                const Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFaqItem(
                  question: 'How does tire inquiry and reservation work?',
                  answer:
                      'Find your tire in the catalog, choose your quantity or bundle, and submit an inquiry. Our shop team will review stock in real time. Once confirmed, your tires are reserved and prepped for your drive-in visit.',
                ),
                _buildFaqItem(
                  question: 'When do I pay for my tires and installation?',
                  answer:
                      'All payments are handled in-person directly at the shop when you arrive for your scheduled installation. No advance online payment is required.',
                ),
                _buildFaqItem(
                  question: 'How do I locate the shop?',
                  answer:
                      'Under your "Inquiries" tab, tap the "Location" button on any active inquiry to view our shop branch address, contact numbers, and interactive map directions.',
                ),
                _buildFaqItem(
                  question: 'How do I check my vehicle tire size?',
                  answer:
                      'Check the placard sticker on the driver-side door jamb, your car owner\'s manual, or read the embossed numbers on your current tire sidewall (e.g. 225/45 R18).',
                ),
                _buildFaqItem(
                  question: 'Can I cancel my inquiry or reservation?',
                  answer:
                      'Yes, you can tap "Cancel Inquiry" in the Inquiries tab at any time before your drive-in visit with zero cancellation fees.',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.lifeBuoy, color: AppTheme.accentOrange, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help Center & FAQs',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Tire fitment guide & customer care',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(LucideIcons.x, color: AppTheme.textSecondary, size: 20),
        ),
      ],
    );
  }

  Widget _buildSupportChannels() {
    return Row(
      children: [
        Expanded(
          child: _buildChannelCard(
            icon: LucideIcons.phoneCall,
            title: 'Hotline',
            subtitle: '1-800-TREADLY',
            onTap: () => _showContactPrompt(
              title: 'Customer Hotline',
              detail: 'Toll-free: 1-800-TREADLY\nLandline: +63 (02) 8888-TIRE\nHours: Mon–Sun, 8:00 AM – 8:00 PM',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildChannelCard(
            icon: LucideIcons.messageSquare,
            title: 'Live Chat',
            subtitle: 'Tire Specialist',
            onTap: () => Get.snackbar(
              'Tire Specialist',
              'Connecting with our fitment advisor... Average wait: < 1 min.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppTheme.surfaceDark,
              colorText: AppTheme.accentOrange,
              margin: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildChannelCard(
            icon: LucideIcons.mail,
            title: 'Email',
            subtitle: 'support@treadly',
            onTap: () => _showContactPrompt(
              title: 'Email Customer Support',
              detail: 'Send your inquiries to support@treadly.ph.\nOur concierge team replies within 2 hours.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.bgDark.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.accentOrange.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.accentOrange, size: 20),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppTheme.accentOrange,
          collapsedIconColor: AppTheme.textSecondary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            question,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Text(
              answer,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactPrompt({required String title, required String detail}) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        content: Text(
          detail,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Get.back(),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
