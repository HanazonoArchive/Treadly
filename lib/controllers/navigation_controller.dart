import 'package:get/get.dart';

class NavigationController extends GetxController {
  // 0 = Home, 1 = Search, 2 = Wishlist, 3 = Cart, 4 = Profile
  var currentTab = 0.obs;

  void changeTab(int index) {
    currentTab.value = index;
  }
}

