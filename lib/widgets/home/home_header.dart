import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../views/inquiry_chat_view.dart';

/// Top Brand Header: Bold, thick Treadly wordmark with Top Bar Message Button & Dynamic Badge
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, AppTheme.accentOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              'TREADLY',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ),
          const TopBarMessageButton(),
        ],
      ),
    );
  }
}
