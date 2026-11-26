import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showToast(String message) {
  Get.rawSnackbar(
    messageText: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontSize: 14),
    ),
    backgroundColor: const Color(0xE6323232),
    borderRadius: 24,
    margin: const EdgeInsets.fromLTRB(40, 0, 40, 40),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    duration: const Duration(seconds: 2),
    animationDuration: const Duration(milliseconds: 250),
  );
}
