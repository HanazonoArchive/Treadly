import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/tire.dart';
import '../../services/tire_repository.dart';

/// Home tab data: best sellers and product grid.
class HomeController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxList<Tire> tires = <Tire>[].obs;
  final RxList<Tire> topBestsellers = <Tire>[].obs;

  final RxInt currentSlide = 0.obs;
  final PageController pageController = PageController();
  Timer? _autoSlideTimer;

  @override
  void onInit() {
    super.onInit();
    loadTires();
  }

  @override
  void onClose() {
    _autoSlideTimer?.cancel();
    pageController.dispose();
    super.onClose();
  }

  Future<void> loadTires() async {
    isLoading.value = true;
    try {
      final loadedTires = await TireRepository.instance.fetchTires();
      tires.assignAll(loadedTires);

      // Best sellers: most reviews first, rating breaks ties.
      final sortedBySales = List<Tire>.from(loadedTires)
        ..sort((a, b) {
          final comp = b.reviewsCount.compareTo(a.reviewsCount);
          if (comp != 0) return comp;
          return b.rating.compareTo(a.rating);
        });
      topBestsellers.assignAll(sortedBySales.take(5).toList());

      _startAutoSlide();
    } catch (e) {
      debugPrint('[HomeController] Error loading tires: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (topBestsellers.isEmpty) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!pageController.hasClients || topBestsellers.isEmpty) return;
      final nextIndex = (currentSlide.value + 1) % topBestsellers.length;
      pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void onSlideChanged(int index) {
    currentSlide.value = index;
  }

  void setSlide(int index) {
    currentSlide.value = index;
    if (pageController.hasClients) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Updates a tire on screen and in Firestore.
  Future<void> updateTire(Tire updatedTire) async {
    final idx = tires.indexWhere((t) => t.id == updatedTire.id);
    if (idx != -1) {
      tires[idx] = updatedTire;
      tires.refresh();
    }
    final bestIdx = topBestsellers.indexWhere((t) => t.id == updatedTire.id);
    if (bestIdx != -1) {
      topBestsellers[bestIdx] = updatedTire;
      topBestsellers.refresh();
    }
    await TireRepository.instance.updateTire(updatedTire);
  }
}
