import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../controllers/auth_controller.dart';
import '../../core/app_theme.dart';

class TopBanner extends StatelessWidget {
  const TopBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.put(AuthController(), permanent: true);

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildAvatar(auth),
                  const SizedBox(width: 14),
                  Expanded(child: _buildNameAndBadge(auth)),
                ],
              ),
            ),
            if (auth.isGuest.value)
              _buildSignInButton()
            else
              _buildSignOutButton(auth),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(AuthController auth) {
    final avatarUrl = auth.avatarUrl.value;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.bgDark,
        border: Border.all(color: AppTheme.accentOrange, width: 2),
        image: avatarUrl.isNotEmpty
            ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
            : null,
      ),
      child: avatarUrl.isEmpty
          ? const Center(
              child: Icon(LucideIcons.user, color: AppTheme.textPrimary, size: 28),
            )
          : null,
    );
  }

  Widget _buildNameAndBadge(AuthController auth) {
    final showEmail = !auth.isGuest.value && auth.userEmail.value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          auth.displayName.value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (showEmail) ...[
          const SizedBox(height: 2),
          Text(
            auth.userEmail.value,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildSignInButton() {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: AppTheme.accentOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => Get.toNamed('/sign-in'),
      child: const Text(
        'Sign In',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSignOutButton(AuthController auth) {
    return IconButton(
      icon: const Icon(
        LucideIcons.logOut,
        color: AppTheme.textSecondary,
        size: 20,
      ),
      tooltip: 'Sign Out',
      onPressed: () => auth.signOut(),
    );
  }
}
