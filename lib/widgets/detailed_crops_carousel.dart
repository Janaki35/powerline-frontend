import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/inspection_model.dart';
import '../services/image_service.dart';

class DetailedCropsCarousel extends StatefulWidget {
  final InspectionImage image;
  final Phase? phase;
  final ComponentDetection? selectedDetection;
  final ValueChanged<ComponentDetection>? onSelectDetection;

  const DetailedCropsCarousel({
    super.key,
    required this.image,
    this.phase,
    this.selectedDetection,
    this.onSelectDetection,
  });

  @override
  State<DetailedCropsCarousel> createState() => _DetailedCropsCarouselState();
}

class _DetailedCropsCarouselState extends State<DetailedCropsCarousel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant DetailedCropsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.imagePath != widget.image.imagePath) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    // Build display items dynamically from the current image's detections from JSON
    final List<Map<String, dynamic>> displayItems = [];

    // 1. Missing components / defects in this image (e.g. cotter_pin_missing)
    final missingDets = image.componentDetections['cotter_pin_missing'] ?? [];
    for (int i = 0; i < missingDets.length; i++) {
      final det = missingDets[i];
      displayItems.add({
        'label': missingDets.length > 1 ? 'Cotter pin missing (${i + 1})' : 'Cotter pin missing',
        'det': det,
        'imagePath': image.imagePath,
        'isDefect': true,
      });
    }

    // 2. Other component types detected in this image, matching PDF detailed crops order
    final standardOrder = [
      'conductor',
      'vibration_damper',
      'corona_ring',
      'insulator',
      'arcing_horn',
      'cotter_pin',
      'earthing_wire',
      'pg_clamp',
      'jumper_cable',
    ];

    for (final compType in standardOrder) {
      final dets = image.componentDetections[compType];
      if (dets != null && dets.isNotEmpty) {
        final count = dets.length;
        final compName = _formatCompName(compType);
        final label = count > 1 ? '$compName × $count' : compName;
        // Take the detection with highest confidence
        final bestDet = dets.reduce((a, b) => a.confidence >= b.confidence ? a : b);
        displayItems.add({
          'label': label,
          'det': bestDet,
          'imagePath': image.imagePath,
          'isDefect': false,
        });
      }
    }

    // Check any remaining component types
    for (final entry in image.componentDetections.entries) {
      if (entry.key == 'cotter_pin_missing' || standardOrder.contains(entry.key)) continue;
      final dets = entry.value;
      if (dets.isNotEmpty) {
        final count = dets.length;
        final compName = _formatCompName(entry.key);
        final label = count > 1 ? '$compName × $count' : compName;
        final bestDet = dets.reduce((a, b) => a.confidence >= b.confidence ? a : b);
        displayItems.add({
          'label': label,
          'det': bestDet,
          'imagePath': image.imagePath,
          'isDefect': false,
        });
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header matching 3.png
          const Text(
            'Detailed crops',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Components inspected in this image',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          // Responsive Grid (3 columns on desktop, 2 on tablet/mobile, 1 on very narrow)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Reserve 16px channel width for the scrollbar so cards never overlap it
                const scrollbarChannelWidth = 16.0;
                final availableWidth = math.max(0.0, constraints.maxWidth - scrollbarChannelWidth);

                final crossAxisCount = availableWidth >= 620
                    ? 3
                    : (availableWidth >= 340 ? 2 : 1);
                final itemWidth = ((availableWidth - (crossAxisCount - 1) * 12) / crossAxisCount).floorToDouble();

                if (displayItems.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No component detections in this image',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }

                return ScrollbarTheme(
                  data: ScrollbarThemeData(
                    thumbVisibility: const WidgetStatePropertyAll(true),
                    trackVisibility: const WidgetStatePropertyAll(true),
                    thickness: const WidgetStatePropertyAll(8.0),
                    radius: const Radius.circular(4),
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.dragged)) {
                        return const Color(0xFF1E293B);
                      }
                      if (states.contains(WidgetState.hovered)) {
                        return const Color(0xFF334155);
                      }
                      return const Color(0xFF64748B); // Distinct, sharp slate-grey thumb!
                    }),
                    trackColor: const WidgetStatePropertyAll(Color(0xFFF1F5F9)),
                    trackBorderColor: const WidgetStatePropertyAll(Color(0xFFE2E8F0)),
                  ),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    interactive: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(right: 14, bottom: 12),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: displayItems.map((item) {
                          return SizedBox(
                            width: itemWidth,
                            child: _buildCropCard(item),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard(Map<String, dynamic> item) {
    final String label = item['label'];
    final ComponentDetection det = item['det'];
    final String itemImagePath = item['imagePath'] ?? widget.image.imagePath;
    final bool isDefect = item['isDefect'] ?? det.isDefect;
    final isSelected = widget.selectedDetection?.detectionId == det.detectionId;

    return InkWell(
      onTap: () => widget.onSelectDetection?.call(det),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFF1967D2), width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label Row with optional DEFECT badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDefect ? const Color(0xFFDB322E) : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDefect)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'DEFECT',
                      style: TextStyle(
                        color: Color(0xFFDB322E),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Image Crop Thumbnail with bounding box drawn on it
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 118,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  border: Border.all(
                    color: isDefect ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                    width: isDefect ? 1.5 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ImageService.buildCropImage(
                  imagePath: itemImagePath,
                  bbox: det.bbox,
                  isDefect: isDefect,
                  label: isDefect ? label : null,
                  compType: det.componentType,
                  drawBox: isDefect,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCompName(String key) {
    switch (key) {
      case 'conductor':
        return 'Conductor';
      case 'vibration_damper':
        return 'Vibration damper';
      case 'corona_ring':
        return 'Corona ring';
      case 'insulator':
        return 'Insulator';
      case 'arcing_horn':
        return 'Arcing horn';
      case 'cotter_pin':
        return 'Cotter pin';
      case 'earthing_wire':
        return 'Earthing wire';
      case 'pg_clamp':
        return 'PG clamp';
      case 'jumper_cable':
        return 'Jumper cable';
      case 'cotter_pin_missing':
        return 'Cotter pin missing';
      default:
        return key.replaceAll('_', ' ');
    }
  }
}

