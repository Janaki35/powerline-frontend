import 'package:flutter/material.dart';

ImageProvider getPlatformImageProvider(
  String rawPath,
  String httpUrl,
  String localBasePath,
) {
  return NetworkImage(httpUrl);
}
