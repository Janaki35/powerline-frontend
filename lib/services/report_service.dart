import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

class ReportService {
  static const String reportFileName =
      '400KV_Tower_1_Site_B_inspection_report_reviewed 1.pdf';

  /// Direct download endpoint with Content-Disposition attachment
  static String get downloadUrl =>
      '${AppConfig.imageServerBaseUrl}/download-report';

  /// Legacy view URL on the local image/data server
  static String get reportUrl =>
      '${AppConfig.imageServerBaseUrl}/$reportFileName';

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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.download_done_rounded, color: Colors.greenAccent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Downloading 80-page inspection report: 400KV_Tower_1_Site_B_inspection_report.pdf',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.blueAccent,
              onPressed: () => launchUrl(Uri.parse(reportUrl)),
            ),
          ),
        );
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
