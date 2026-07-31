import 'package:flutter/material.dart';

import '../../../generate/domain/entities/ticket.dart';
import '../../../tickets/data/ticket_payload.dart';
import '../../../tickets/data/ticket_public_verify.dart';

/// Public Hosting route `/verify/:id` — external QR gatekeeper confirmation.
class TicketVerificationScreen extends StatefulWidget {
  const TicketVerificationScreen({
    super.key,
    required this.ticketId,
    this.verifier,
  });

  /// Guest code from the URL (`####-####-###`).
  final String ticketId;
  final TicketPublicVerify? verifier;

  static const String routeName = 'verify';
  static const String routePath = '/verify/:id';

  @override
  State<TicketVerificationScreen> createState() =>
      _TicketVerificationScreenState();
}

class _TicketVerificationScreenState extends State<TicketVerificationScreen> {
  late final Future<TicketVerifyResult> _future;

  @override
  void initState() {
    super.initState();
    final verifier = widget.verifier ?? TicketPublicVerify();
    _future = verifier.verifyAndCheckIn(widget.ticketId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TicketVerifyResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final result = snapshot.data ??
            TicketVerifyResult(
              status: TicketVerifyStatus.notFound,
              code: TicketPayload.parseCode(widget.ticketId),
            );

        return _VerificationResultScaffold(result: result);
      },
    );
  }
}

class _VerificationResultScaffold extends StatelessWidget {
  const _VerificationResultScaffold({required this.result});

  final TicketVerifyResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = _schemeFor(result.status);

    return Scaffold(
      backgroundColor: scheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(scheme.icon, color: Colors.white, size: 88),
                  const SizedBox(height: 20),
                  Text(
                    scheme.headline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      letterSpacing: 0.4,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (result.status == TicketVerifyStatus.success &&
                      result.ticket != null)
                    _TicketDetailsCard(ticket: result.ticket!)
                  else if (result.status ==
                          TicketVerifyStatus.alreadyCheckedIn &&
                      result.ticket != null)
                    _AlreadyUsedCard(ticket: result.ticket!)
                  else if (result.status == TicketVerifyStatus.checkInFailed) ...[
                    Text(
                      result.detail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    if (result.code != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        result.code!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ] else if (result.code != null)
                    Text(
                      result.code!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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

  static _VerifyScheme _schemeFor(TicketVerifyStatus status) {
    switch (status) {
      case TicketVerifyStatus.success:
        return const _VerifyScheme(
          background: Color(0xFF15803D),
          icon: Icons.check_circle,
          headline: 'CONFIRMED - TICKET VALID',
        );
      case TicketVerifyStatus.alreadyCheckedIn:
        return const _VerifyScheme(
          background: Color(0xFFEA580C),
          icon: Icons.warning_amber_rounded,
          headline: 'WARNING: TICKET ALREADY USED',
        );
      case TicketVerifyStatus.checkInFailed:
        return const _VerifyScheme(
          background: Color(0xFFB45309),
          icon: Icons.error_outline,
          headline: 'CHECK-IN FAILED — TRY AGAIN',
        );
      case TicketVerifyStatus.notFound:
      case TicketVerifyStatus.invalidPayload:
        return const _VerifyScheme(
          background: Color(0xFFDC2626),
          icon: Icons.cancel,
          headline: 'INVALID TICKET - TICKET NOT FOUND',
        );
    }
  }
}

class _VerifyScheme {
  const _VerifyScheme({
    required this.background,
    required this.icon,
    required this.headline,
  });

  final Color background;
  final IconData icon;
  final String headline;
}

class _TicketDetailsCard extends StatelessWidget {
  const _TicketDetailsCard({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final date = ticket.dateLabel.trim().isNotEmpty
        ? ticket.dateLabel
        : _formatDay(ticket.eventAt);
    final time = ticket.timeLabel.trim();
    final when = time.isEmpty ? date : '$date · $time';

    return _GlassCard(
      children: [
        _DetailRow(label: 'Event', value: ticket.title),
        _DetailRow(label: 'Date', value: when),
        if (ticket.venue.trim().isNotEmpty)
          _DetailRow(label: 'Venue', value: ticket.venue),
        _DetailRow(label: 'Guest Code', value: ticket.code),
      ],
    );
  }
}

class _AlreadyUsedCard extends StatelessWidget {
  const _AlreadyUsedCard({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final checkedIn = ticket.checkedInAt;
    final stamp = checkedIn == null
        ? 'Previously checked in'
        : _formatStamp(checkedIn.toLocal());

    return _GlassCard(
      children: [
        if (ticket.title.trim().isNotEmpty)
          _DetailRow(label: 'Event', value: ticket.title),
        _DetailRow(label: 'Checked in', value: stamp),
        _DetailRow(label: 'Guest Code', value: ticket.code),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

String _formatDay(DateTime dt) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

String _formatStamp(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '${_formatDay(dt)} · $h:$m $ampm';
}
