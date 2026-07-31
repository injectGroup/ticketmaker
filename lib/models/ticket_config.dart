import 'dart:convert';

/// Lightweight ticket metadata persisted in secure storage.
class TicketConfig {
  const TicketConfig({
    required this.eventName,
    required this.subtitle,
    required this.payloadUrl,
    required this.guestName,
    required this.generatedAt,
  });

  final String eventName;
  final String subtitle;
  final String payloadUrl;
  final String guestName;
  final DateTime generatedAt;

  /// Default v1 template used when the generator has no custom title yet.
  factory TicketConfig.v1Default({required String guestName}) {
    return TicketConfig(
      eventName: "Ejike's Birthday Bash",
      subtitle: 'VIP Guest Pass',
      payloadUrl: 'https://quick-ticket-maker-sandbox.web.app/verify/',
      guestName: guestName,
      generatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'eventName': eventName,
        'subtitle': subtitle,
        'payloadUrl': payloadUrl,
        'guestName': guestName,
        'generatedAt': generatedAt.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory TicketConfig.fromJson(Map<String, dynamic> json) {
    return TicketConfig(
      eventName: json['eventName'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      payloadUrl: json['payloadUrl'] as String? ?? '',
      guestName: json['guestName'] as String? ?? '',
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory TicketConfig.fromJsonString(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid TicketConfig JSON');
    }
    return TicketConfig.fromJson(decoded);
  }
}
