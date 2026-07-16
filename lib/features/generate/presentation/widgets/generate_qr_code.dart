import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renders a styled QR code with configurable eye/module colors and shapes.
class GenerateQrCode extends StatelessWidget {
  const GenerateQrCode({
    super.key,
    this.width,
    this.height,
    required this.data,
    required this.eyeStyleColor,
    required this.dataModuleStyleColor,
    required this.isSquare,
  });

  final double? width;
  final double? height;
  final String data;
  final Color eyeStyleColor;
  final Color dataModuleStyleColor;
  final bool isSquare;

  @override
  Widget build(BuildContext context) {
    final size = width ?? height ?? 150;

    return SizedBox(
      width: size,
      height: size,
      child: QrImageView(
        data: data,
        size: size,
        backgroundColor: Colors.white,
        eyeStyle: QrEyeStyle(
          color: eyeStyleColor,
          eyeShape: isSquare ? QrEyeShape.square : QrEyeShape.circle,
        ),
        dataModuleStyle: QrDataModuleStyle(
          color: dataModuleStyleColor,
          dataModuleShape:
              isSquare ? QrDataModuleShape.square : QrDataModuleShape.circle,
        ),
      ),
    );
  }
}
