import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/inspection_model.dart';
import '../services/report_service.dart';
import '../services/tower_registry.dart';
import 'transmission_tower_icon.dart';

class AssetNavigatorPanel extends StatefulWidget {
  final Tower tower;
  final String? selectedAssetType; // 'Circuit', 'Earthing peak', or null
  final Circuit? selectedCircuit;
  final Phase? selectedPhase;
  // Currently selected earthing peak (for earthing peak inspection)
  final EarthPeak? selectedEarthPeak;
  final ValueChanged<String> onSelectAssetType;
  final ValueChanged<Circuit> onSelectCircuit;
  final ValueChanged<Phase> onSelectPhase;
  // Callback when user selects an earthing peak
  final ValueChanged<EarthPeak>? onSelectEarthPeak;
  final VoidCallback? onOpenSummary;
  final VoidCallback? onBackToMap;
  final double? width;

  const AssetNavigatorPanel({
    super.key,
    required this.tower,
    this.selectedAssetType,
    this.selectedCircuit,
    this.selectedPhase,
    this.selectedEarthPeak,
    required this.onSelectAssetType,
    required this.onSelectCircuit,
    required this.onSelectPhase,
    this.onSelectEarthPeak,
    this.onOpenSummary,
    this.onBackToMap,
    this.width,
  });

  @override
  State<AssetNavigatorPanel> createState() => _AssetNavigatorPanelState();
}

class _AssetNavigatorPanelState extends State<AssetNavigatorPanel> {
  late bool _isAssetTypeDropdownOpen;
  late bool _isCircuitDropdownOpen;
  late bool _isPhaseDropdownOpen;
  // Controls whether the earth point dropdown is open
  late bool _isEarthPeakDropdownOpen;
  bool _showSummary = false;

  @override
  void initState() {
    super.initState();
    _isAssetTypeDropdownOpen = false;
    _isCircuitDropdownOpen = false;
    _isPhaseDropdownOpen = false;
    _isEarthPeakDropdownOpen = widget.selectedAssetType == 'Earthing peak' && widget.selectedEarthPeak == null;
    _showSummary = false;
  }

  @override
  void didUpdateWidget(covariant AssetNavigatorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isSingleCircuit = widget.tower.circuits.length == 1 || widget.tower.summary.circuitCount == 1;

    // Handle switching between Circuit and Earthing peak asset types
    if (widget.selectedAssetType != oldWidget.selectedAssetType) {
      _showSummary = false;
      if (widget.selectedAssetType == 'Earthing peak') {
        _isAssetTypeDropdownOpen = false;
        _isCircuitDropdownOpen = false;
        _isPhaseDropdownOpen = false;
        _isEarthPeakDropdownOpen = true;
        // Keep summary closed by default when switching asset types
        _showSummary = false;
      } else if (widget.selectedAssetType == 'Circuit') {
        _isAssetTypeDropdownOpen = false;
        _isEarthPeakDropdownOpen = false;
        if (isSingleCircuit) {
          _isCircuitDropdownOpen = false;
          _isPhaseDropdownOpen = true;
        } else {
          _isCircuitDropdownOpen = true;
        }
      } else if (widget.selectedAssetType == null) {
        _isAssetTypeDropdownOpen = false;
        _isCircuitDropdownOpen = false;
        _isPhaseDropdownOpen = false;
        _isEarthPeakDropdownOpen = false;
      }
    }

    // When an earthing peak is selected, close dropdown but keep summary closed
    // Summary must only open when the user clicks the Summary button
    if (widget.selectedEarthPeak != oldWidget.selectedEarthPeak) {
      _showSummary = false;
      if (widget.selectedEarthPeak != null) {
        _isEarthPeakDropdownOpen = false;
      }
    }

    if (widget.selectedCircuit != oldWidget.selectedCircuit) {
      _showSummary = false;
      if (widget.selectedCircuit != null) {
        _isCircuitDropdownOpen = false;
        _isPhaseDropdownOpen = true;
      } else {
        _isPhaseDropdownOpen = false;
      }
    }

    if (widget.selectedPhase != oldWidget.selectedPhase) {
      _showSummary = false;
      if (widget.selectedPhase != null) {
        _isPhaseDropdownOpen = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final towerDef = TowerRegistry.getTower(widget.tower.towerId);
    final lineLabel = '${towerDef?.voltage ?? '400 kV'} · ${towerDef?.site ?? 'Site B'}';
    final towerLabel = towerDef?.displayCode ?? widget.tower.towerId;
    final isSingleCircuit = widget.tower.circuits.length == 1 || widget.tower.summary.circuitCount == 1;

    return Container(
      width: widget.width ?? 320,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          // Back to Network Map link if provided
          if (widget.onBackToMap != null) ...[
            InkWell(
              onTap: widget.onBackToMap,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.chevron_left, size: 18, color: Color(0xFF1E60B5)),
                    SizedBox(width: 4),
                    Text(
                      'Network map',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E60B5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Section Title: ASSET NAVIGATOR
          const Text(
            'ASSET NAVIGATOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),

          // --- TREE STRUCTURE (LINE -> TOWER -> ASSET TYPE -> CIRCUIT/EARTH POINT -> PHASE) ---

          // Node 1: LINE
          _buildTreeNode(
            label: 'LINE',
            content: Row(
              children: [
                const Icon(Icons.waves, size: 16, color: Color(0xFF475569)),
                const SizedBox(width: 8),
                Text(
                  lineLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            hasChildren: true,
            depth: 0,
          ),

          // Node 2: TOWER
          _buildTreeNode(
            label: 'TOWER',
            content: Row(
              children: [
                const TransmissionTowerIcon(size: 16, color: Color(0xFF475569)),
                const SizedBox(width: 8),
                Text(
                  towerLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            hasChildren: true,
            depth: 1,
          ),

          // Node 3: ASSET TYPE (always shown: user can choose Circuit or Earthing peak)
          _buildAssetTypeTreeNode(isSingleCircuit: isSingleCircuit),

          // --- EARTHING PEAK BRANCH (matching earthingpeak.png) ---
          if (widget.selectedAssetType == 'Earthing peak') ...[
            // Earth Point dropdown (SW or NE)
            _buildEarthPeakTreeNode(),

            // Summary & Report buttons when an earthing peak is selected
            if (widget.selectedEarthPeak != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showSummary = !_showSummary;
                          });
                        },
                        icon: const Icon(Icons.bar_chart_rounded, size: 16),
                        label: const Text(
                          'Summary',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ReportService.downloadReport(context, towerId: widget.tower.towerId);
                        },
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: const Text(
                          'Report',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Earthing Peak Summary Card (matching earthingpeak.png)
              if (_showSummary) ...[
                const SizedBox(height: 16),
                _buildEarthPeakSummaryCard(widget.selectedEarthPeak!),
              ],
            ],
          ],

          // --- CIRCUIT & PHASE BRANCH (existing flow preserved 100%) ---
          if (widget.selectedAssetType == 'Circuit') ...[
            // Node 4: CIRCUIT (only shown after Asset Type is selected for multi-circuit towers)
            if (!isSingleCircuit)
              _buildCircuitTreeNode(),

            // Node 5 (or 4 for single-circuit): PHASE (only shown after Circuit is selected)
            if (widget.selectedCircuit != null)
              _buildPhaseTreeNode(isSingleCircuit: isSingleCircuit),

            // Action Buttons: Summary & Report (shown when Phase is selected)
            if (widget.selectedCircuit != null && widget.selectedPhase != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showSummary = !_showSummary;
                          });
                        },
                        icon: const Icon(Icons.bar_chart_rounded, size: 16),
                        label: const Text(
                          'Summary',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ReportService.downloadReport(context, towerId: widget.tower.towerId);
                        },
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: const Text(
                          'Report',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Phase Summary Card (shows ONLY if _showSummary is true)
            if (widget.selectedCircuit != null && widget.selectedPhase != null && _showSummary) ...[
              const SizedBox(height: 16),
              _buildPhaseSummaryCard(),
            ],
          ],
        ],
      ),
    );
  }

  /// Node 3: ASSET TYPE dropdown (Image 1)
  Widget _buildAssetTypeTreeNode({bool isSingleCircuit = false}) {
    final isOpen = _isAssetTypeDropdownOpen;
    final isSelected = widget.selectedAssetType != null;
    final displayText = widget.selectedAssetType ?? 'Select';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18.0 * 2,
            child: CustomPaint(
              painter: _TreeBranchPainter(isLastChild: widget.selectedAssetType == null),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown Header
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isAssetTypeDropdownOpen = !_isAssetTypeDropdownOpen;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOpen ? const Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOpen ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                          width: isOpen ? 1.2 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ASSET TYPE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isOpen ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Icon(
                                isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 16,
                                color: isOpen ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isOpen
                                  ? const Color(0xFF1D4ED8)
                                  : (isSelected ? AppColors.textPrimary : const Color(0xFF1967D2)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Option Card List (when open)
                  if (isOpen)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Option 1: Circuit
                          InkWell(
                            onTap: () {
                              widget.onSelectAssetType('Circuit');
                              if (isSingleCircuit && widget.tower.circuits.isNotEmpty) {
                                widget.onSelectCircuit(widget.tower.circuits.first);
                              }
                              setState(() {
                                _isAssetTypeDropdownOpen = false;
                                _isCircuitDropdownOpen = !isSingleCircuit;
                                _isPhaseDropdownOpen = isSingleCircuit;
                                _isEarthPeakDropdownOpen = false;
                                _showSummary = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: widget.selectedAssetType == 'Circuit'
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Circuit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: widget.selectedAssetType == 'Circuit'
                                      ? const Color(0xFF1D4ED8)
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),

                          // Option 2: Earthing peak (only shown if the tower has earthing peaks)
                          if (widget.tower.earthPeaks.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: () {
                                // User selects Earthing peak as the asset type
                                widget.onSelectAssetType('Earthing peak');
                                setState(() {
                                  _isAssetTypeDropdownOpen = false;
                                  _isCircuitDropdownOpen = false;
                                  _isPhaseDropdownOpen = false;
                                  _isEarthPeakDropdownOpen = true;
                                  // Keep summary closed until user clicks the Summary button
                                  _showSummary = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                decoration: BoxDecoration(
                                  color: widget.selectedAssetType == 'Earthing peak'
                                      ? const Color(0xFFEFF6FF)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Earthing peak',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: widget.selectedAssetType == 'Earthing peak'
                                        ? const Color(0xFF1D4ED8)
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Earth Point dropdown node (shown when Asset Type is 'Earthing peak')
  Widget _buildEarthPeakTreeNode() {
    final isOpen = _isEarthPeakDropdownOpen;
    final isSelected = widget.selectedEarthPeak != null;
    final displayText = widget.selectedEarthPeak?.earthPeakId ?? 'Select';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18.0 * 3,
            child: CustomPaint(
              painter: _TreeBranchPainter(isLastChild: widget.selectedEarthPeak == null),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown Header showing "EARTH POINT"
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isEarthPeakDropdownOpen = !_isEarthPeakDropdownOpen;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOpen ? const Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOpen ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                          width: isOpen ? 1.2 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'EARTH POINT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isOpen ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Icon(
                                isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 16,
                                color: isOpen ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isOpen
                                  ? const Color(0xFF1D4ED8)
                                  : (isSelected ? AppColors.textPrimary : const Color(0xFF1967D2)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Option Card List showing all Earth Points (matching earthingpeak.png)
                  if (isOpen)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: widget.tower.earthPeaks.map((ep) {
                          final isItemActive = widget.selectedEarthPeak?.earthPeakId == ep.earthPeakId;

                          return InkWell(
                            onTap: () {
                              // User selects this earthing peak
                              widget.onSelectEarthPeak?.call(ep);
                              setState(() {
                                _isEarthPeakDropdownOpen = false;
                                // Keep summary closed until user clicks the Summary button
                                _showSummary = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isItemActive ? const Color(0xFFEFF6FF) : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  // Teal dot matching earthingpeak.png
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0E9AA7),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      ep.earthPeakId,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isItemActive ? FontWeight.bold : FontWeight.w500,
                                        color: isItemActive ? const Color(0xFF1D4ED8) : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  // Blue checkmark when selected
                                  if (isItemActive)
                                    const Icon(
                                      Icons.check,
                                      size: 15,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Summary card for the selected Earthing Peak (matching earthingpeak.png)
  Widget _buildEarthPeakSummaryCard(EarthPeak earthPeak) {
    final counts = earthPeak.componentCounts;
    final conductorCount = counts['conductor'] ?? 0;
    final earthingWireCount = counts['earthing_wire'] ?? 0;
    final pgClampCount = counts['pg_clamp'] ?? 0;
    final damperCount = counts['vibration_damper'] ?? 0;

    // Count how many of the standard component types were not detected
    final standardTypes = [
      'arcing_horn',
      'corona_ring',
      'cotter_pin',
      'insulator',
      'jumper_cable',
      'cotter_pin_missing',
    ];
    int notSeenCount = 0;
    for (final t in standardTypes) {
      if ((counts[t] ?? 0) == 0) notSeenCount++;
    }

    final distanceStr = earthPeak.distanceToTowerM > 0
        ? '${earthPeak.distanceToTowerM.toStringAsFixed(1)} m'
        : '16.5 m';
    final imageCount = earthPeak.images.length;
    final defectCount = earthPeak.defectCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with teal dot, earth peak name and side label
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF0E9AA7),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${earthPeak.earthPeakId} summary',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${earthPeak.side} side',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Component rows dynamically showing detection counts
          _buildSummaryRow('Conductors', '$conductorCount', 'NORMAL', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
          _buildSummaryRow('Earthing wires', '$earthingWireCount', 'NORMAL', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
          _buildSummaryRow('PG clamps', '$pgClampCount', 'NORMAL', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
          _buildSummaryRow('Vibration dampers', '$damperCount', 'NORMAL', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
          _buildSummaryRow('Not seen ($notSeenCount types)', '—', 'NOT SEEN', const Color(0xFFF1F5F9), const Color(0xFF64748B)),

          const SizedBox(height: 12),
          // Legend / footnote matching reference image
          Text(
            'NORMAL no defect found · DEFECT issue found · NOT SEEN arcing horn, corona ring, cotter pin, insulator, jumper. Numbers are detections. $imageCount images, $distanceStr from the tower - $defectCount issues.',
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// Node 4: CIRCUIT dropdown (Image 2)
  Widget _buildCircuitTreeNode() {
    final isOpen = _isCircuitDropdownOpen;
    final isSelected = widget.selectedCircuit != null;
    final displayText = widget.selectedCircuit?.circuitId ?? 'Select';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18.0 * 3,
            child: CustomPaint(
              painter: _TreeBranchPainter(isLastChild: widget.selectedCircuit == null),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown Header
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isCircuitDropdownOpen = !_isCircuitDropdownOpen;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOpen ? const Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOpen ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                          width: isOpen ? 1.2 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'CIRCUIT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isOpen ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Icon(
                                isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 16,
                                color: isOpen ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isOpen
                                  ? const Color(0xFF1D4ED8)
                                  : (isSelected ? AppColors.textPrimary : const Color(0xFF1967D2)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Option Card List (when open, as in Image 2)
                  if (isOpen)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: widget.tower.circuits.map((c) {
                          final isItemActive = widget.selectedCircuit?.circuitId == c.circuitId;

                          return InkWell(
                            onTap: () {
                              widget.onSelectCircuit(c);
                              setState(() {
                                _isCircuitDropdownOpen = false;
                                _isPhaseDropdownOpen = true;
                                _showSummary = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isItemActive ? const Color(0xFFEFF6FF) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.circuitId,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isItemActive ? FontWeight.bold : FontWeight.w500,
                                  color: isItemActive ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Node 5: PHASE dropdown (Image 3)
  Widget _buildPhaseTreeNode({bool isSingleCircuit = false}) {
    final hasPhase = widget.selectedPhase != null;
    final phaseDisplayText = hasPhase ? 'Phase-${widget.selectedPhase!.phaseName}' : 'Select';
    final isOpen = _isPhaseDropdownOpen;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18.0 * (isSingleCircuit ? 3 : 4),
            child: const CustomPaint(
              painter: _TreeBranchPainter(isLastChild: true),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Phase Dropdown Header (Interactive Toggle)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isPhaseDropdownOpen = !_isPhaseDropdownOpen;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOpen ? const Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOpen ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                          width: isOpen ? 1.2 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PHASE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isOpen ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Icon(
                                isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 16,
                                color: isOpen ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            phaseDisplayText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isOpen
                                  ? const Color(0xFF1D4ED8)
                                  : (hasPhase ? AppColors.textPrimary : const Color(0xFF1967D2)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Phase Option Cards (shown only when dropdown is open)
                  if (isOpen)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPhaseOptionRow('R', const Color(0xFFEF4444)),
                          const SizedBox(height: 4),
                          _buildPhaseOptionRow('Y', const Color(0xFFEAB308)),
                          const SizedBox(height: 4),
                          _buildPhaseOptionRow('B', const Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseOptionRow(String phaseName, Color dotColor) {
    final phase = widget.selectedCircuit?.phases[phaseName];
    final isSelected = widget.selectedPhase?.phaseName == phaseName;

    return InkWell(
      onTap: () {
        if (phase != null) {
          widget.onSelectPhase(phase);
        }
        setState(() {
          _isPhaseDropdownOpen = false;
          _showSummary = false;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Phase-$phaseName',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              const Icon(Icons.check, size: 16, color: Color(0xFF1967D2)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTreeNode({
    required String label,
    required Widget content,
    required bool hasChildren,
    required int depth,
    bool isDisabled = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tree guide lines for depth > 0
          if (depth > 0)
            SizedBox(
              width: 18.0 * depth,
              child: CustomPaint(
                painter: _TreeBranchPainter(isLastChild: !hasChildren),
              ),
            ),

          // Card Node
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDisabled ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDisabled
                      ? const Color(0xFFE2E8F0).withValues(alpha: 0.6)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDisabled ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  content,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseSummaryCard() {
    final phaseName = widget.selectedPhase?.phaseName ?? 'R';
    final isYellow = phaseName == 'Y';
    final isBlue = phaseName == 'B';

    final Color dotColor = isYellow
        ? const Color(0xFFEAB308)
        : isBlue
            ? const Color(0xFF2563EB)
            : const Color(0xFFDB322E);

    final phase = widget.selectedPhase;
    int countComp(String compKey) {
      if (phase == null) return 0;
      int c = 0;
      for (final img in phase.images) {
        c += img.componentDetections[compKey]?.length ?? 0;
      }
      return c;
    }

    final int insulatorCount = countComp('insulator');
    final int conductorCount = countComp('conductor');
    final int damperCount = countComp('vibration_damper');
    final int ringCount = countComp('corona_ring');
    final int hornCount = countComp('arcing_horn');
    final int cotterMissingCount = countComp('cotter_pin_missing');
    final bool hasDefect = cotterMissingCount > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title row: Phase color dot + Phase-R/Y/B summary + Circuit_SW (Image 4)
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Phase-$phaseName summary',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                (widget.tower.circuits.length == 1 || widget.tower.summary.circuitCount == 1)
                    ? 'Circuit'
                    : (widget.selectedCircuit?.circuitId ?? ''),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar with Green, Red (defect), and Grey track matching user reference
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 5,
              width: double.infinity,
              color: const Color(0xFFE2E8F0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 50,
                    child: Container(color: const Color(0xFF22C55E)),
                  ),
                  if (hasDefect)
                    Expanded(
                      flex: 10,
                      child: Container(color: const Color(0xFFDB322E)),
                    ),
                  Expanded(
                    flex: hasDefect ? 40 : 50,
                    child: Container(color: const Color(0xFFE2E8F0)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Component rows dynamically driven by JSON data
          _buildSummaryRow('Insulators', '$insulatorCount', 'NORMAL', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
          _buildSummaryRow('Conductors', '$conductorCount', 'NORMAL', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
          _buildSummaryRow('Vibration dampers', '$damperCount', 'NORMAL', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
          _buildSummaryRow('Corona rings', '$ringCount', 'NORMAL', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
          _buildSummaryRow('Arcing horns', '$hornCount', 'NORMAL', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
          _buildSummaryRow(
            'Cotter pins missing',
            '$cotterMissingCount',
            hasDefect ? 'DEFECT' : 'NORMAL',
            hasDefect ? const Color(0xFFFDE8E8) : const Color(0xFFDCFCE7),
            hasDefect ? const Color(0xFFDB322E) : const Color(0xFF15803D),
          ),
          _buildSummaryRow('Not seen (4 types)', '—', 'NOT SEEN', const Color(0xFFF1F5F9), const Color(0xFF64748B)),

          const SizedBox(height: 12),
          // Legend / footnote
          const Text(
            'NORMAL no defect found · DEFECT issue found · NOT SEEN cotter pin, earth wire, jumper, PG clamp. Numbers are detections.',
            style: TextStyle(
              fontSize: 10.5,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String component,
    String count,
    String status,
    Color badgeBg,
    Color badgeText,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              component,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            count,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: badgeText,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tree branch guide line painter
class _TreeBranchPainter extends CustomPainter {
  final bool isLastChild;

  const _TreeBranchPainter({required this.isLastChild});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    const cy = 22.0;

    // Vertical line
    canvas.drawLine(Offset(cx, 0), Offset(cx, isLastChild ? cy : size.height), linePaint);
    // Horizontal branch line to card
    canvas.drawLine(Offset(cx, cy), Offset(size.width, cy), linePaint);
  }

  @override
  bool shouldRepaint(covariant _TreeBranchPainter oldDelegate) =>
      oldDelegate.isLastChild != isLastChild;
}
