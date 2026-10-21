import 'package:flutter/material.dart';
import '../config/app_config.dart';

// Conditional import: on desktop platforms uses dart:io FileImage, on web uses NetworkImage
import 'image_loader_stub.dart'
    if (dart.library.io) 'image_loader_desktop.dart'
    if (dart.library.html) 'image_loader_web.dart';

class ImageService {
  /// Cleans the relative path coming from the JSON (supports S3 URLs, local paths, and prefixes)
  static String cleanPath(String rawPath) {
    var p = rawPath.trim();
    final uri = Uri.tryParse(p);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      p = uri.path;
      if (p.startsWith('/')) {
        p = p.substring(1);
      }
    }
    if (p.startsWith('data/')) {
      p = p.substring('data/'.length);
    }
    if (p.startsWith('towers/')) {
      p = p.substring('towers/'.length);
    }
    if (p.startsWith('corrected_earth_peak/')) {
      p = p.substring('corrected_earth_peak/'.length);
    }
    return p.replaceAll('\\', '/');
  }

  /// URL for the HTTP server (for web or network fallback)
  static String getHttpUrl(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final cleaned = cleanPath(rawPath);
    return '${AppConfig.imageServerBaseUrl}/$cleaned';
  }

  /// URL for server-side cropped bounding box with defect and label rendering
  static String getCropUrl(
    String rawPath,
    List<double> bbox, {
    bool isDefect = false,
    String? label,
    String? compType,
    bool drawBox = true,
  }) {
    final cleaned = cleanPath(rawPath);
    final x = bbox.isNotEmpty ? bbox[0] : 0.0;
    final y = bbox.length > 1 ? bbox[1] : 0.0;
    final w = bbox.length > 2 ? bbox[2] : 100.0;
    final h = bbox.length > 3 ? bbox[3] : 100.0;

    var url = '${AppConfig.imageServerBaseUrl}/crop?path=$cleaned&x=$x&y=$y&w=$w&h=$h';
    if (drawBox) {
      url += '&draw_box=1';
    } else {
      url += '&draw_box=0';
    }
    if (isDefect) {
      url += '&is_defect=1';
    }
    if (label != null && label.isNotEmpty) {
      url += '&label=${Uri.encodeComponent(label)}';
    }
    if (compType != null && compType.isNotEmpty) {
      url += '&comp_type=${Uri.encodeComponent(compType)}';
    }
    return url;
  }

  /// Returns appropriate ImageProvider for Web vs Windows Desktop
  static ImageProvider getImageProvider(String rawPath) {
    final clean = cleanPath(rawPath);

    // 1. Check for explicit asset paths
    if (rawPath.startsWith('assets/') || clean.startsWith('assets/')) {
      return AssetImage(rawPath.startsWith('assets/') ? rawPath : clean);
    }

    // 2. Check for bundled base tower overview images for deployment reliability
    const towerBaseAssets = {
      'DJI_20260328161505_0088_S_seg01_frame_01180.jpg':
          'assets/images/DJI_20260328161505_0088_S_seg01_frame_01180.jpg',
      '135_t1.jpg': 'assets/images/135_t1.jpg',
      'frame_00969.jpg': 'assets/images/135_t1.jpg',
      '135t2.jpg': 'assets/images/135t2.jpg',
      'frame_00063.jpg': 'assets/images/135t2.jpg',
      '220t1sa.jpg': 'assets/images/220t1sa.jpg',
      'frame_00506.jpg': 'assets/images/220t1sa.jpg',
      '220t2sa.jpg': 'assets/images/220t2sa.jpg',
      'frame_00946.jpg': 'assets/images/220t2sa.jpg',
      '220t1sb.jpg': 'assets/images/220t1sb.jpg',
      'frame_01342.jpg': 'assets/images/220t1sb.jpg',
      '220t2sb.jpg': 'assets/images/220t2sb.jpg',
      'frame_00138.jpg': 'assets/images/220t2sb.jpg',
    };

    for (final entry in towerBaseAssets.entries) {
      if (clean.endsWith(entry.key) || clean.contains(entry.key)) {
        return AssetImage(entry.value);
      }
    }

    // 3. Fallback to platform-specific provider (local file on desktop, HTTP on web)
    final httpUrl = getHttpUrl(rawPath);
    return getPlatformImageProvider(rawPath, httpUrl, AppConfig.rawDataLocalPath);
  }

  /// Builds a robust image widget with loading indicator and graceful error fallback
  static Widget buildImage({
    required String imagePath,
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
    Alignment alignment = Alignment.center,
    FilterQuality filterQuality = FilterQuality.medium,
  }) {
    return Image(
      image: getImageProvider(imagePath),
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      filterQuality: filterQuality,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final total = progress.expectedTotalBytes;
        final loaded = progress.cumulativeBytesLoaded;
        return Container(
          width: width,
          height: height,
          color: const Color(0xFF0F172A),
          child: Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                value: total != null ? loaded / total : null,
                strokeWidth: 2.5,
                color: Colors.white70,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: const Color(0xFF1E293B),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_outlined, color: Colors.white38, size: 40),
              const SizedBox(height: 8),
              Text(
                imagePath.split('/').last,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Text(
                'Available via local image server (port 8085)',
                style: TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a cropped component thumbnail image
  static Widget buildCropImage({
    required String imagePath,
    required List<double> bbox,
    bool isDefect = false,
    String? label,
    String? compType,
    bool drawBox = true,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (bbox.length < 4 || bbox[2] <= 0 || bbox[3] <= 0) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFF1E293B),
        child: const Center(
          child: Icon(Icons.crop_original, color: Colors.white38, size: 24),
        ),
      );
    }

    return ClientSideCropWidget(
      imagePath: imagePath,
      bbox: bbox,
      isDefect: isDefect,
      label: label,
      compType: compType,
      drawBox: drawBox,
      width: width,
      height: height,
    );
  }
}

/// Client-side zero-backend crop widget
/// Renders zoomed crop of component detection in-browser from the cached full image.
class ClientSideCropWidget extends StatelessWidget {
  final String imagePath;
  final List<double> bbox;
  final bool isDefect;
  final String? label;
  final String? compType;
  final bool drawBox;
  final double? width;
  final double? height;

  const ClientSideCropWidget({
    super.key,
    required this.imagePath,
    required this.bbox,
    this.isDefect = false,
    this.label,
    this.compType,
    this.drawBox = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Standard DJI inspection resolution
    const double imgW = 5184.0;
    const double imgH = 3888.0;

    final double x = bbox[0];
    final double y = bbox[1];
    final double w = bbox[2];
    final double h = bbox[3];

    final double cx = x + w / 2.0;
    final double cy = y + h / 2.0;

    // Minimum context padding so components are clearly visible
    final double minCropW = (w * 2.2).clamp(320.0, imgW);
    final double minCropH = (h * 2.2).clamp(220.0, imgH);

    final double cropW = minCropW > minCropH * 1.45 ? minCropW : minCropH * 1.45;
    final double cropH = minCropH > minCropW / 1.45 ? minCropH : minCropW / 1.45;

    final double padX1 = (cx - cropW / 2.0).clamp(0.0, imgW);
    final double padY1 = (cy - cropH / 2.0).clamp(0.0, imgH);
    final double padX2 = (cx + cropW / 2.0).clamp(0.0, imgW);
    final double padY2 = (cy + cropH / 2.0).clamp(0.0, imgH);

    final double actualCropW = padX2 - padX1;
    final double actualCropH = padY2 - padY1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double targetW = width ?? (constraints.maxWidth.isFinite ? constraints.maxWidth : 160.0);
        final double targetH = height ?? (constraints.maxHeight.isFinite ? constraints.maxHeight : 118.0);

        if (actualCropW <= 0 || actualCropH <= 0 || targetW <= 0 || targetH <= 0) {
          return Container(width: targetW, height: targetH, color: const Color(0xFF1E293B));
        }

        final double scale = targetW / actualCropW;
        final double renderedImgW = imgW * scale;
        final double renderedImgH = imgH * scale;

        final double imgLeft = -padX1 * scale;
        final double imgTop = -padY1 * scale;

        return ClipRect(
          child: SizedBox(
            width: targetW,
            height: targetH,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: imgLeft,
                  top: imgTop,
                  width: renderedImgW,
                  height: renderedImgH,
                  child: Image(
                    image: ImageService.getImageProvider(imagePath),
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (ctx, err, st) => Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(Icons.crop_original, color: Colors.white24, size: 24),
                      ),
                    ),
                  ),
                ),
                if (isDefect && drawBox) ...[
                  Positioned(
                    left: (x - padX1) * scale,
                    top: (y - padY1) * scale,
                    width: (w * scale).clamp(4.0, targetW),
                    height: (h * scale).clamp(4.0, targetH),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFEF4444), width: 2.0),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  if (label != null && label!.isNotEmpty)
                    Positioned(
                      left: (x - padX1) * scale,
                      top: ((y - padY1) * scale - 18.0).clamp(0.0, targetH - 18.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          label!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

