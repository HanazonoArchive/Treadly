import 'dart:math' as math;
import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/search/search_controller.dart';
import '../../core/app_theme.dart';

/// Dynamic Tire Sizing Studio & Blueprint Visualizer
/// Combines a real-time dual CustomPainter canvas (Front Stance & Side Profile)
/// with an ergonomic 3-column tumbler wheel picker for Width, Aspect Ratio, and Rim.
class TireSizingStudioSheet extends StatefulWidget {
  const TireSizingStudioSheet({super.key});

  @override
  State<TireSizingStudioSheet> createState() => _TireSizingStudioSheetState();
}

class _TireSizingStudioSheetState extends State<TireSizingStudioSheet> {
  final SearchCatalogController controller = Get.find<SearchCatalogController>();

  // Dynamically populated sizing parameter datasets from active catalog
  late final List<int?> widths;
  late final List<int?> ratios;
  late final List<int?> rims;

  late final FixedExtentScrollController _widthController;
  late final FixedExtentScrollController _ratioController;
  late final FixedExtentScrollController _rimController;

  @override
  void initState() {
    super.initState();

    // 1. Dynamically extract unique sorted dimensions from active tire inventory
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
              // 1. Top Header: Just "Filter" on the left, "Reset" on the right
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

              // 2. Dual Canvas Visualizer Box (Front Stance & Side Profile)
              Obx(() {
                final w = controller.selectedWidth.value;
                final r = controller.selectedRatio.value;
                final rim = controller.selectedRim.value;

                return Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF090E17),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderDark, width: 1.2),
                  ),
                  child: Stack(
                    children: [
                      // Dual CustomPainter Row
                      Row(
                        children: [
                          // Left Panel: Front Stance (Width & Tread)
                          Expanded(
                            child: CustomPaint(
                              painter: TireFrontPainter(width: w),
                              child: Container(),
                            ),
                          ),
                          // Subtle vertical divider between views
                          Container(
                            width: 1,
                            height: 110,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                          // Right Panel: Side Profile (Rim & Sidewall)
                          Expanded(
                            child: CustomPaint(
                              painter: TireSidePainter(rim: rim, ratio: r),
                              child: Container(),
                            ),
                          ),
                        ],
                      ),

                      // View Labels at bottom corners
                      const Positioned(
                        bottom: 6,
                        left: 12,
                        child: Text(
                          'FRONT STANCE',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const Positioned(
                        bottom: 6,
                        right: 12,
                        child: Text(
                          'SIDE PROFILE',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),

              const SizedBox(height: 12),

              // 4. 3-Column Tumbler Wheel Picker (Width, Ratio, Rim)
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    // Column 1: WIDTH (mm)
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

                    // Column 2: RATIO (%)
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

                    // Column 3: RIM (in)
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

              // 4. In-Stock Only Switch (Clean transparent row, no icon, no background, no border)
              Obx(() => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'In-Stock Tires Only',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch(
                          value: controller.inStockOnly.value,
                          activeThumbColor: AppTheme.accentOrange,
                          activeTrackColor: AppTheme.accentOrange.withValues(alpha: 0.3),
                          inactiveThumbColor: AppTheme.textSecondary,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                          onChanged: (val) => controller.inStockOnly.value = val,
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),

              // 6. Apply Button with Live Matching Counter
              Obx(() {
                final matchCount = controller.searchResults.length;
                final hasMatches = matchCount > 0;

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasMatches ? AppTheme.accentOrange : const Color(0xFF334155),
                      foregroundColor: hasMatches ? Colors.black : Colors.white70,
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
                    color: Colors.white,
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

/// CustomPainter: Front Stance View (Tread Width & Grooves)
class TireFrontPainter extends CustomPainter {
  final int? width;

  const TireFrontPainter({this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveWidth = (width ?? 225).clamp(165, 335).toDouble();
    // Normalize width between 165 and 335 -> visual width between 32 and 76 px
    final norm = (effectiveWidth - 165) / 170.0;
    final tireW = 32.0 + (norm * 44.0);
    const tireH = 76.0;

    final center = Offset(size.width / 2, size.height / 2 + 5);
    final tireRect = Rect.fromCenter(center: center, width: tireW, height: tireH);
    final rrect = RRect.fromRectAndRadius(tireRect, const Radius.circular(8));

    // 1. Rubber background with subtle gradient
    final rubberPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF0F172A)],
      ).createShader(tireRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, rubberPaint);

    // 2. Tire outline border
    final borderPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rrect, borderPaint);

    // 3. Longitudinal Tread Grooves
    final groovePaint = Paint()
      ..color = const Color(0xFF070B12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final grooveCount = tireW > 54 ? 3 : 2;
    for (int i = 1; i <= grooveCount; i++) {
      final xOffset = -tireW / 2 + (tireW / (grooveCount + 1)) * i;
      canvas.drawLine(
        Offset(center.dx + xOffset, center.dy - tireH / 2 + 5),
        Offset(center.dx + xOffset, center.dy + tireH / 2 - 5),
        groovePaint,
      );
    }

    // 4. Caliper measurement brackets on top
    final caliperY = center.dy - tireH / 2 - 8;
    final caliperPaint = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final leftX = center.dx - tireW / 2;
    final rightX = center.dx + tireW / 2;

    canvas.drawLine(Offset(leftX, caliperY), Offset(rightX, caliperY), caliperPaint);
    canvas.drawLine(Offset(leftX, caliperY - 3), Offset(leftX, caliperY + 3), caliperPaint);
    canvas.drawLine(Offset(rightX, caliperY - 3), Offset(rightX, caliperY + 3), caliperPaint);

    // Measurement text
    final textSpan = TextSpan(
      text: width != null ? '$width mm' : 'Any Width',
      style: TextStyle(
        fontFamily: 'Outfit',
        color: width != null ? const Color(0xFFF97316) : const Color(0xFF94A3B8),
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
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

/// CustomPainter: Side Profile View (Rim & Sidewall Ring)
class TireSidePainter extends CustomPainter {
  final int? rim;
  final int? ratio;

  const TireSidePainter({this.rim, this.ratio});

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveRim = (rim ?? 18).clamp(13, 22).toDouble();

    final center = Offset(size.width / 2, size.height / 2 + 5);
    const outerRadius = 42.0;

    // Rim radius scales from 19.0 to 32.0 based on rim size (14" to 21")
    final rimNorm = (effectiveRim - 13) / 9.0;
    final rimRadius = 19.0 + (rimNorm * 13.0);

    // 1. Outer tire circle (black rubber)
    final tirePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF090E17)],
        stops: [0.6, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, tirePaint);

    final tireBorder = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, outerRadius, tireBorder);

    // 2. Rim Wheel (Alloy circle)
    final rimPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF94A3B8), Color(0xFF475569), Color(0xFF334155)],
      ).createShader(Rect.fromCircle(center: center, radius: rimRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, rimRadius, rimPaint);

    final rimBorder = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, rimRadius, rimBorder);

    // 3. 5 Alloy Wheel Spokes
    final spokePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 72.0 - 90.0) * (math.pi / 180.0);
      final spokeEnd = Offset(
        center.dx + (rimRadius - 2) * math.cos(angle),
        center.dy + (rimRadius - 2) * math.sin(angle),
      );
      canvas.drawLine(center, spokeEnd, spokePaint);
    }

    // 4. Center Cap Hub
    final hubPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5.5, hubPaint);
    final hubBorder = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 5.5, hubBorder);

    // 5. Caliper Measurement Callout on Top
    final caliperY = center.dy - outerRadius - 8;
    final caliperPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final leftX = center.dx - rimRadius;
    final rightX = center.dx + rimRadius;

    canvas.drawLine(Offset(leftX, caliperY), Offset(rightX, caliperY), caliperPaint);
    canvas.drawLine(Offset(leftX, caliperY - 3), Offset(leftX, caliperY + 3), caliperPaint);
    canvas.drawLine(Offset(rightX, caliperY - 3), Offset(rightX, caliperY + 3), caliperPaint);

    final rimText = rim != null ? '$rim"' : 'Any Rim';
    final ratioText = ratio != null ? '/$ratio' : '';
    final textSpan = TextSpan(
      text: '$rimText $ratioText',
      style: TextStyle(
        fontFamily: 'Outfit',
        color: rim != null ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
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
