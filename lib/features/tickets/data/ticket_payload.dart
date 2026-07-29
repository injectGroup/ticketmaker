import '../../generate/domain/entities/ticket.dart';

/// Result of decoding a scanned QR / manual door-entry payload.
enum TicketVerifyStatus {
  /// Valid unused ticket — check-in applied.
  success,

  /// Ticket exists but already checked in.
  alreadyCheckedIn,

  /// Code/URL not found in host tickets.
  notFound,

  /// Scanned text is not a ticketmaker payload.
  invalidPayload,
}

/// Outcome of [TicketsCubit.verifyAndCheckIn].
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
        return 'ALREADY CHECKED IN';
      case TicketVerifyStatus.notFound:
        return 'INVALID TICKET';
      case TicketVerifyStatus.invalidPayload:
        return 'UNRECOGNIZED CODE';
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
            ? '${ticket!.title} was already used'
            : 'This ticket was already used';
      case TicketVerifyStatus.notFound:
        return code == null
            ? 'No matching ticket on this device'
            : 'No ticket for $code';
      case TicketVerifyStatus.invalidPayload:
        return 'Scan a Quick Ticket Maker guest pass QR';
    }
  }
}

/// Parses ticket verification payloads from QR text or manual entry.
///
/// Accepted forms:
/// - `https://ticketmaker.app/t/1234-5678-910`
/// - `http://ticketmaker.app/t/1234-5678-910`
/// - bare `1234-5678-910`
class TicketPayload {
  TicketPayload._();

  static const String host = 'ticketmaker.app';
  static const String pathPrefix = '/t/';

  static final RegExp codePattern = RegExp(r'^\d{4}-\d{4}-\d{3}$');

  /// Builds the canonical verification URL encoded in ticket QR codes.
  static String verificationUrl(String code) => 'https://$host/t/$code';

  /// Extracts a ticket [code] from raw scan text, or null if invalid.
  static String? parseCode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (codePattern.hasMatch(trimmed)) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (uri.host != host && uri.host != 'www.$host') return null;

    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 't') {
      final code = segments[1].trim();
      if (codePattern.hasMatch(code)) return code;
    }

    // Fallback: path `/t/CODE`
    final path = uri.path;
    if (path.startsWith(pathPrefix)) {
      final code = path.substring(pathPrefix.length).split('/').first.trim();
      if (codePattern.hasMatch(code)) return code;
    }
    return null;
  }
}
