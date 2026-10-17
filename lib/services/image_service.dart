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
  }) {
    return Image(
      image: getImageProvider(imagePath),
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
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
    final cropUrl = getCropUrl(
      imagePath,
      bbox,
      isDefect: isDefect,
      label: label,
      compType: compType,
      drawBox: drawBox,
    );
    return Image.network(
      cropUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: const Color(0xFF1E293B),
          child: const Center(
            child: Icon(Icons.crop_original, color: Colors.white38, size: 24),
          ),
        );
      },
    );
  }
}

