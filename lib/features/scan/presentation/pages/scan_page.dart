import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../tickets/data/ticket_payload.dart';
import '../../../tickets/presentation/bloc/tickets_cubit.dart';

/// Door entrance QR scanner — verify guest passes and mark check-in.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  static const String routeName = 'scan';
  static const String routePath = '/scan';

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController? _controller =
      kIsWeb ? null : MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
          torchEnabled: false,
        );

  final TextEditingController _manualController = TextEditingController();
  TicketVerifyResult? _result;
  bool _busy = false;
  bool _torchOn = false;
  DateTime? _lastScanAt;

  bool get _cameraSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  void dispose() {
    _manualController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final now = DateTime.now();
    if (_lastScanAt != null &&
        now.difference(_lastScanAt!) < const Duration(milliseconds: 1600)) {
      return;
    }
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .map((s) => s.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;
    _lastScanAt = now;
    await _verify(raw);
  }

  Future<void> _verify(String raw) async {
    if (_busy || !mounted) return;
    setState(() {
      _busy = true;
      _result = null;
    });

    final result =
        await context.read<TicketsCubit>().verifyAndCheckIn(raw);
    if (!mounted) return;

    setState(() {
      _result = result;
      _busy = false;
    });

    if (result.isSuccess) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    } else {
      HapticFeedback.heavyImpact();
    }

    // Auto-clear banner so the next guest can scan.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (_result == result) {
      setState(() => _result = null);
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.toggleTorch();
      setState(() => _torchOn = !_torchOn);
    } catch (e) {
      debugPrint('Torch toggle failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Door Scan'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_cameraSupported)
            IconButton(
              tooltip: _torchOn ? 'Torch off' : 'Torch on',
              onPressed: _toggleTorch,
              icon: Icon(
                _torchOn ? Icons.flash_on : Icons.flash_off,
                color: _torchOn ? Colors.amber : Colors.white,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_cameraSupported && _controller != null)
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  )
                else
                  _UnsupportedCameraPane(
                    onSubmitCode: _verify,
                    controller: _manualController,
                  ),
                if (_cameraSupported)
                  const IgnorePointer(child: _ScanFrameOverlay()),
                if (_busy)
                  const ColoredBox(
                    color: Color(0x66000000),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                if (_result != null)
                  _ResultBanner(result: _result!),
              ],
            ),
          ),
          Material(
            color: const Color(0xFF111827),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Scan guest pass QR (`ticketmaker.app/t/…`)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_cameraSupported) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _manualController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Or enter code ####-####-###',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            tooltip: 'Verify',
                            onPressed: () =>
                                _verify(_manualController.text),
                            icon: const Icon(Icons.check, color: Colors.white),
                          ),
                        ),
                        onSubmitted: _verify,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnsupportedCameraPane extends StatelessWidget {
  const _UnsupportedCameraPane({
    required this.onSubmitCode,
    required this.controller,
  });

  final Future<void> Function(String raw) onSubmitCode;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0F172A),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner, size: 64, color: Colors.white54),
                const SizedBox(height: 16),
                Text(
                  'Camera scanning needs iOS or Android.\nEnter a guest code to verify.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '####-####-### or ticket URL',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: onSubmitCode,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => onSubmitCode(controller.text),
                  child: const Text('Verify ticket'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FramePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 24),
      width: size.width * 0.7,
      height: size.width * 0.7,
    );
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const corner = 28.0;
    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(corner, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, corner), paint);
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-corner, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, corner), paint);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(corner, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -corner), paint);
    // Bottom-right
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(-corner, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(0, -corner),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result});

  final TicketVerifyResult result;

  @override
  Widget build(BuildContext context) {
    final success = result.isSuccess;
    final color = success ? const Color(0xFF16A34A) : AppColors.error;
    final icon = success ? Icons.check_circle : Icons.cancel;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(16),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.headline,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.detail,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        if (result.code != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            result.code!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}
