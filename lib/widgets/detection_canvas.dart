import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/inspection_model.dart';

class _CanvasLabelItem {
  final Rect boxRect;
  final String text;
  final Color tagColor;
  final bool isDefect;
  final bool isSelected;
  final ComponentDetection detection;

  const _CanvasLabelItem({
    required this.boxRect,
    required this.text,
    required this.tagColor,
    required this.isDefect,
    required this.isSelected,
    required this.detection,
  });
}

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

        // Layer 1: All bounding boxes (rendered underneath labels so boxes never cover text)
        // Layer 2: All component labels (rendered on top with collision avoidance)
        final Set<String> labeledTypes = {};
        final List<Widget> boxWidgets = [];
        final List<_CanvasLabelItem> candidateLabels = [];

        for (final det in image.allDetections) {
          final isSelected = selectedDetection?.detectionId == det.detectionId;
          final isDefect = det.isDefect;

          final rect = det.rect;
          final left = offsetX + rect.left * scale;
          final top = offsetY + rect.top * scale;
          final width = (rect.width * scale).clamp(14.0, renderW);
          final height = (rect.height * scale).clamp(14.0, renderH);
          final boxRect = Rect.fromLTWH(left, top, width, height);

          // Determine tag color matching design system
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
          } else if (det.componentType.contains('jumper')) {
            tagColor = const Color(0xFF16A34A); // Medium Green
            compKey = 'jumper_cable';
            final count = image.componentDetections[compKey]?.length ?? 1;
            label = count > 1 ? 'Jumper cable × $count' : 'Jumper cable';
          } else if (det.componentType == 'cotter_pin') {
            tagColor = const Color(0xFF16A34A); // Normal Green
            compKey = 'cotter_pin';
            final count = image.componentDetections[compKey]?.length ?? 1;
            label = count > 1 ? 'Cotter pin × $count' : 'Cotter pin';
          } else {
            tagColor = const Color(0xFF2E7D32);
          }

          // Layer 1: Bounding box rectangle
          boxWidgets.add(
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
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
                  ),
                ),
              ),
            ),
          );

          // Show label for defects or the first instance of each component type
          final bool shouldShowLabel = isDefect || !labeledTypes.contains(compKey);
          if (shouldShowLabel) {
            labeledTypes.add(compKey);
            candidateLabels.add(
              _CanvasLabelItem(
                boxRect: boxRect,
                text: label,
                tagColor: tagColor,
                isDefect: isDefect,
                isSelected: isSelected,
                detection: det,
              ),
            );
          }
        }

        // Prioritize defects and selected items first so they get optimal placement
        candidateLabels.sort((a, b) {
          if (a.isDefect != b.isDefect) {
            return a.isDefect ? -1 : 1;
          }
          if (a.isSelected != b.isSelected) {
            return a.isSelected ? -1 : 1;
          }
          return a.boxRect.top.compareTo(b.boxRect.top);
        });

        // Layer 2: All labels rendered on top of all bounding boxes with collision avoidance
        final List<Rect> occupiedLabelRects = [];
        final List<Widget> labelWidgets = [];
        const double labelH = 19.0;
        final double minX = offsetX;
        final double maxX = offsetX + imgW * scale;
        final double minY = offsetY;
        final double maxY = offsetY + imgH * scale;

        bool isOverlapping(Rect testRect) {
          for (final occ in occupiedLabelRects) {
            if (testRect.overlaps(occ.inflate(2.0))) {
              return true;
            }
          }
          return false;
        }

        for (final item in candidateLabels) {
          final double labelW = (item.text.length * 6.3 + 14.0).clamp(38.0, 180.0).toDouble();

          // 1. Primary ideal placement: top of bounding box
          double targetX = item.boxRect.left;
          double targetY = item.boxRect.top - labelH - 1.0;

          // If top goes beyond upper image boundary, place inside top of box
          if (targetY < minY) {
            targetY = (item.boxRect.top + 2.0).clamp(minY, maxY - labelH).toDouble();
          }
          targetX = targetX.clamp(minX, math.max(minX, maxX - labelW)).toDouble();

          Rect candidateRect = Rect.fromLTWH(targetX, targetY, labelW, labelH);

          // 2. Collision resolution: avoid overlapping other labels
          if (isOverlapping(candidateRect)) {
            final conflicting = occupiedLabelRects.firstWhere(
              (r) => candidateRect.overlaps(r.inflate(2.0)),
              orElse: () => candidateRect,
            );

            // Strategy A: Place directly above conflicting label
            final aboveY = conflicting.top - labelH - 3.0;
            final aboveRect = Rect.fromLTWH(targetX, aboveY, labelW, labelH);

            // Strategy B: Shift to the right of conflicting label
            final rightX = (conflicting.right + 4.0).clamp(minX, math.max(minX, maxX - labelW)).toDouble();
            final rightRect = Rect.fromLTWH(rightX, targetY, labelW, labelH);

            // Strategy C: Place directly below conflicting label
            final belowY = conflicting.bottom + 3.0;
            final belowRect = Rect.fromLTWH(targetX, belowY, labelW, labelH);

            // Strategy D: Inside bottom of the box
            final insideBottomY = (item.boxRect.bottom - labelH - 2.0).clamp(minY, maxY - labelH).toDouble();
            final insideBottomRect = Rect.fromLTWH(targetX, insideBottomY, labelW, labelH);

            if (aboveY >= minY && !isOverlapping(aboveRect)) {
              candidateRect = aboveRect;
            } else if (rightX + labelW <= maxX && !isOverlapping(rightRect)) {
              candidateRect = rightRect;
            } else if (belowY + labelH <= maxY && !isOverlapping(belowRect)) {
              candidateRect = belowRect;
            } else if (!isOverlapping(insideBottomRect)) {
              candidateRect = insideBottomRect;
            } else {
              // Fallback: step down vertically until free space found
              double stepY = belowY;
              while (stepY + labelH <= maxY && isOverlapping(Rect.fromLTWH(targetX, stepY, labelW, labelH))) {
                stepY += labelH + 3.0;
              }
              candidateRect = Rect.fromLTWH(targetX, stepY.clamp(minY, maxY - labelH).toDouble(), labelW, labelH);
            }
          }

          occupiedLabelRects.add(candidateRect);

          labelWidgets.add(
            Positioned(
              left: candidateRect.left,
              top: candidateRect.top,
              child: GestureDetector(
                onTap: () => onDetectionTap?.call(item.detection),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.tagColor,
                      borderRadius: BorderRadius.circular(2.5),
                      border: Border.all(
                        color: item.isSelected ? Colors.white : Colors.white.withValues(alpha: 0.35),
                        width: item.isSelected ? 1.5 : 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 3,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Text(
                      item.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            ...boxWidgets,
            ...labelWidgets,
          ],
        );
      },
    );
  }
}
