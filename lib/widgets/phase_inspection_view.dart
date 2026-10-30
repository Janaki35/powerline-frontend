import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/inspection_model.dart';
import '../services/image_service.dart';
import 'detailed_crops_carousel.dart';
import 'detection_canvas.dart';

class PhaseInspectionView extends StatefulWidget {
  final Phase? phase;
  final Circuit? circuit;
  // Asset type: 'Earthing peak' or 'Circuit'
  final String? selectedAssetType;
  // Currently selected earthing peak
  final EarthPeak? earthPeak;

  const PhaseInspectionView({
    super.key,
    this.phase,
    this.circuit,
    this.selectedAssetType,
    this.earthPeak,
  });

  @override
  State<PhaseInspectionView> createState() => _PhaseInspectionViewState();
}

class _PhaseInspectionViewState extends State<PhaseInspectionView> {
  // Start at image 0 (1st image)
  int _currentImageIndex = 0;
  ComponentDetection? _selectedDetection;
  final bool _showDetections = true;
  final TransformationController _transformController = TransformationController();
  double _cropsFraction = 0.45;
  bool _isDraggingDivider = false;

  // Active list of inspection images based on current asset selection
  List<InspectionImage> get _currentImages {
    if (widget.selectedAssetType == 'Earthing peak') {
      return widget.earthPeak?.images ?? [];
    }
    return widget.phase?.images ?? [];
  }

  @override
  void initState() {
    super.initState();
    _clampImageIndex();
  }

  @override
  void didUpdateWidget(covariant PhaseInspectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isEarthing = widget.selectedAssetType == 'Earthing peak';
    final wasEarthing = oldWidget.selectedAssetType == 'Earthing peak';

    // Reset image index when switching between assets, phases, or earth peaks
    if (isEarthing != wasEarthing ||
        (isEarthing && oldWidget.earthPeak?.earthPeakId != widget.earthPeak?.earthPeakId) ||
        (!isEarthing && (oldWidget.phase?.phaseName != widget.phase?.phaseName ||
            oldWidget.circuit?.circuitId != widget.circuit?.circuitId))) {
      _currentImageIndex = 0;
      _clampImageIndex();
      _selectedDetection = null;
      _transformController.value = Matrix4.identity();
    }
  }

  void _clampImageIndex() {
    final images = _currentImages;
    if (images.isEmpty) {
      _currentImageIndex = 0;
    } else if (_currentImageIndex >= images.length) {
      _currentImageIndex = images.length - 1;
    } else if (_currentImageIndex < 0) {
      _currentImageIndex = 0;
    }
  }

  void _nextImage() {
    final images = _currentImages;
    if (_currentImageIndex < images.length - 1) {
      setState(() {
        _currentImageIndex++;
        _selectedDetection = null;
        _transformController.value = Matrix4.identity();
      });
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
        _selectedDetection = null;
        _transformController.value = Matrix4.identity();
      });
    }
  }

  // Formats ISO timestamps like '2026-03-28T16:06:33' into '28 Mar 2026, 16:06:33' matching earthingpeak.png
  String _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final day = dt.day;
        final mon = months[dt.month - 1];
        final yr = dt.year;
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        final s = dt.second.toString().padLeft(2, '0');
        return '$day $mon $yr, $h:$m:$s';
      }
    } catch (_) {}
    return raw.replaceAll('T', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final isEarthing = widget.selectedAssetType == 'Earthing peak';

    // 1. EMPTY STATE FOR EARTHING PEAK (WHEN NO EARTH POINT IS SELECTED)
    if (isEarthing && widget.earthPeak == null) {
      return Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Earth peak inspection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Images and component crops for the selected earth point',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Empty state placeholder
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          size: 42,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No earth point selected',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose an earth point in the Asset navigator or click on the\ntower structure to see the earth peak images and detailed crops.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. EMPTY STATE FOR PHASE (WHEN NO PHASE IS SELECTED)
    if (!isEarthing && widget.phase == null) {
      return Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Phase inspection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Images and component crops for the selected phase',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          size: 42,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No phase selected',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose an asset type, circuit and phase in the Asset\nnavigator to see the phase images and detailed crops.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final images = _currentImages;
    if (images.isEmpty) {
      return Center(
        child: Text(
          isEarthing
              ? 'No inspection images available for this earth point'
              : 'No inspection images available for this phase',
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    _clampImageIndex();
    final currentImage = images[_currentImageIndex];

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header matching earthingpeak.png
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isEarthing ? 'Earth peak inspection' : 'Phase inspection',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Badge: Teal badge for Earthing peak, colored badge for Phase
                    if (isEarthing)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E9AA7), // Teal badge matching earthingpeak.png
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.earthPeak!.earthPeakId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.phase!.phaseName == 'Y'
                              ? const Color(0xFFEAB308)
                              : widget.phase!.phaseName == 'B'
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFDB322E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Phase-${widget.phase!.phaseName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  // Image counter (e.g. Image 1 of 10) placed under the phase inspection
                  Text(
                    'Image ${_currentImageIndex + 1} of ${images.length}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Middle & Bottom Area with Draggable Divider
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalH = constraints.maxHeight;
                const dividerH = 20.0;
                final availableH = math.max(100.0, totalH - dividerH);

                // Fraction clamped between 0.18 and 0.80
                final clampedFraction = _cropsFraction.clamp(0.18, 0.80);
                final cropsH = availableH * clampedFraction;
                final topH = availableH - cropsH;

                return Column(
                  children: [
                    // Main Drone Image Card Area
                    SizedBox(
                      height: topH,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  // Centered Drone Image
                                  Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 10,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            // Base Image
                                            ImageService.buildImage(
                                              imagePath: currentImage.imagePath,
                                              fit: BoxFit.contain,
                                            ),
                                            // Bounding Boxes Overlay
                                            DetectionCanvas(
                                              image: currentImage,
                                              selectedDetection: _selectedDetection,
                                              showDetections: _showDetections,
                                              onDetectionTap: (det) {
                                                setState(() => _selectedDetection = det);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Left Arrow Button (<)
                                  Positioned(
                                    left: 4,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.12),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.chevron_left, size: 20, color: Color(0xFF1E293B)),
                                          onPressed: _currentImageIndex > 0 ? _previousImage : null,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Right Arrow Button (>)
                                  Positioned(
                                    right: 4,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.12),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF1E293B)),
                                          onPressed: _currentImageIndex < images.length - 1
                                              ? _nextImage
                                              : null,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Image Telemetry Caption matching earthingpeak.png
                            Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 4),
                              child: Text(
                                [
                                  currentImage.filename,
                                  if (currentImage.telemetry?.capturedAt.isNotEmpty ?? false)
                                    _formatTimestamp(currentImage.telemetry!.capturedAt),
                                  if (currentImage.distanceToTowerM > 0)
                                    '${currentImage.distanceToTowerM.toStringAsFixed(1)} m from tower',
                                ].join(' · '),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF475569),
                                  fontFamily: 'monospace',
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Draggable Divider Bar with Grip Handle
                    _buildDraggableDivider(availableH),

                    // Bottom Detailed Crops Section
                    SizedBox(
                      height: cropsH,
                      child: DetailedCropsCarousel(
                        image: currentImage,
                        phase: isEarthing ? null : widget.phase,
                        selectedDetection: _selectedDetection,
                        onSelectDetection: (det) {
                          setState(() => _selectedDetection = det);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDraggableDivider(double availableH) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => setState(() => _isDraggingDivider = true),
        onVerticalDragEnd: (_) => setState(() => _isDraggingDivider = false),
        onVerticalDragCancel: () => setState(() => _isDraggingDivider = false),
        onDoubleTap: () {
          // Double-click toggle between expanded (80%) and default (45%)
          setState(() {
            _cropsFraction = _cropsFraction > 0.60 ? 0.45 : 0.80;
          });
        },
        onVerticalDragUpdate: (details) {
          if (availableH <= 0) return;
          final deltaFraction = details.delta.dy / availableH;
          setState(() {
            _cropsFraction = (_cropsFraction - deltaFraction).clamp(0.18, 0.80);
          });
        },
        child: SizedBox(
          height: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Horizontal divider line
              const Positioned(
                left: 0,
                right: 0,
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE2E8F0),
                ),
              ),

              // Grip Pill Handle in the middle
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _isDraggingDivider ? 56 : 48,
                height: _isDraggingDivider ? 7 : 5,
                decoration: BoxDecoration(
                  color: _isDraggingDivider
                      ? const Color(0xFF1967D2)
                      : const Color(0xFF94A3B8),
                  borderRadius: BorderRadius.circular(3.5),
                  boxShadow: [
                    BoxShadow(
                      color: (_isDraggingDivider ? const Color(0xFF1967D2) : Colors.black)
                          .withValues(alpha: _isDraggingDivider ? 0.35 : 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 1.5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
