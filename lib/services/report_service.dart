import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportService {
  static const String reportFileName =
      '400KV_Tower_1_Site_B_inspection_report_reviewed 1.pdf';

  static const String s3ReportUrl =
      'https://powerlinee.s3.ap-south-1.amazonaws.com/data/400KV_Tower_1_Site_B_inspection_report_reviewed+1.pdf';

  /// Direct download endpoint for the 80-page inspection report
  static String get downloadUrl => s3ReportUrl;

  /// View URL for the inspection report
  static String get reportUrl => s3ReportUrl;

  /// Opens or downloads the 80-page local inspection report
  static Future<void> downloadReport(BuildContext context) async {
    final uri = Uri.parse(downloadUrl);
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
