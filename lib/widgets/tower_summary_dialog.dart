import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/inspection_model.dart';
import '../services/tower_registry.dart';

class TowerSummaryDialog extends StatelessWidget {
  final Tower tower;

  const TowerSummaryDialog({super.key, required this.tower});

  @override
  Widget build(BuildContext context) {
    final summary = tower.summary;
    final towerDef = TowerRegistry.getTower(tower.towerId);
    final surveyDate = towerDef?.surveyDate ?? '28 Mar 2026';
    final totalDefects = summary.componentCounts['cotter_pin_missing'] ?? 0;

    int totalImages = 0;
    for (final c in tower.circuits) {
      for (final p in c.phases.values) {
        totalImages += p.images.length;
      }
    }
    if (totalImages == 0) {
      totalImages = summary.componentCounts.values.fold(0, (a, b) => a + b);
    }

    final missingItemsText = summary.missingComponents.isNotEmpty
        ? summary.missingComponents.map((e) => e.replaceAll('_', ' ')).join(', ')
        : 'None';

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 750),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tower Inspection Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tower.towerName} · Inspection Date: $surveyDate',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Content scroll area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Alert Box (Critical Red or Normal Green)
                    if (totalDefects > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.criticalRedLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.criticalRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.criticalRed,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$totalDefects Critical Deficiencies Identified',
                                    style: const TextStyle(
                                      color: AppColors.criticalRed,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'All $totalDefects issues: "Cotter pin missing (Critical)". Requires prompt line crew remediation before conductor attachment hardware weakens.',
                                    style: const TextStyle(
                                      color: Color(0xFF991B1B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF86EFAC),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Normal Operational Condition (0 Defects)',
                                    style: TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'All components and structural members inspected within standard operational limits. No missing cotter pins detected.',
                                    style: TextStyle(
                                      color: Color(0xFF166534),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Quick Telemetry stats
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 540;
                        if (isNarrow) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  _buildStatCard('Circuits', '${summary.circuitCount}', Icons.electrical_services),
                                  const SizedBox(width: 10),
                                  _buildStatCard('Images Inspected', '$totalImages', Icons.photo_library_outlined),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _buildStatCard('Missing Items', missingItemsText, Icons.remove_circle_outline),
                                  const SizedBox(width: 10),
                                  _buildStatCard('Altitude', '${tower.location.altitudeM.toStringAsFixed(1)} m', Icons.terrain_outlined),
                                ],
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            _buildStatCard('Circuits', '${summary.circuitCount}', Icons.electrical_services),
                            const SizedBox(width: 12),
                            _buildStatCard('Images Inspected', '$totalImages', Icons.photo_library_outlined),
                            const SizedBox(width: 12),
                            _buildStatCard('Missing Items', missingItemsText, Icons.remove_circle_outline),
                            const SizedBox(width: 12),
                            _buildStatCard('Altitude', '${tower.location.altitudeM.toStringAsFixed(1)} m', Icons.terrain_outlined),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Condition by Phase Table
                    const Text(
                      'Condition by Phase',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...tower.circuits.expand((c) => c.phases.entries.map((entry) {
                          final p = entry.value;
                          final isCrit = p.defectCount > 0;
                          return _buildPhaseRow(
                            '${c.circuitId} - Phase ${entry.key}',
                            isCrit
                                ? '${p.defectCount} issue${p.defectCount > 1 ? 's' : ''} (Cotter pin missing)'
                                : 'No defects detected',
                            isCrit ? AppColors.criticalRed : AppColors.normalGreen,
                            isCrit,
                          );
                        })),

                    const SizedBox(height: 24),

                    // Total Component Detection Counts
                    const Text(
                      'AI Component Detections Roll-up',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: summary.componentCounts.entries.map((entry) {
                          final isDefect = entry.key == 'cotter_pin_missing';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.border, width: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isDefect ? FontWeight.bold : FontWeight.w600,
                                    color: isDefect ? AppColors.criticalRed : AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDefect ? AppColors.criticalRedLight : Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isDefect ? AppColors.criticalRed : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    '${entry.value}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDefect ? AppColors.criticalRed : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Modal Actions
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Full 80-page inspection report available at data/400KV_Tower_1_Site_B_inspection_report_reviewed 1.pdf',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('Export / Reference PDF Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryBlue),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseRow(String phaseTitle, String statusText, Color color, bool isDefect) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            phaseTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            children: [
              Icon(
                isDefect ? Icons.close : Icons.check,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
