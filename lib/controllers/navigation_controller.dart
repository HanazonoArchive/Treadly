import 'package:get/get.dart';

import 'search/search_controller.dart';

class NavigationController extends GetxController {
  // 0 = Home, 1 = Search, 2 = Inquiries, 3 = Profile
  var currentTab = 0.obs;

  void changeTab(int index) {
    if (index != 1) {
      // Whenever leaving or not on Search (going to Home, Inquiries, or Profile),
      // empty out the search input and reset category to clean defaults
      if (Get.isRegistered<SearchCatalogController>()) {
        Get.find<SearchCatalogController>().clearSearchQuery(resetCategory: true);
      }
    }
    currentTab.value = index;
  }
}

