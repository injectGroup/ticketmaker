import 'package:flutter/material.dart';

/// Displays FREE in green, or a formatted ₦ amount (e.g. ₦8000.00).
class PriceLabel extends StatelessWidget {
  const PriceLabel({super.key, required this.rawPrice});

  final String rawPrice;

  static const Color _freeGreen = Color(0xFF2E7D32);

  static bool isFree(String raw) {
    final normalized = raw.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'free' ||
        normalized == '₦0' ||
        normalized == '₦0.00' ||
        normalized == '0' ||
        normalized == '0.00';
  }

  /// Parses catalog strings like `₦8,500` into `₦8500.00`.
  static String formatPaid(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d.]'), '');
    if (digits.isEmpty) return raw.trim();
    final value = double.tryParse(digits);
    if (value == null) return raw.trim();
    final whole = value.truncate();
    final cents = ((value - whole) * 100).round().abs().toString().padLeft(
      2,
      '0',
    );
    return '₦$whole.$cents';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final free = isFree(rawPrice);
    final text = free ? 'FREE' : formatPaid(rawPrice);

    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: free ? _freeGreen : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
