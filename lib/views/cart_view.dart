import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Center(
          child: Text(
            'Cart',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
