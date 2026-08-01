import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/utils/color_contrast.dart';

/// Renders a styled QR code with configurable eye/module colors and shapes.
///
/// The ticket's palette is honoured only as far as a reader can still follow
/// it: the code is drawn dark on [ColorContrast.qrField], and a colour too
/// pale to scan gives way to ink. A guest whose code will not open the door
/// has no ticket, however well it matches the card.
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

  /// When null, the light field a reader expects behind the modules.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final size = width ?? height ?? 150;
    final pad = backgroundColor ?? ColorContrast.qrField;

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
            color: ColorContrast.qrInk(eyeStyleColor),
            eyeShape: isSquare ? QrEyeShape.square : QrEyeShape.circle,
          ),
          dataModuleStyle: QrDataModuleStyle(
            color: ColorContrast.qrInk(dataModuleStyleColor),
            dataModuleShape: isSquare
                ? QrDataModuleShape.square
                : QrDataModuleShape.circle,
          ),
        ),
      ),
    );
  }
}
