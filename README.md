# KnoGrid — AI-Powered Transmission Infrastructure Intelligence Platform

A high-fidelity Flutter frontend implementation for **KnoGrid (TowerLens Intelligence)**, accurately reproducing the Penpot design system and powered by real transmission tower inspection data (`400KV_Tower_1_Site_B`).

---

## 1. Selected Tower & Inspected Source Files

* **Tower Identifier**: `400KV_Tower_1_Site_B` (Code: `T01-400KV-SB`)
* **Tower Name**: `400KV Tower 1 (Site B)`
* **Line**: `400KV Line - Site B`
* **Location**: Latitude: `20.80535° N`, Longitude: `85.2851686° E`, Altitude: `43.881 m`
* **Inspection ID**: `INSP_400KV_Tower_1_Site_B_20260328161544`
* **Inspection Date**: `28 Mar 2026`
* **Source Files Inspected**:
  * `data/inspection 1.json` (Full 19,176-line inspection dataset)
  * `data/400KV_Tower_1_Site_B/tower_info.json` (Tower metadata, GPS, and assigned file manifest)
  * `data/400KV_Tower_1_Site_B_inspection_report_reviewed 1.pdf` (80-page formal inspection report)
  * `data/400KV_Tower_1_Site_B/image/` (87 high-resolution RGB drone images, 5184x3888)
  * `data/400KV_Tower_1_Site_B/thermal/` (91 thermal sensor images and video telemetry)

---

## 2. Penpot Design Translation & Screen Hierarchy

The Flutter application mirrors the Penpot design boards (`01 Network map`, `02 Components`, `04 Inspection`, `05 Reference`):

### A. App Bar (`Inspection / App bar`)
* **Branding**: `KnoGrid — TowerLens Intelligence`
* **Breadcrumbs**: `Network › 400KV Line - Site B › 400KV Tower 1 (Site B) › 9 Critical Deficiencies`
* **View Switcher**: Toggle between interactive **Network Map** and **Phase Inspection**.
* **Inspection Report**: Triggers the comprehensive inspection summary modal.

### B. Column 1: Asset Navigator (`Inspection / Asset navigator` — Width: 320px)
* **Hierarchy**: LINE → TOWER (`T01-400KV-SB`) → ASSET TYPE (`Transmission Tower`)
* **Circuit Selector**: `Circuit_SW` vs `Circuit_NE`
* **Phase Selector**: `Phase R`, `Phase Y`, `Phase B` with critical defect counts and badges.
* **Phase Summary Roll-up**:
  * Arcing Horn (Normal)
  * Conductor (Normal)
  * Corona Ring (Normal)
  * Cotter Pin (Normal)
  * **Cotter Pin Missing (Defect — ✕ Critical)**
  * Insulator (Normal)
  * Vibration Damper (Normal)
  * Earthing Wire / Jumper Cable (Not Seen)

### C. Column 2: Tower Structure (`Inspection / Tower structure` — Width: 408px)
* **Metadata**: `400 kV Double Circuit · Suspension`
* **Sensor Mode Toggle**: Real-time switch between **RGB** (`_Z.JPG`) and **Thermal** (`_T.JPG`) whole-tower imagery.
* **Interactive Crossarm Diagram**: Interactive clickable phase markers (`R`, `Y`, `B`) showing real condition states directly on the tower structure.
* **Condition Legend**: Critical (`✕`), Major (`!!`), Minor (`!`), Normal (`✓`), Not inspected (`—`).

### D. Column 3: Phase Inspection & Detailed Crops (`Inspection / Phase inspection` — Width: 712px)
* **Interactive Image Canvas**: Pan and zoom (`InteractiveViewer`) on original 5184×3888 drone photos.
* **AI Bounding Boxes**: Crisp vector overlays with component labels, severity colors, and confidence percentages.
* **Telemetry Capsule**: Original filename, timestamp, and distance to tower (e.g. `14.6 m from tower`).
* **Detailed Crops Carousel**: Horizontal gallery of cropped component inspection cards with status pills and confidence ratings.

### E. Network Map Overview (`01 Network map`)
* **GIS Map Canvas**: Stylized satellite/street map with 400 kV transmission line trajectory.
* **Filters**: Survey date (`28 Mar 2026`, `16 Apr 2026`, `20 Apr 2026`), Voltage (`400 kV`, `220 kV`, `135 kV`), Map/Satellite view.
* **Tower Defect Card**: Floating panel summarizing the 9 critical deficiencies with an instant **"Open in Asset Navigator →"** button.

### F. Summary Modal (`Inspection 6 · Summary`)
* Detailed roll-up of all 9 missing cotter pin defects across `Circuit_SW` and `Circuit_NE`.
* Summary detection counts for all 10 component types.

---

## 3. Local Image Loading Architecture

Inspection images are **loaded on demand directly from your local RAW data folder** without bloating the compiled application:

1. **Windows Desktop (`!kIsWeb`)**:
   Loads directly from local disk via `FileImage(File(path))` at native filesystem speed with zero network latency.
2. **Flutter Web (`kIsWeb`)**:
   Browser security restricts direct filesystem access. Images are served on demand through the included high-performance local image server (`image_server.py`) over HTTP with CORS enabled.

### Image Server (`image_server.py`) Features:
* Serves raw images directly from `c:\flutter_power\data`.
* Real-time `/crop?path=...&x=...&y=...&w=...&h=...` endpoint generating crisp component thumbnails for the crops carousel.

---

## 4. How to Run

### Step 1: Start the Local Image Server (Optional for Desktop, Recommended for Web)
Open a terminal in `c:\flutter_power` and run:

```bash
python image_server.py
```
*(Or double-click `run_image_server.bat`)*

### Step 2: Run the Flutter Frontend

To run on **Windows Desktop**:
```bash
cd flutter_proj
flutter run -d windows
```

To run on **Chrome (Web)**:
```bash
cd flutter_proj
flutter run -d chrome
```

---

## 5. Configuration Paths (`lib/config/app_config.dart`)

To change data or server locations on another machine, update `lib/config/app_config.dart`:
```dart
static const String rawDataLocalPath = r'c:\flutter_power\data';
static const String imageServerBaseUrl = 'http://localhost:8085';
```
