import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/utils/color_contrast.dart';

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
    this.backgroundColor,
  });

  final double? width;
  final double? height;
  final String data;
  final Color eyeStyleColor;
  final Color dataModuleStyleColor;
  final bool isSquare;

  /// When null, picks a high-contrast pad from [dataModuleStyleColor].
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final size = width ?? height ?? 150;
    final pad =
        backgroundColor ?? ColorContrast.qrPadForPattern(dataModuleStyleColor);

    // Nearest-neighbor / high filter quality keeps module edges crisp when
    // the QR layer is composited or scaled (avoids soft blur).
    return SizedBox(
      width: size,
      height: size,
      child: Transform.scale(
        scale: 1,
        filterQuality: FilterQuality.none,
        child: QrImageView(
          data: data,
          size: size,
          gapless: true,
          backgroundColor: pad,
          eyeStyle: QrEyeStyle(
            color: eyeStyleColor,
            eyeShape: isSquare ? QrEyeShape.square : QrEyeShape.circle,
          ),
          dataModuleStyle: QrDataModuleStyle(
            color: dataModuleStyleColor,
            dataModuleShape: isSquare
                ? QrDataModuleShape.square
                : QrDataModuleShape.circle,
          ),
        ),
      ),
    );
  }
}
