import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../widgets/profile/top_banner.dart';
import '../widgets/profile/top_nav_bar.dart';
import '../widgets/profile/body_my_purchase.dart';
import '../widgets/profile/body_my_wallet.dart';
import '../widgets/profile/account_services_section.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            ProfileTopNavBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TopBanner(),
                    const SizedBox(height: 22),
                    MyPurchaseSection(),
                    const SizedBox(height: 22),
                    MyWalletSection(),
                    const SizedBox(height: 22),
                    const AccountServicesSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
