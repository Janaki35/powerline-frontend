import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/inspection_model.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../widgets/asset_navigator_panel.dart';
import '../widgets/tower_structure_panel.dart';
import '../widgets/phase_inspection_view.dart';
import '../widgets/network_map_overview_view.dart';
import '../widgets/transmission_tower_icon.dart';
import 'login_screen.dart';

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  InspectionData? _inspectionData;
  String? _selectedAssetType;
  Circuit? _selectedCircuit;
  Phase? _selectedPhase;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await DataService.loadInspectionData();
      setState(() {
        _inspectionData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen to global AppState (manages user session and active screen)
    final appState = Provider.of<AppState>(context);

    // Initial Loading State: waits for data and stored session in browser
    if (!appState.isInitialized || _isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F5EE),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: AppColors.primaryBlue),
              SizedBox(height: 16),
              Text(
                'Loading TowerLens Intelligence...',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _inspectionData == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.criticalRed),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load inspection data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Unknown error',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _loadData();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final tower = _inspectionData!.tower;

    // Restore saved circuit & phase if website was refreshed while on the 2nd page
    if (_selectedCircuit == null && appState.selectedCircuitId != null) {
      final match = tower.circuits
          .where((c) => c.circuitId == appState.selectedCircuitId);
      if (match.isNotEmpty) {
        _selectedAssetType = 'Circuit';
        _selectedCircuit = match.first;
        if (appState.selectedPhaseName != null) {
          _selectedPhase = _selectedCircuit?.phases[appState.selectedPhaseName!];
        }
      }
    }

    // 1. SCREEN 1: SIGN IN (Penpot: 1.png)
    if (appState.currentView == AppView.signIn) {
      return LoginScreen(
        onLoginSuccess: () => appState.login(),
      );
    }

    // 2. SCREEN 2: NETWORK MAP (Penpot: 2.png / 2_sidebar.png / 2_tableview.png)
    if (appState.currentView == AppView.networkMap) {
      return NetworkMapOverviewView(
        tower: tower,
        initialDate: appState.selectedDate,
        initialVoltage: appState.selectedVoltage,
        initialTowerId: appState.selectedTowerId,
        onDateChanged: (d) => appState.setSelectedDate(d),
        onVoltageChanged: (v) => appState.setSelectedVoltage(v),
        onTowerChanged: (t) => appState.setSelectedTowerId(t),
        onLogout: () => appState.logout(),
        onOpenInspection: (c, p, [towerId]) {
          setState(() {
            _selectedAssetType = c != null ? 'Circuit' : null;
            _selectedCircuit = c;
            _selectedPhase = p;
          });
          appState.navigateToInspection(
            towerId: towerId,
            circuitId: c?.circuitId,
            phaseName: p?.phaseName,
          );
        },
      );
    }

    // 3. SCREEN 3: 04 INSPECTION (Matching Screenshot 1 & 2: 3 Columns Full Screen)
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // DESKTOP VIEW (width >= 1050): Full 3-column layout
          if (width >= 1050) {
            final navWidth = width >= 1280 ? 320.0 : 280.0;
            final structWidth = width >= 1280 ? 410.0 : 340.0;

            return Column(
              children: [
                // Top Header matching Screenshot 1 & 2
                Container(
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          // Return to Page 1 (Network Map)
                          appState.navigateToMap();
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1967D2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: TransmissionTowerIcon(size: 16, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'TowerLens Intelligence',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          // Clear stored session and logout to Sign In screen
                          appState.logout();
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout, size: 14, color: Color(0xFF475569)),
                              SizedBox(width: 6),
                              Text(
                                'Log out',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3 Columns Row
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Column 1: Asset Navigator
                      AssetNavigatorPanel(
                        width: navWidth,
                        tower: tower,
                        selectedAssetType: _selectedAssetType,
                        selectedCircuit: _selectedCircuit,
                        selectedPhase: _selectedPhase,
                        onSelectAssetType: (type) {
                          setState(() {
                            _selectedAssetType = type;
                            _selectedCircuit = null;
                            _selectedPhase = null;
                          });
                        },
                        onSelectCircuit: (c) {
                          setState(() {
                            _selectedCircuit = c;
                            _selectedPhase = null;
                          });
                          // Save selection to AppState for browser refresh persistence
                          appState.navigateToInspection(
                            circuitId: c.circuitId,
                            phaseName: null,
                          );
                        },
                        onSelectPhase: (p) {
                          setState(() {
                            _selectedPhase = p;
                          });
                          // Save selection to AppState for browser refresh persistence
                          appState.navigateToInspection(
                            circuitId: _selectedCircuit?.circuitId,
                            phaseName: p.phaseName,
                          );
                        },
                        onBackToMap: () {
                          appState.navigateToMap();
                        },
                      ),

                      // Column 2: Tower Structure Diagram
                      TowerStructurePanel(
                        width: structWidth,
                        tower: tower,
                        selectedCircuit: _selectedCircuit,
                        selectedPhase: _selectedPhase,
                        onSelectCircuit: (c) {
                          setState(() {
                            _selectedAssetType = 'Circuit';
                            _selectedCircuit = c;
                            _selectedPhase = null;
                          });
                          // Save selection to AppState for browser refresh persistence
                          appState.navigateToInspection(
                            circuitId: c.circuitId,
                            phaseName: null,
                          );
                        },
                        onSelectPhase: (p) {
                          setState(() {
                            _selectedAssetType = 'Circuit';
                            _selectedPhase = p;
                          });
                          // Save selection to AppState for browser refresh persistence
                          appState.navigateToInspection(
                            circuitId: _selectedCircuit?.circuitId,
                            phaseName: p.phaseName,
                          );
                        },
                      ),

                      // Column 3: Phase Inspection & Detailed Crops (Expanded)
                      Expanded(
                        child: PhaseInspectionView(
                          phase: _selectedPhase,
                          circuit: _selectedCircuit,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // TABLET & MOBILE VIEW (< 1050 width)
          return DefaultTabController(
            length: 3,
            initialIndex: _selectedPhase != null ? 2 : 0,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0.5,
                scrolledUnderElevation: 1,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                  tooltip: 'Back to Network Map',
                  onPressed: () => appState.navigateToMap(),
                ),
                title: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1967D2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Center(
                        child: TransmissionTowerIcon(size: 14, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${tower.towerName} · Inspection',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20, color: Color(0xFF475569)),
                    tooltip: 'Log out',
                    onPressed: () => appState.logout(),
                  ),
                ],
                bottom: const TabBar(
                  labelColor: Color(0xFF1967D2),
                  unselectedLabelColor: Color(0xFF64748B),
                  indicatorColor: Color(0xFF1967D2),
                  indicatorWeight: 2.5,
                  tabs: [
                    Tab(icon: Icon(Icons.account_tree_outlined, size: 18), text: 'Navigator'),
                    Tab(icon: Icon(Icons.architecture, size: 18), text: 'Structure'),
                    Tab(icon: Icon(Icons.image_search, size: 18), text: 'Inspection'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  AssetNavigatorPanel(
                    width: double.infinity,
                    tower: tower,
                    selectedAssetType: _selectedAssetType,
                    selectedCircuit: _selectedCircuit,
                    selectedPhase: _selectedPhase,
                    onSelectAssetType: (type) {
                      setState(() {
                        _selectedAssetType = type;
                        _selectedCircuit = null;
                        _selectedPhase = null;
                      });
                    },
                    onSelectCircuit: (c) {
                      setState(() {
                        _selectedCircuit = c;
                        _selectedPhase = null;
                      });
                      appState.navigateToInspection(
                        circuitId: c.circuitId,
                        phaseName: null,
                      );
                    },
                    onSelectPhase: (p) {
                      setState(() => _selectedPhase = p);
                      appState.navigateToInspection(
                        circuitId: _selectedCircuit?.circuitId,
                        phaseName: p.phaseName,
                      );
                    },
                    onBackToMap: () => appState.navigateToMap(),
                  ),
                  TowerStructurePanel(
                    width: double.infinity,
                    tower: tower,
                    selectedCircuit: _selectedCircuit,
                    selectedPhase: _selectedPhase,
                    onSelectCircuit: (c) {
                      setState(() {
                        _selectedAssetType = 'Circuit';
                        _selectedCircuit = c;
                        _selectedPhase = null;
                      });
                      appState.navigateToInspection(
                        circuitId: c.circuitId,
                        phaseName: null,
                      );
                    },
                    onSelectPhase: (p) {
                      setState(() {
                        _selectedAssetType = 'Circuit';
                        _selectedPhase = p;
                      });
                      appState.navigateToInspection(
                        circuitId: _selectedCircuit?.circuitId,
                        phaseName: p.phaseName,
                      );
                    },
                  ),
                  PhaseInspectionView(
                    phase: _selectedPhase,
                    circuit: _selectedCircuit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
