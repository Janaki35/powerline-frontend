import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/inspection_model.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final Tower tower;
  final VoidCallback? onOpenSummary;
  final VoidCallback? onToggleMapOverview;
  final bool isMapOverview;

  const AppHeader({
    super.key,
    required this.tower,
    this.onOpenSummary,
    this.onToggleMapOverview,
    this.isMapOverview = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 860;
    final isMobile = width < 620;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      child: Row(
        children: [
          // Platform Brand / Logo
          InkWell(
            onTap: onToggleMapOverview,
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KnoGrid',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (!isMobile)
                      const Text(
                        'TowerLens Intelligence',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          if (!isMobile) ...[
            const SizedBox(width: 20),
            const VerticalDivider(
              color: AppColors.border,
              indent: 14,
              endIndent: 14,
              width: 1,
            ),
            const SizedBox(width: 20),

            // Breadcrumbs
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Network',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                    ),
                    const Text(
                      '400KV Line - Site B',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlueLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tower.towerName,
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Severity tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.criticalRedLight,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.criticalRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.close, size: 12, color: AppColors.criticalRed),
                          SizedBox(width: 3),
                          Text(
                            '9 Critical Deficiencies',
                            style: TextStyle(
                              color: AppColors.criticalRed,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Spacer(),
          ],

          const SizedBox(width: 10),

          // Action: View Map / Inspection Switcher
          OutlinedButton.icon(
            onPressed: onToggleMapOverview,
            style: OutlinedButton.styleFrom(
              foregroundColor: isMapOverview ? AppColors.primaryBlue : AppColors.textSecondary,
              backgroundColor: isMapOverview ? AppColors.primaryBlueLight : Colors.transparent,
              side: BorderSide(
                color: isMapOverview ? AppColors.primaryBlue : AppColors.border,
              ),
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: Icon(isMapOverview ? Icons.analytics_outlined : Icons.map_outlined, size: 16),
            label: Text(
              isCompact
                  ? (isMapOverview ? 'Inspection' : 'Map')
                  : (isMapOverview ? 'Inspection View' : 'Network Map'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(width: 8),

          // Action: Summary Report Button
          ElevatedButton.icon(
            onPressed: onOpenSummary,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.description_outlined, size: 16),
            label: Text(
              isCompact ? 'Report' : 'Inspection Report',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(width: 10),

          // User Profile
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE2E8F0),
            child: const Text(
              'IE',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
