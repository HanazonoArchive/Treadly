import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/app_theme.dart';
import '../../views/search_input_view.dart';

/// Top Search Bar on Home feed:
/// Acts as an interactive tap target (Shopee-style) that immediately directs
/// the user to the dedicated SearchInputView.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: GestureDetector(
        onTap: () {
          Get.to(() => const SearchInputView());
        },
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF141B2D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderDark),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: const Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search brand, model, size (e.g. 225/45 R18)...',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
