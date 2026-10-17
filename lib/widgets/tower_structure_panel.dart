import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/inspection_model.dart';
import '../services/image_service.dart';

class TowerStructurePanel extends StatefulWidget {
  final Tower tower;
  final Circuit? selectedCircuit;
  final Phase? selectedPhase;
  final ValueChanged<Circuit>? onSelectCircuit;
  final ValueChanged<Phase>? onSelectPhase;
  final double? width;

  const TowerStructurePanel({
    super.key,
    required this.tower,
    this.selectedCircuit,
    this.selectedPhase,
    this.onSelectCircuit,
    this.onSelectPhase,
    this.width,
  });

  @override
  State<TowerStructurePanel> createState() => _TowerStructurePanelState();
}

class _TowerStructurePanelState extends State<TowerStructurePanel> {
  // Raw image dimension: 1920 x 1080.
  // Crop area focusing on the tower:
  static const double _cropLeft = 620.0;
  static const double _cropTop = 130.0;
  static const double _cropWidth = 680.0;
  static const double _cropHeight = 850.0;

  @override
  Widget build(BuildContext context) {
    final hasSelectedCircuit = widget.selectedCircuit != null;

    const imagePath = AppConfig.baseTowerImageAsset;

    return Container(
      width: widget.width ?? 410,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and [ RGB | Thermal ] Pill Toggle (shown only when a circuit is selected)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tower structure',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ' · 400 kV · Site B',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),


                  ],
                ),
                const SizedBox(height: 12),

                // Metadata Row: STRUCTURE, TOWER TYPE
                const Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STRUCTURE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Not available',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOWER TYPE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Double circuit - Suspension',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Subtitle label: WHOLE TOWER vs SELECTED CIRCUIT
                if (!hasSelectedCircuit)
                  const Text(
                    'WHOLE TOWER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                      letterSpacing: 0.5,
                    ),
                  )
                else
                  Row(
                    children: [
                      const Text(
                        'SELECTED CIRCUIT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.selectedCircuit!.circuitId,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1967D2),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Main Cropped Tower Frame
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boxW = constraints.maxWidth;
                    final boxH = constraints.maxHeight;

                    final scaleX = boxW / _cropWidth;
                    final scaleY = boxH / _cropHeight;
                    final scale = scaleX < scaleY ? scaleX : scaleY;

                    final renderW = _cropWidth * scale;
                    final renderH = _cropHeight * scale;

                    return Center(
                      child: SizedBox(
                        width: renderW,
                        height: renderH,
                        child: GestureDetector(
                          onTapUp: (details) {
                            if (!hasSelectedCircuit || widget.onSelectPhase == null) return;
                            _handleTowerTap(details.localPosition, scale);
                          },
                          child: Stack(
                            children: [
                              // 1. Cropped & Scaled Base Tower Photo
                              Positioned(
                                left: -_cropLeft * scale,
                                top: -_cropTop * scale,
                                width: 1920.0 * scale,
                                height: 1080.0 * scale,
                                child: ImageService.buildImage(
                                  imagePath: imagePath,
                                  fit: BoxFit.fill,
                                ),
                              ),

                              // 2. Highlighting circuit and phases ONLY when a circuit is selected
                              if (hasSelectedCircuit)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _SelectiveTowerPainter(
                                      scale: scale,
                                      selectedCircuit: widget.selectedCircuit!,
                                      selectedPhase: widget.selectedPhase,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Legend under Tower Image matching ui_designs/3.png
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: PHASE
                Row(
                  children: [
                    const Text(
                      'PHASE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 14),
                    _buildDot('R', const Color(0xFFEF4444)),
                    const SizedBox(width: 10),
                    _buildDot('Y', const Color(0xFFEAB308)),
                    const SizedBox(width: 10),
                    _buildDot('B', const Color(0xFF2563EB)),
                  ],
                ),
                const SizedBox(height: 6),

                // Row 2: CONDITION
                Row(
                  children: [
                    const Text(
                      'CONDITION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildSquare('Critical', const Color(0xFFDB322E)),
                    const SizedBox(width: 8),
                    _buildSquare('Major', const Color(0xFFF97316)),
                    const SizedBox(width: 8),
                    _buildSquare('Minor', const Color(0xFFEAB308)),
                    const SizedBox(width: 8),
                    _buildSquare('Normal', const Color(0xFF22C55E)),
                  ],
                ),
                const SizedBox(height: 6),

                // Row 3: Not inspected
                Row(
                  children: [
                    _buildSquare('Not inspected', const Color(0xFF94A3B8)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTowerTap(Offset localPos, double scale) {
    if (widget.selectedCircuit == null) return;
    final isSW = widget.selectedCircuit!.circuitId.contains('SW');

    final double yR = isSW ? (295.0 - _cropTop) * scale : (289.7 - _cropTop) * scale;
    final double yY = isSW ? (448.0 - _cropTop) * scale : (455.2 - _cropTop) * scale;
    final double yB = isSW ? (600.0 - _cropTop) * scale : (593.9 - _cropTop) * scale;

    const threshold = 35.0;
    if ((localPos.dy - yR).abs() < threshold) {
      final p = widget.selectedCircuit!.phases['R'];
      if (p != null) widget.onSelectPhase!(p);
    } else if ((localPos.dy - yY).abs() < threshold) {
      final p = widget.selectedCircuit!.phases['Y'];
      if (p != null) widget.onSelectPhase!(p);
    } else if ((localPos.dy - yB).abs() < threshold) {
      final p = widget.selectedCircuit!.phases['B'];
      if (p != null) widget.onSelectPhase!(p);
    }
  }



  Widget _buildDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildSquare(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}

class _SelectiveTowerPainter extends CustomPainter {
  final double scale;
  final Circuit selectedCircuit;
  final Phase? selectedPhase;

  _SelectiveTowerPainter({
    required this.scale,
    required this.selectedCircuit,
    required this.selectedPhase,
  });

  static const double _cropLeft = 620.0;
  static const double _cropTop = 130.0;

  double _toX(double x) => (x - _cropLeft) * scale;
  double _toY(double y) => (y - _cropTop) * scale;

  @override
  void paint(Canvas canvas, Size size) {
    final isSW = selectedCircuit.circuitId.contains('SW');

    // Circuit bounding box:
    // SW: [756.2, 264.6, 38.3, 368.2]
    // NE: [1070.5, 285.5, 33.3, 377.3]
    final bbox = isSW
        ? const [756.2, 264.6, 38.3, 368.2]
        : const [1070.5, 285.5, 33.3, 377.3];

    final rect = Rect.fromLTWH(
      _toX(bbox[0]),
      _toY(bbox[1]),
      bbox[2] * scale,
      bbox[3] * scale,
    );

    // 1. Blue Bounding Box
    final borderPaint = Paint()
      ..color = const Color(0xFF1967D2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawRect(rect, borderPaint);

    // 2. Solid Blue Tag at bottom of box: Circuit_SW or Circuit_NE
    final tagText = selectedCircuit.circuitId;
    final tagPainter = TextPainter(
      text: TextSpan(
        text: tagText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tagBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rect.left - 6,
        rect.bottom - 4,
        tagPainter.width + 12,
        tagPainter.height + 6,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(tagBgRect, Paint()..color = const Color(0xFF1967D2));
    tagPainter.paint(canvas, Offset(rect.left, rect.bottom - 1));

    // 3. Phase indicators dynamically positioned for the selected circuit
    final double yR;
    final double yY;
    final double yB;
    final double nodeX;
    final double letterX;

    if (isSW) {
      // SW arm insulator positions
      nodeX = _toX(775.35);
      letterX = nodeX - 22;
      yR = _toY(295.0);
      yY = _toY(448.0);
      yB = _toY(600.0);
    } else {
      // NE arm insulator positions
      nodeX = _toX(1087.15);
      letterX = nodeX + 18;
      yR = _toY(289.7);
      yY = _toY(455.2);
      yB = _toY(593.9);
    }

    final isRSelected = selectedPhase?.phaseName == 'R';
    final isYSelected = selectedPhase?.phaseName == 'Y';
    final isBSelected = selectedPhase?.phaseName == 'B';

    // Derive phase defects dynamically from JSON inspection data
    final rHasDefect = selectedCircuit.phases['R']?.images.any((img) => img.hasDefect) ?? isSW;
    final yHasDefect = selectedCircuit.phases['Y']?.images.any((img) => img.hasDefect) ?? false;
    final bHasDefect = selectedCircuit.phases['B']?.images.any((img) => img.hasDefect) ?? isSW;

    // Phase R (Red Dot with white ring)
    _drawPhaseLetter(canvas, 'R', letterX, yR);
    _drawPhaseNode(
      canvas: canvas,
      center: Offset(nodeX, yR),
      isSelected: isRSelected,
      hasDefect: rHasDefect,
      dotColor: const Color(0xFFEF4444),
    );

    // Phase Y (Yellow Dot with white ring)
    _drawPhaseLetter(canvas, 'Y', letterX, yY);
    _drawPhaseNode(
      canvas: canvas,
      center: Offset(nodeX, yY),
      isSelected: isYSelected,
      hasDefect: yHasDefect,
      dotColor: const Color(0xFFEAB308),
    );

    // Phase B (Blue Dot with white ring)
    _drawPhaseLetter(canvas, 'B', letterX, yB);
    _drawPhaseNode(
      canvas: canvas,
      center: Offset(nodeX, yB),
      isSelected: isBSelected,
      hasDefect: bHasDefect,
      dotColor: const Color(0xFF2563EB),
    );
  }

  void _drawPhaseLetter(Canvas canvas, String letter, double x, double y) {
    final painter = TextPainter(
      text: TextSpan(
        text: letter,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(color: Colors.white, blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, Offset(x, y - (painter.height / 2)));
  }

  void _drawPhaseNode({
    required Canvas canvas,
    required Offset center,
    required bool isSelected,
    required bool hasDefect,
    required Color dotColor,
  }) {
    if (isSelected) {
      // Double circle highlight ring when selected
      canvas.drawCircle(
        center,
        13.5,
        Paint()
          ..color = dotColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      canvas.drawCircle(
        center,
        11.0,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    // Inner node solid circle
    canvas.drawCircle(
      center,
      8.5,
      Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill,
    );

    // White border around dot
    canvas.drawCircle(
      center,
      8.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Shoulder badge on the top right: red cross or green checkmark
    final badgeCenter = center + const Offset(6, -6);
    final badgeColor = hasDefect ? const Color(0xFFEF4444) : const Color(0xFF22C55E);

    canvas.drawCircle(
      badgeCenter,
      4.5,
      Paint()
        ..color = badgeColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      badgeCenter,
      4.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    final icon = hasDefect ? Icons.close : Icons.check;
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 5.5,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(badgeCenter.dx - iconPainter.width / 2, badgeCenter.dy - iconPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SelectiveTowerPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.selectedCircuit != selectedCircuit ||
        oldDelegate.selectedPhase != selectedPhase;
  }
}
