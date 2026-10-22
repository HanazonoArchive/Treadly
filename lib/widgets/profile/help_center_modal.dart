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
                'Tire fitment guide & inquiry answers',
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
}
