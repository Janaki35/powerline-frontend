import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tower_registry.dart';

class ReportService {
  static const String defaultReportFileName =
      '400KV_Tower_1_Site_B_inspection_report_reviewed 1.pdf';

  static const String defaultS3ReportUrl =
      'https://powerlinee.s3.ap-south-1.amazonaws.com/data/400KV_Tower_1_Site_B_inspection_report_reviewed+1.pdf';

  /// Resolves the S3 PDF report URL for a tower
  static String getReportUrl([String? towerIdOrCode]) {
    final def = TowerRegistry.getTower(towerIdOrCode);
    if (def != null && def.pdfS3Url != null && def.pdfS3Url!.isNotEmpty) {
      return def.pdfS3Url!;
    }
    return defaultS3ReportUrl;
  }

  /// Direct download endpoint
  static String get downloadUrl => defaultS3ReportUrl;

  /// View URL for the inspection report
  static String get reportUrl => defaultS3ReportUrl;

  /// Opens or downloads the inspection report for the active tower
  static Future<void> downloadReport(BuildContext context, {String? towerId}) async {
    final targetUrl = getReportUrl(towerId);
    final uri = Uri.parse(targetUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback: try default launch
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

