import 'dart:math' as math;
import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/search/search_controller.dart';
import '../../core/app_theme.dart';

/// Tire Sizing Studio bottom sheet: width/rim diagrams drawn with CustomPainter
/// plus scroll pickers for width, aspect ratio and rim.
class TireSizingStudioSheet extends StatefulWidget {
  const TireSizingStudioSheet({super.key});

  @override
  State<TireSizingStudioSheet> createState() => _TireSizingStudioSheetState();
}

class _TireSizingStudioSheetState extends State<TireSizingStudioSheet> {
  final SearchCatalogController controller = Get.find<SearchCatalogController>();

  // Picker values, built from the sizes in the catalog
  late final List<int?> widths;
  late final List<int?> ratios;
  late final List<int?> rims;

  late final FixedExtentScrollController _widthController;
  late final FixedExtentScrollController _ratioController;
  late final FixedExtentScrollController _rimController;

  @override
  void initState() {
    super.initState();

    // Unique sorted sizes from the catalog
    final catalogWidths = controller.allTires
        .map((t) => t.width)
        .where((w) => w > 0)
        .toSet()
        .toList()
      ..sort();

    final catalogRatios = controller.allTires
        .map((t) => t.aspectRatio)
        .where((r) => r > 0)
        .toSet()
        .toList()
      ..sort();

    final catalogRims = controller.allTires
        .map((t) => t.rimSize)
        .where((r) => r > 0)
        .toSet()
        .toList()
      ..sort();

    widths = [
      null,
      ...(catalogWidths.isNotEmpty
          ? catalogWidths
          : [175, 185, 195, 205, 215, 225, 235, 245, 255, 265, 275, 285, 295, 325])
    ];

    ratios = [
      null,
      ...(catalogRatios.isNotEmpty
          ? catalogRatios
          : [30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80])
    ];

    rims = [
      null,
      ...(catalogRims.isNotEmpty
          ? catalogRims
          : [14, 15, 16, 17, 18, 19, 20, 21])
    ];

    final widthIdx = widths.indexOf(controller.selectedWidth.value);
    _widthController = FixedExtentScrollController(initialItem: widthIdx >= 0 ? widthIdx : 0);

    final ratioIdx = ratios.indexOf(controller.selectedRatio.value);
    _ratioController = FixedExtentScrollController(initialItem: ratioIdx >= 0 ? ratioIdx : 0);

    final rimIdx = rims.indexOf(controller.selectedRim.value);
    _rimController = FixedExtentScrollController(initialItem: rimIdx >= 0 ? rimIdx : 0);
  }

  @override
  void dispose() {
    _widthController.dispose();
    _ratioController.dispose();
    _rimController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    controller.selectedWidth.value = null;
    controller.selectedRatio.value = null;
    controller.selectedRim.value = null;
    controller.inStockOnly.value = false;

    if (_widthController.hasClients) {
      _widthController.animateToItem(0, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    }
    if (_ratioController.hasClients) {
      _ratioController.animateToItem(0, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    }
    if (_rimController.hasClients) {
      _rimController.animateToItem(0, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.borderDark, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: title and Reset
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh_rounded, size: 14, color: AppTheme.accentOrange),
                    label: const Text(
                      'Reset',
                      style: TextStyle(
                        color: AppTheme.accentOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Diagrams
              Obx(() {
                final w = controller.selectedWidth.value;
                final r = controller.selectedRatio.value;
                final rim = controller.selectedRim.value;

                return Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderDark, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      // Front view (width)
                      Expanded(
                        child: CustomPaint(
                          painter: TireFrontPainter(width: w),
                          child: Container(),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 110,
                        color: const Color(0xFFE2E8F0),
                      ),
                      // Side view (rim)
                      Expanded(
                        child: CustomPaint(
                          painter: TireSidePainter(rim: rim, ratio: r),
                          child: Container(),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),

              const SizedBox(height: 12),

              // Pickers
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPickerColumn(
                        label: 'WIDTH (mm)',
                        controller: _widthController,
                        itemCount: widths.length,
                        itemBuilder: (index) => widths[index] != null ? '${widths[index]}' : 'Any',
                        onChanged: (index) => controller.selectedWidth.value = widths[index],
                      ),
                    ),
                    Container(width: 1, height: 80, color: AppTheme.borderDark),

                    Expanded(
                      child: _buildPickerColumn(
                        label: 'PROFILE (%)',
                        controller: _ratioController,
                        itemCount: ratios.length,
                        itemBuilder: (index) => ratios[index] != null ? '${ratios[index]}%' : 'Any',
                        onChanged: (index) => controller.selectedRatio.value = ratios[index],
                      ),
                    ),
                    Container(width: 1, height: 80, color: AppTheme.borderDark),

                    Expanded(
                      child: _buildPickerColumn(
                        label: 'RIM (in)',
                        controller: _rimController,
                        itemCount: rims.length,
                        itemBuilder: (index) => rims[index] != null ? '${rims[index]}"' : 'Any',
                        onChanged: (index) => controller.selectedRim.value = rims[index],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // In-stock only
              Obx(() => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'In-Stock Tires Only',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch(
                          value: controller.inStockOnly.value,
                          activeThumbColor: AppTheme.accentOrange,
                          activeTrackColor: AppTheme.accentOrange.withValues(alpha: 0.3),
                          inactiveThumbColor: AppTheme.textSecondary,
                          inactiveTrackColor: AppTheme.inputBg,
                          onChanged: (val) => controller.inStockOnly.value = val,
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),

              // Apply button with match count
              Obx(() {
                final matchCount = controller.searchResults.length;
                final hasMatches = matchCount > 0;

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasMatches ? AppTheme.accentOrange : const Color(0xFF94A3B8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Get.back(),
                    child: Text(
                      hasMatches
                          ? 'Apply Filter ($matchCount Tire${matchCount == 1 ? '' : 's'} Found)'
                          : 'Apply Filter (0 In-Store Matches)',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerColumn({
    required String label,
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) itemBuilder,
    required void Function(int) onChanged,
  }) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.3,
          ),
        ),
        Expanded(
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 32,
            magnification: 1.15,
            useMagnifier: true,
            squeeze: 1.1,
            selectionOverlay: Container(
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: AppTheme.accentOrange.withValues(alpha: 0.45),
                    width: 1,
                  ),
                ),
              ),
            ),
            onSelectedItemChanged: onChanged,
            children: List.generate(itemCount, (index) {
              return Center(
                child: Text(
                  itemBuilder(index),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// Front view of the tire; drawn width follows the selected section width.
class TireFrontPainter extends CustomPainter {
  final int? width;

  const TireFrontPainter({this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveWidth = (width ?? 225).clamp(165, 335).toDouble();
    // Map 165-335 mm to 34-76 px.
    final norm = (effectiveWidth - 165) / 170.0;
    final tireW = 34.0 + (norm * 42.0);
    const tireH = 74.0;

    final center = Offset(size.width / 2, size.height / 2 + 4);
    final tireRect = Rect.fromCenter(center: center, width: tireW, height: tireH);
    final rrect = RRect.fromRectAndRadius(tireRect, const Radius.circular(6));

    // Background
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // Outline
    final linePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRRect(rrect, linePaint);

    // Shoulder lines
    final shoulderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(center.dx - tireW / 2 + 4, center.dy - tireH / 2 + 6),
      Offset(center.dx - tireW / 2 + 4, center.dy + tireH / 2 - 6),
      shoulderPaint,
    );
    canvas.drawLine(
      Offset(center.dx + tireW / 2 - 4, center.dy - tireH / 2 + 6),
      Offset(center.dx + tireW / 2 - 4, center.dy + tireH / 2 - 6),
      shoulderPaint,
    );

    // Tread grooves
    final groovePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final grooveCount = tireW > 54 ? 3 : 2;
    for (int i = 1; i <= grooveCount; i++) {
      final xOffset = -tireW / 2 + (tireW / (grooveCount + 1)) * i;
      canvas.drawLine(
        Offset(center.dx + xOffset, center.dy - tireH / 2 + 5),
        Offset(center.dx + xOffset, center.dy + tireH / 2 - 5),
        groovePaint,
      );
    }

    // Width dimension line
    final caliperY = center.dy - tireH / 2 - 8;
    final draftingPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final leftX = center.dx - tireW / 2;
    final rightX = center.dx + tireW / 2;

    canvas.drawLine(Offset(leftX, caliperY), Offset(rightX, caliperY), draftingPaint);
    canvas.drawLine(Offset(leftX, caliperY - 3), Offset(leftX, caliperY + 3), draftingPaint);
    canvas.drawLine(Offset(rightX, caliperY - 3), Offset(rightX, caliperY + 3), draftingPaint);

    final textSpan = TextSpan(
      text: width != null ? '$width mm' : 'Width',
      style: const TextStyle(
        fontFamily: 'Outfit',
        color: Color(0xFF0F172A),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, caliperY - 13),
    );
  }

  @override
  bool shouldRepaint(covariant TireFrontPainter oldDelegate) => oldDelegate.width != width;
}

/// Side view of the wheel; rim size changes the drawn rim radius.
class TireSidePainter extends CustomPainter {
  final int? rim;
  final int? ratio;

  const TireSidePainter({this.rim, this.ratio});

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveRim = (rim ?? 18).clamp(13, 22).toDouble();

    final center = Offset(size.width / 2, size.height / 2 + 4);
    const outerRadius = 40.0;

    // Rim radius 18-30 px depending on rim size.
    final rimNorm = (effectiveRim - 13) / 9.0;
    final rimRadius = 18.0 + (rimNorm * 12.0);

    // Background
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, fillPaint);

    // Tire outline
    final outerTirePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, outerRadius, outerTirePaint);

    // Sidewall
    final sidewallPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, outerRadius - 4, sidewallPaint);

    // Rim
    final rimPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, rimRadius, rimPaint);

    // Spokes
    final spokePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const spokeCount = 5;
    for (int i = 0; i < spokeCount; i++) {
      final angle = (i * (360.0 / spokeCount) - 90.0) * (math.pi / 180.0);
      final spokeEnd = Offset(
        center.dx + (rimRadius - 1) * math.cos(angle),
        center.dy + (rimRadius - 1) * math.sin(angle),
      );
      canvas.drawLine(center, spokeEnd, spokePaint);
    }

    // Hub
    final hubBorder = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, 5.0, hubBorder);

    final hubCenter = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.0, hubCenter);

    // Rim dimension line
    final caliperY = center.dy - outerRadius - 8;
    final draftingPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final leftX = center.dx - rimRadius;
    final rightX = center.dx + rimRadius;

    canvas.drawLine(Offset(leftX, caliperY), Offset(rightX, caliperY), draftingPaint);
    canvas.drawLine(Offset(leftX, caliperY - 3), Offset(leftX, caliperY + 3), draftingPaint);
    canvas.drawLine(Offset(rightX, caliperY - 3), Offset(rightX, caliperY + 3), draftingPaint);

    final rimText = rim != null ? '$rim"' : 'Rim';
    final ratioText = ratio != null ? ' / R$ratio' : '';
    final textSpan = TextSpan(
      text: '$rimText$ratioText',
      style: const TextStyle(
        fontFamily: 'Outfit',
        color: Color(0xFF0F172A),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, caliperY - 13),
    );
  }

  @override
  bool shouldRepaint(covariant TireSidePainter oldDelegate) =>
      oldDelegate.rim != rim || oldDelegate.ratio != ratio;
}
