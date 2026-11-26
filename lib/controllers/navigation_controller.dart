import 'package:get/get.dart';

import 'search/search_controller.dart';

class NavigationController extends GetxController {
  // 0 = Home, 1 = Search, 2 = Orders, 3 = Profile
  var currentTab = 0.obs;

  void changeTab(int index) {
    if (index != 1) {
      if (Get.isRegistered<SearchCatalogController>()) {
        Get.find<SearchCatalogController>().clearSearchQuery(resetCategory: true);
      }
    }
    currentTab.value = index;
  }
}

