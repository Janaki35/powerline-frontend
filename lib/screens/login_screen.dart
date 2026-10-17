import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/transmission_tower_icon.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();

    if (userId == 'test_user' && password == '123456') {
      setState(() {
        _errorMessage = null;
      });
      widget.onLoginSuccess();
    } else {
      setState(() {
        if (userId.isEmpty || password.isEmpty) {
          _errorMessage = 'Please enter both User ID and password';
        } else {
          _errorMessage = 'Invalid username or password';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = _errorMessage != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: Stack(
        children: [
          // Realistic light GIS / OpenStreetMap style background matching 1.png and 2.png
          Positioned.fill(
            child: CustomPaint(
              painter: _MapRealisticBackgroundPainter(),
            ),
          ),

          // Central Sign In Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo Header (TowerLens Intelligence)
                    Center(
                      child: TowerLensLogo(
                        iconSize: 34,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Title
                    const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    const Text(
                      'Use your TowerLens account to open the network map.',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Banner if invalid credentials
                    if (hasError) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // User ID Label
                    const Text(
                      'User ID',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // User ID Field
                    TextField(
                      controller: _userIdController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g. test_user',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: hasError ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: hasError ? const Color(0xFFEF4444) : const Color(0xFFD1D5DB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: hasError ? const Color(0xFFEF4444) : AppColors.primaryBlue,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Password Label
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        fontSize: 15,
                        letterSpacing: 2.0,
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 16,
                          letterSpacing: 2.0,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: hasError ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: hasError ? const Color(0xFFEF4444) : const Color(0xFFD1D5DB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: hasError ? const Color(0xFFEF4444) : AppColors.primaryBlue,
                            width: 1.5,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      onSubmitted: (_) => _handleSignIn(),
                    ),
                    const SizedBox(height: 28),

                    // Sign in Button
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _handleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Help Text
                    const Text(
                      'Forgot your password? Contact your administrator.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}

/// Realistic map painter representing the open street map background in 1.png and 2.png
class _MapRealisticBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base terrain
    final bgPaint = Paint()..color = const Color(0xFFF7F5EE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Pale green fields & patches
    final fieldPaint1 = Paint()
      ..color = const Color(0xFFE4ECD8)
      ..style = PaintingStyle.fill;
    final fieldPaint2 = Paint()
      ..color = const Color(0xFFDFE9D4)
      ..style = PaintingStyle.fill;
    final yellowFieldPaint = Paint()
      ..color = const Color(0xFFF6F0DC)
      ..style = PaintingStyle.fill;

    // Field 1 (top left park)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, size.height * 0.12, size.width * 0.15, size.height * 0.20),
        const Radius.circular(80),
      ),
      fieldPaint1,
    );

    // Field 2 (top right park)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.75, size.height * 0.10, size.width * 0.16, size.height * 0.22),
        const Radius.circular(50),
      ),
      fieldPaint2,
    );

    // Field 3 (middle field left)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.03, size.height * 0.44, size.width * 0.18, size.height * 0.22),
        const Radius.circular(20),
      ),
      fieldPaint1,
    );

    // Field 4 (middle field center-right)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.36, size.height * 0.48, size.width * 0.18, size.height * 0.24),
        const Radius.circular(16),
      ),
      yellowFieldPaint,
    );

    // Field 5 (middle field right)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.60, size.height * 0.62, size.width * 0.14, size.height * 0.16),
        const Radius.circular(24),
      ),
      fieldPaint1,
    );

    // 3. Roads
    // Main orange highway running horizontally
    final roadCasingPaint = Paint()
      ..color = const Color(0xFFE0BA88)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke;
    final roadInnerPaint = Paint()
      ..color = const Color(0xFFFBE3B5)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke;

    final mainRoad = Path()
      ..moveTo(0, size.height * 0.38)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.36, size.width, size.height * 0.46);
    canvas.drawPath(mainRoad, roadCasingPaint);
    canvas.drawPath(mainRoad, roadInnerPaint);

    // Secondary vertical yellow road
    final secRoadPaint = Paint()
      ..color = const Color(0xFFFDF0A6)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;
    final secRoad = Path()
      ..moveTo(size.width * 0.53, 0)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.5, size.width * 0.57, size.height);
    canvas.drawPath(secRoad, secRoadPaint);

    // Minor streets
    final minorStreetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    final st1 = Path()
      ..moveTo(size.width * 0.56, size.height * 0.58)
      ..lineTo(size.width * 0.74, size.height * 0.54);
    canvas.drawPath(st1, minorStreetPaint);

    // 4. Blue River at bottom
    final riverPaint = Paint()
      ..color = const Color(0xFFBCE1EF)
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final river = Path()
      ..moveTo(0, size.height * 0.94)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.88, size.width * 0.7, size.height * 0.84)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.82, size.width, size.height * 0.87);
    canvas.drawPath(river, riverPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
