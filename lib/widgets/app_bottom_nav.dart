import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../controllers/inquiry/inquiry_controller.dart';
import '../controllers/navigation_controller.dart';
import '../core/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController nav = Get.find<NavigationController>();
    final InquiryController inquiryCtrl = Get.isRegistered<InquiryController>()
        ? Get.find<InquiryController>()
        : Get.put(InquiryController(), permanent: true);

    return Obx(
      () => NavigationBar(
        selectedIndex: nav.currentTab.value,
        onDestinationSelected: (index) {
          nav.changeTab(index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Obx(() {
              final activeCount = inquiryCtrl.activeInquiries.length;
              return Badge(
                isLabelVisible: activeCount > 0,
                backgroundColor: AppTheme.accentOrange,
                textColor: Colors.black,
                label: Text(
                  '$activeCount',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
                ),
                child: const Icon(LucideIcons.calendarClock),
              );
            }),
            selectedIcon: Obx(() {
              final activeCount = inquiryCtrl.activeInquiries.length;
              return Badge(
                isLabelVisible: activeCount > 0,
                backgroundColor: AppTheme.accentOrange,
                textColor: Colors.black,
                label: Text(
                  '$activeCount',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
                ),
                child: const Icon(LucideIcons.calendarClock, color: AppTheme.accentOrange),
              );
            }),
            label: 'Inquiries',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
