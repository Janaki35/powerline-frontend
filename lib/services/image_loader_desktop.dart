import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider getPlatformImageProvider(
  String rawPath,
  String httpUrl,
  String localBasePath,
) {
  try {
    var clean = rawPath.trim();
    final uri = Uri.tryParse(clean);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      clean = uri.path;
      if (clean.startsWith('/')) {
        clean = clean.substring(1);
      }
    }
    if (clean.startsWith('data/')) {
      clean = clean.substring('data/'.length);
    }
    if (clean.startsWith('towers/')) {
      clean = clean.substring('towers/'.length);
    }
    if (clean.startsWith('corrected_earth_peak/')) {
      clean = clean.substring('corrected_earth_peak/'.length);
    }
    clean = clean.replaceAll('/', '\\');
    final localFilePath = '$localBasePath\\$clean';
    final file = File(localFilePath);
    if (file.existsSync()) {
      return FileImage(file);
    }
  } catch (_) {
    // Fall back to HTTP network provider
  }
  return NetworkImage(httpUrl);
}
