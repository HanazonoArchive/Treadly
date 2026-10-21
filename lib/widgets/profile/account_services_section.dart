import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_theme.dart';
import 'help_center_modal.dart';

/// Section providing access to Help Center & FAQs.
class AccountServicesSection extends StatelessWidget {
  const AccountServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account & Support',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildHelpCenterCard(context),
      ],
    );
  }

  Widget _buildHelpCenterCard(BuildContext context) {
    return Material(
      color: AppTheme.bgDark.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => HelpCenterModal.show(context),
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.accentOrange.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.lifeBuoy,
                  color: AppTheme.accentOrange,
                  size: 20,
                ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tire fitment guide, drive-in reservations & hotline',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                color: AppTheme.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
