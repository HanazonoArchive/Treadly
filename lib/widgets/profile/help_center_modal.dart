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
                  question: 'How does tire ordering and in-store pickup work?',
                  answer:
                      'Select your tires in the catalog, choose your quantity or Set of 4 bundle, and tap "Order". Your order starts as "Placed". Once our workshop bay team verifies stock, your order status becomes "Confirmed" and prepped for your drive-in bay fitment.',
                ),
                _buildFaqItem(
                  question: 'When do I pay for my tires and installation?',
                  answer:
                      'All payments are settled in-person directly at the workshop counter after your tires are installed. We accept Cash, GCash, and Card with zero advance online fees.',
                ),
                _buildFaqItem(
                  question: 'Where is Treadly located?',
                  answer:
                      'Our flagship workshop center is located at 108 Quezon Avenue, Quezon City. You can view our operating hours, hotline, and drive-in service bay details under Workshop Bay Location in your Profile.',
                ),
                _buildFaqItem(
                  question: 'What is included in the bay service?',
                  answer:
                      'Every tire purchase includes in-bay tire mounting, high-speed balancing, tire disposal, and computerized alignment diagnostics.',
                ),
                _buildFaqItem(
                  question: 'How do I check my vehicle tire size?',
                  answer:
                      'Check the placard sticker on the driver-side door jamb, your car owner\'s manual, or read the embossed numbers on your current tire sidewall (e.g. 225/45 R18).',
                ),
                _buildFaqItem(
                  question: 'Can I cancel my order?',
                  answer:
                      'Yes, you can tap "Cancel Order" in the Orders tab at any time before your drive-in visit with zero cancellation fees.',
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
        color: AppTheme.borderDark,
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
                'Tire fitment guide & workshop FAQs',
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
