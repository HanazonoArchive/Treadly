import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../views/inquiry_chat_view.dart';

/// Home header: Treadly wordmark and message icon.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'TREADLY',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: AppTheme.accentOrange,
            ),
          ),
          const TopBarMessageButton(),
        ],
      ),
    );
  }
}
