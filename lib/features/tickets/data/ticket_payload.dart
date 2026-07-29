import '../../generate/domain/entities/ticket.dart';

/// Result of decoding a scanned QR / door-entry payload, or web verify.
enum TicketVerifyStatus {
  /// Valid unused ticket — check-in applied.
  success,

  /// Ticket exists but already checked in.
  alreadyCheckedIn,

  /// Code/URL not found in Firestore index.
  notFound,

  /// Scanned text is not a ticketmaker payload.
  invalidPayload,
}

/// Outcome of door / web verification.
class TicketVerifyResult {
  const TicketVerifyResult({
    required this.status,
    this.ticket,
    this.code,
  });

  final TicketVerifyStatus status;
  final Ticket? ticket;
  final String? code;

  bool get isSuccess => status == TicketVerifyStatus.success;

  String get headline {
    switch (status) {
      case TicketVerifyStatus.success:
        return 'CONFIRMED';
      case TicketVerifyStatus.alreadyCheckedIn:
        return 'ALREADY USED';
      case TicketVerifyStatus.notFound:
        return 'INVALID';
      case TicketVerifyStatus.invalidPayload:
        return 'INVALID';
    }
  }

  String get detail {
    switch (status) {
      case TicketVerifyStatus.success:
        return ticket?.title.trim().isNotEmpty == true
            ? ticket!.title
            : 'Guest admitted';
      case TicketVerifyStatus.alreadyCheckedIn:
        return ticket?.title.trim().isNotEmpty == true
            ? '${ticket!.title} was already checked in'
            : 'This ticket was already checked in';
      case TicketVerifyStatus.notFound:
        return code == null
            ? 'No matching ticket'
            : 'No ticket for $code';
      case TicketVerifyStatus.invalidPayload:
        return 'Unrecognized ticket code';
    }
  }
}

/// Parses ticket verification payloads from QR text or path segments.
///
/// Canonical QR URL:
/// `https://quick-ticket-maker-sandbox.web.app/verify/1234-5678-910`
///
/// Also accepts legacy `ticketmaker.app/t/<code>` and bare codes.
class TicketPayload {
  TicketPayload._();

  static const String host = 'quick-ticket-maker-sandbox.web.app';
  static const String pathPrefix = '/verify/';

  static const Set<String> allowedHosts = {
    host,
    'quick-ticket-maker-sandbox.firebaseapp.com',
    'ticketmaker.app',
    'www.ticketmaker.app',
    'localhost',
  };

  static final RegExp codePattern = RegExp(r'^\d{4}-\d{4}-\d{3}$');

  /// Builds the live Hosting verification URL encoded in ticket QR codes.
  static String verificationUrl(String code) => 'https://$host/verify/$code';

  /// Extracts a ticket [code] from raw scan text, path id, or null if invalid.
  static String? parseCode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (codePattern.hasMatch(trimmed)) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    final hostOk = uri.host.isEmpty ||
        allowedHosts.contains(uri.host) ||
        (uri.host.endsWith('.web.app') &&
            uri.host.contains('quick-ticket-maker'));
    if (!hostOk) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 &&
        (segments[0] == 'verify' || segments[0] == 't')) {
      final code = segments[1].trim();
      if (codePattern.hasMatch(code)) return code;
    }

    for (final prefix in [pathPrefix, '/t/']) {
      if (uri.path.startsWith(prefix)) {
        final code = uri.path.substring(prefix.length).split('/').first.trim();
        if (codePattern.hasMatch(code)) return code;
      }
    }
    return null;
  }
}
