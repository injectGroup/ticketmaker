import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../tickets/data/ticket_image_store.dart';
import '../bloc/generate_cubit.dart';
import 'top_bg_color_customizer_sheet.dart';

/// Floating customize bar for QR color/shape, background, photo, and code refresh.
class TicketCustomizeToolbar extends StatelessWidget {
  const TicketCustomizeToolbar({super.key, this.imageStore});

  final TicketImageStore? imageStore;

  Future<void> _pickPhoto(BuildContext context) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !context.mounted) return;

    final store = imageStore ?? TicketImageStore();
    Uint8List? bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      bytes = null;
    }
    final durablePath = await store.import(
      sourcePath: file.path,
      bytes: bytes,
    );
    if (!context.mounted) return;
    final nextPath = durablePath.isNotEmpty ? durablePath : file.path;
    context.read<GenerateCubit>().setImagePath(nextPath);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GenerateCubit>();

    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      color: AppColors.secondaryBackground,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Tool(
              icon: Icons.palette_outlined,
              label: 'Color',
              onTap: cubit.cycleQrColors,
            ),
            _Tool(
              icon: Icons.crop_square_rounded,
              label: 'Shape',
              onTap: cubit.toggleQrShape,
            ),
            _Tool(
              icon: Icons.gradient_rounded,
              label: 'Bg',
              onTap: () => TopBgColorCustomizerSheet.show(context),
            ),
            _Tool(
              icon: Icons.add_photo_alternate_outlined,
              label: 'Photo',
              onTap: () => _pickPhoto(context),
            ),
            _Tool(
              icon: Icons.qr_code_2_rounded,
              label: 'Code',
              onTap: cubit.generateTicketCode,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tool extends StatefulWidget {
  const _Tool({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_Tool> createState() => _ToolState();
}

class _ToolState extends State<_Tool> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
