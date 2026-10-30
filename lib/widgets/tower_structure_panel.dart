import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/inspection_model.dart';
import '../services/image_service.dart';
import '../services/tower_registry.dart';

class TowerStructurePanel extends StatefulWidget {
  final Tower tower;
  final String? selectedAssetType; // 'Circuit', 'Earthing peak', or null
  final Circuit? selectedCircuit;
  final Phase? selectedPhase;
  // Currently selected earthing peak
  final EarthPeak? selectedEarthPeak;
  final ValueChanged<Circuit>? onSelectCircuit;
  final ValueChanged<Phase>? onSelectPhase;
  // Callback when user taps or selects an earthing peak
  final ValueChanged<EarthPeak>? onSelectEarthPeak;
  final double? width;

  const TowerStructurePanel({
    super.key,
    required this.tower,
    this.selectedAssetType,
    this.selectedCircuit,
    this.selectedPhase,
    this.selectedEarthPeak,
    this.onSelectCircuit,
    this.onSelectPhase,
    this.onSelectEarthPeak,
    this.width,
  });

  @override
  State<TowerStructurePanel> createState() => _TowerStructurePanelState();
}

class _TowerStructurePanelState extends State<TowerStructurePanel> {
  @override
  Widget build(BuildContext context) {
    final hasSelectedCircuit = widget.selectedCircuit != null;

    final towerDef = TowerRegistry.getTower(widget.tower.towerId);
    final imagePath = towerDef?.baseImageAsset ?? AppConfig.baseTowerImageAsset;
    final voltageText = towerDef?.voltage ?? '400 kV';
    final siteText = towerDef?.site ?? 'Site B';
    final is135 = voltageText.contains('135') ||
        widget.tower.towerId.contains('135') ||
        widget.tower.towerName.contains('135');
    final towerType = widget.tower.summary.circuitCount == 1
        ? (is135 ? 'Single circuit - Tension' : 'Single circuit - Suspension')
        : (is135 ? 'Double circuit - Tension' : 'Double circuit - Suspension');

    // Dynamic crop calculation from tower bounding box
    final det = widget.tower.towerDetection;
    final bbox = det.bbox;
    final double rawW = det.imageWidth > 0 ? det.imageWidth.toDouble() : 1920.0;
    final double rawH = det.imageHeight > 0 ? det.imageHeight.toDouble() : 1080.0;

    final double bx = bbox.isNotEmpty ? bbox[0] : 0.0;
    final double by = bbox.length > 1 ? bbox[1] : 0.0;
    final double bw = bbox.length > 2 ? bbox[2] : rawW;
    final double bh = bbox.length > 3 ? bbox[3] : rawH;

    final double padH = (bw * 0.45).clamp(60.0, rawW);
    final double padV = (bh * 0.08).clamp(30.0, rawH);
    final double cropLeft = (bx - padH).clamp(0.0, rawW);
    final double cropTop = (by - padV).clamp(0.0, rawH);
    final double cropWidth = (bw + 2 * padH).clamp(100.0, rawW - cropLeft);
    final double cropHeight = (bh + 2 * padV).clamp(100.0, rawH - cropTop);

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
                // Title and voltage/site subtitle
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
                          '${towerDef?.displayCode ?? widget.tower.towerId} · $voltageText · $siteText',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    // RGB / Thermal static toggle button matching earthingpeak.png
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B6BCB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'RGB',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Thermal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Metadata Row: STRUCTURE, TOWER TYPE
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    const Column(
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
                        const Text(
                          'TOWER TYPE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          towerType,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Subtitle label: WHOLE TOWER, SELECTED EARTH POINT, or SELECTED CIRCUIT
                if (widget.selectedAssetType == 'Earthing peak')
                  if (widget.selectedEarthPeak != null)
                    Row(
                      children: [
                        const Text(
                          'SELECTED EARTH POINT',
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
                            color: const Color(0xFF0E9AA7), // Teal badge matching earthingpeak.png
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.selectedEarthPeak!.earthPeakId,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'WHOLE TOWER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                        letterSpacing: 0.5,
                      ),
                    )
                else if (!hasSelectedCircuit)
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
                          (widget.tower.summary.circuitCount == 1 || widget.tower.circuits.length == 1)
                              ? 'Circuit'
                              : widget.selectedCircuit!.circuitId,
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

                    final scaleX = boxW / cropWidth;
                    final scaleY = boxH / cropHeight;
                    final scale = scaleX < scaleY ? scaleX : scaleY;

                    final renderW = cropWidth * scale;
                    final renderH = cropHeight * scale;

                    return Center(
                      child: SizedBox(
                        width: renderW,
                        height: renderH,
                        child: GestureDetector(
                          // Tap detection: allows user to select earthing peak directly on the tower
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) {
                            if (widget.selectedAssetType == 'Earthing peak') {
                              final tapX = details.localPosition.dx;
                              final tapY = details.localPosition.dy;
                              for (final ep in widget.tower.earthPeaks) {
                                double nodeX;
                                double nodeY;
                                if (ep.keypoint != null) {
                                  nodeX = (ep.keypoint!.x - cropLeft) * scale;
                                  nodeY = (ep.keypoint!.y - cropTop) * scale;
                                } else {
                                  // Fallback coordinates if keypoint is missing
                                  final double baseBx = bbox.isNotEmpty ? bbox[0] : 760.0;
                                  final double baseBy = bbox.length > 1 ? bbox[1] : 180.0;
                                  final double baseBw = bbox.length > 2 ? bbox[2] : 340.0;
                                  final isLeft = ep.side.contains('SW') || ep.side.contains('W');
                                  nodeX = ((isLeft ? baseBx + 60 : baseBx + baseBw - 60) - cropLeft) * scale;
                                  nodeY = (baseBy - cropTop) * scale;
                                }

                                final bool isLeft = ep.side.contains('SW') || ep.side.contains('W');
                                final double labelX = isLeft ? nodeX - 28 : nodeX + 20;

                                // Check tap distance to node or to side label
                                final distToNodeSq = (tapX - nodeX) * (tapX - nodeX) + (tapY - nodeY) * (tapY - nodeY);
                                final distToLabelSq = (tapX - labelX) * (tapX - labelX) + (tapY - nodeY) * (tapY - nodeY);

                                if (distToNodeSq <= 36 * 36 || distToLabelSq <= 26 * 26) {
                                  widget.onSelectEarthPeak?.call(ep);
                                  break;
                                }
                              }
                            }
                          },
                          child: Stack(
                            children: [
                              // 1. Cropped & Scaled Base Tower Photo
                              Positioned(
                                left: -cropLeft * scale,
                                top: -cropTop * scale,
                                width: rawW * scale,
                                height: rawH * scale,
                                child: ImageService.buildImage(
                                  imagePath: imagePath,
                                  fit: BoxFit.fill,
                                ),
                              ),

                              // 2. Highlighting Earthing Peaks when Earthing Peak asset type is selected
                              if (widget.selectedAssetType == 'Earthing peak')
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _EarthPeakTowerPainter(
                                      scale: scale,
                                      cropLeft: cropLeft,
                                      cropTop: cropTop,
                                      towerBbox: bbox,
                                      earthPeaks: widget.tower.earthPeaks,
                                      selectedEarthPeak: widget.selectedEarthPeak,
                                    ),
                                  ),
                                )
                              // 3. Highlighting circuit and phases when circuit is selected
                              else if (hasSelectedCircuit)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _SelectiveTowerPainter(
                                      scale: scale,
                                      cropLeft: cropLeft,
                                      cropTop: cropTop,
                                      towerBbox: bbox,
                                      selectedCircuit: widget.selectedCircuit!,
                                      selectedPhase: widget.selectedPhase,
                                      isSingleCircuit: widget.tower.summary.circuitCount == 1 ||
                                          widget.tower.circuits.length == 1,
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

          // Legend under Tower Image matching earthingpeak.png
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
                // Row 1: EARTH POINT (when Earthing peak is selected) or PHASE
                if (widget.selectedAssetType == 'Earthing peak')
                  Row(
                    children: [
                      const Text(
                        'EARTH POINT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 14),
                      for (final ep in widget.tower.earthPeaks) ...[
                        _buildDot(ep.side, const Color(0xFF0E9AA7)),
                        const SizedBox(width: 10),
                      ],
                    ],
                  )
                else
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
  final double cropLeft;
  final double cropTop;
  final List<double> towerBbox;
  final Circuit selectedCircuit;
  final Phase? selectedPhase;
  final bool isSingleCircuit;

  _SelectiveTowerPainter({
    required this.scale,
    required this.cropLeft,
    required this.cropTop,
    required this.towerBbox,
    required this.selectedCircuit,
    required this.selectedPhase,
    this.isSingleCircuit = false,
  });

  double _toX(double x) => (x - cropLeft) * scale;
  double _toY(double y) => (y - cropTop) * scale;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Circuit bounding box (use selectedCircuit.bbox if available)
    final cb = selectedCircuit.bbox;
    Rect? circuitRect;
    if (cb.length >= 4 && cb[2] > 0 && cb[3] > 0) {
      circuitRect = Rect.fromLTWH(
        _toX(cb[0]),
        _toY(cb[1]),
        cb[2] * scale,
        cb[3] * scale,
      );
    } else {
      // Fallback if circuit bbox is empty
      final isSW = selectedCircuit.circuitId.contains('SW');
      final fallbackBbox = isSW
          ? const [756.2, 264.6, 38.3, 368.2]
          : const [1070.5, 285.5, 33.3, 377.3];
      circuitRect = Rect.fromLTWH(
        _toX(fallbackBbox[0]),
        _toY(fallbackBbox[1]),
        fallbackBbox[2] * scale,
        fallbackBbox[3] * scale,
      );
    }

    // 1. Blue Bounding Box
    final borderPaint = Paint()
      ..color = const Color(0xFF1967D2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawRect(circuitRect, borderPaint);

    // 2. Solid Blue Tag at bottom of box
    final tagText = isSingleCircuit ? 'Circuit' : selectedCircuit.circuitId;
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
        circuitRect.left - 6,
        circuitRect.bottom - 4,
        tagPainter.width + 12,
        tagPainter.height + 6,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(tagBgRect, Paint()..color = const Color(0xFF1967D2));
    tagPainter.paint(canvas, Offset(circuitRect.left, circuitRect.bottom - 1));

    // 3. Phase indicators dynamically positioned for the selected circuit
    final double towerCenterX = towerBbox.length >= 3
        ? _toX(towerBbox[0] + towerBbox[2] / 2.0)
        : size.width / 2.0;

    final phases = selectedCircuit.phases;

    void drawPhase(String name, Color dotColor, double defaultXOffset, double defaultYFrac) {
      final p = phases[name];
      double nodeX;
      double nodeY;

      if (p?.keypoint != null) {
        nodeX = _toX(p!.keypoint!.x);
        nodeY = _toY(p.keypoint!.y);
      } else {
        // Fallback positioning based on circuit and arm
        final isLeft = selectedCircuit.circuitId.contains('SW') ||
            selectedCircuit.circuitId.contains('NW') ||
            selectedCircuit.circuitId.contains('W') ||
            selectedCircuit.circuitId.contains('S');
        final double baseBx = towerBbox.isNotEmpty ? towerBbox[0] : 760.0;
        final double baseBy = towerBbox.length > 1 ? towerBbox[1] : 180.0;
        final double baseBw = towerBbox.length > 2 ? towerBbox[2] : 340.0;
        final double baseBh = towerBbox.length > 3 ? towerBbox[3] : 720.0;
        nodeX = isLeft ? _toX(baseBx + defaultXOffset) : _toX(baseBx + baseBw - defaultXOffset);
        nodeY = _toY(baseBy + baseBh * defaultYFrac);
      }

      final letterX = nodeX < towerCenterX ? nodeX - 22 : nodeX + 18;
      final isSelected = selectedPhase?.phaseName == name;
      final hasDefect = (p != null) ? p.defectCount > 0 : false;

      _drawPhaseLetter(canvas, name, letterX, nodeY);
      _drawPhaseNode(
        canvas: canvas,
        center: Offset(nodeX, nodeY),
        isSelected: isSelected,
        hasDefect: hasDefect,
        dotColor: dotColor,
      );
    }

    drawPhase('R', const Color(0xFFEF4444), 15.0, 0.20);
    drawPhase('Y', const Color(0xFFEAB308), 20.0, 0.40);
    drawPhase('B', const Color(0xFF2563EB), 22.0, 0.60);
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
        oldDelegate.cropLeft != cropLeft ||
        oldDelegate.cropTop != cropTop ||
        oldDelegate.selectedCircuit != selectedCircuit ||
        oldDelegate.selectedPhase != selectedPhase;
  }
}

/// Painter that draws earthing peaks and highlight circles on the tower structure
class _EarthPeakTowerPainter extends CustomPainter {
  final double scale;
  final double cropLeft;
  final double cropTop;
  final List<double> towerBbox;
  final List<EarthPeak> earthPeaks;
  final EarthPeak? selectedEarthPeak;

  _EarthPeakTowerPainter({
    required this.scale,
    required this.cropLeft,
    required this.cropTop,
    required this.towerBbox,
    required this.earthPeaks,
    required this.selectedEarthPeak,
  });

  double _toX(double x) => (x - cropLeft) * scale;
  double _toY(double y) => (y - cropTop) * scale;

  @override
  void paint(Canvas canvas, Size size) {
    // Teal color matching earthingpeak.png
    const tealColor = Color(0xFF0E9AA7);

    for (final ep in earthPeaks) {
      double nodeX;
      double nodeY;

      if (ep.keypoint != null) {
        nodeX = _toX(ep.keypoint!.x);
        nodeY = _toY(ep.keypoint!.y);
      } else {
        // Fallback positioning at top of tower if keypoint coordinate is missing
        final double baseBx = towerBbox.isNotEmpty ? towerBbox[0] : 760.0;
        final double baseBy = towerBbox.length > 1 ? towerBbox[1] : 180.0;
        final double baseBw = towerBbox.length > 2 ? towerBbox[2] : 340.0;
        final isLeft = ep.side.contains('SW') || ep.side.contains('W');
        nodeX = isLeft ? _toX(baseBx + 60) : _toX(baseBx + baseBw - 60);
        nodeY = _toY(baseBy);
      }

      final isSelected = selectedEarthPeak?.earthPeakId == ep.earthPeakId;
      final hasDefect = ep.isCritical;

      // Draw side label (e.g. 'SW' to the left or 'NE' to the right of node)
      final bool isLeft = ep.side.contains('SW') || ep.side.contains('W');
      final double labelX = isLeft ? nodeX - 28 : nodeX + 20;
      _drawSideLabel(canvas, ep.side, labelX, nodeY);

      // Draw the circular node containing the letter 'E' and shoulder checkmark
      _drawEarthPeakNode(
        canvas: canvas,
        center: Offset(nodeX, nodeY),
        isSelected: isSelected,
        hasDefect: hasDefect,
        color: tealColor,
      );
    }
  }

  // Draws text label for side (like 'SW' or 'NE') with white drop-shadow for contrast
  void _drawSideLabel(Canvas canvas, String text, double x, double y) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
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

  // Draws the earthing peak node: teal circle with white 'E', green checkmark, and double ring when selected
  void _drawEarthPeakNode({
    required Canvas canvas,
    required Offset center,
    required bool isSelected,
    required bool hasDefect,
    required Color color,
  }) {
    // When selected: draw double outer highlight rings matching earthingpeak.png
    if (isSelected) {
      canvas.drawCircle(
        center,
        14.5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      canvas.drawCircle(
        center,
        12.0,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    // Inner solid teal circle
    canvas.drawCircle(
      center,
      9.0,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // White border around the circle
    canvas.drawCircle(
      center,
      9.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Letter 'E' inside circle (bold white)
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'E',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    // Shoulder badge on the top right (green circle with checkmark if normal)
    final badgeCenter = center + const Offset(6.5, -6.5);
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
  bool shouldRepaint(covariant _EarthPeakTowerPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.cropLeft != cropLeft ||
        oldDelegate.cropTop != cropTop ||
        oldDelegate.selectedEarthPeak != selectedEarthPeak ||
        oldDelegate.earthPeaks != earthPeaks;
  }
}
