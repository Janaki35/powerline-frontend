import 'package:flutter/material.dart';
import '../models/inspection_model.dart';

class DetectionCanvas extends StatelessWidget {
  final InspectionImage image;
  final ComponentDetection? selectedDetection;
  final ValueChanged<ComponentDetection>? onDetectionTap;
  final bool showDetections;

  const DetectionCanvas({
    super.key,
    required this.image,
    this.selectedDetection,
    this.onDetectionTap,
    this.showDetections = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showDetections || image.allDetections.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final renderW = constraints.maxWidth;
        final renderH = constraints.maxHeight;

        // Calculate aspect ratio scale
        final imgW = image.imageWidth > 0 ? image.imageWidth.toDouble() : 5184.0;
        final imgH = image.imageHeight > 0 ? image.imageHeight.toDouble() : 3888.0;

        final imgAspect = imgW / imgH;
        final renderAspect = renderW / renderH;

        double scale;
        double offsetX = 0;
        double offsetY = 0;

        if (renderAspect > imgAspect) {
          // Limited by height
          scale = renderH / imgH;
          offsetX = (renderW - imgW * scale) / 2;
        } else {
          // Limited by width
          scale = renderW / imgW;
          offsetY = (renderH - imgH * scale) / 2;
        }

        // Track which component types have already had a label rendered
        // to prevent 16 duplicate labels for conductor as per Penpot design
        final Set<String> labeledTypes = {};
        final List<Widget> detectionWidgets = [];

        for (final det in image.allDetections) {
          final isSelected = selectedDetection?.detectionId == det.detectionId;
          final isDefect = det.isDefect;

          final rect = det.rect;
          final left = offsetX + rect.left * scale;
          final top = offsetY + rect.top * scale;
          final width = rect.width * scale;
          final height = rect.height * scale;

          // Determine tag color matching 3.png
          Color tagColor;
          String label = det.displayName;
          String compKey = det.componentType;

          if (isDefect || det.componentType == 'cotter_pin_missing') {
            tagColor = const Color(0xFFDB322E); // Red
            label = 'Cotter pin missing';
            compKey = 'cotter_pin_missing';
          } else if (det.componentType.contains('arcing')) {
            tagColor = const Color(0xFF00838F); // Dark Cyan
            compKey = 'arcing_horn';
            final count = image.componentDetections[compKey]?.length ?? 1;
            label = count > 1 ? 'Arcing horn × $count' : 'Arcing horn';
          } else if (det.componentType.contains('insulator')) {
            tagColor = const Color(0xFF2E7D32); // Forest Green
            compKey = 'insulator';
            final count = image.componentDetections[compKey]?.length ?? 1;
            label = count > 1 ? 'Insulator × $count' : 'Insulator';
          } else if (det.componentType.contains('corona')) {
            tagColor = const Color(0xFF0097A7); // Teal
            compKey = 'corona_ring';
            final count = image.componentDetections[compKey]?.length ?? 1;
            label = count > 1 ? 'Corona ring × $count' : 'Corona ring';
          } else if (det.componentType.contains('conductor')) {
            tagColor = const Color(0xFF00838F); // Cyan
            compKey = 'conductor';
            final count = image.componentDetections[compKey]?.length ?? 1;
            label = count > 1 ? 'Conductor × $count' : 'Conductor';
          } else if (det.componentType.contains('damper')) {
            tagColor = const Color(0xFF1565C0); // Deep Blue
            compKey = 'vibration_damper';
            final count = image.componentDetections[compKey]?.length ?? 1;
            label = count > 1 ? 'Vibration damper × $count' : 'Vibration damper';
          } else if (det.componentType == 'cotter_pin') {
            tagColor = const Color(0xFF16A34A); // Normal Green
            compKey = 'cotter_pin';
            final count = image.componentDetections[compKey]?.length ?? 1;
            label = count > 1 ? 'Cotter pin × $count' : 'Cotter pin';
          } else {
            tagColor = const Color(0xFF2E7D32);
          }

          // Show label for defects or the first instance of each component type
          final bool shouldShowLabel = isDefect || !labeledTypes.contains(compKey);
          if (shouldShowLabel) {
            labeledTypes.add(compKey);
          }

          detectionWidgets.add(
            Positioned(
              left: left,
              top: top,
              width: width.clamp(14.0, renderW),
              height: height.clamp(14.0, renderH),
              child: GestureDetector(
                onTap: () => onDetectionTap?.call(det),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.white : tagColor,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      color: isSelected
                          ? tagColor.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                    child: shouldShowLabel
                        ? Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Label pill pinned to top-left of bounding box matching 3.png
                              Positioned(
                                top: -18,
                                left: -1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tagColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
            ),
          );
        }

        return Stack(children: detectionWidgets);
      },
    );
  }
}
