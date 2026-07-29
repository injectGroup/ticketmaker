import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../tickets/data/ticket_payload.dart';
import '../../../tickets/data/ticket_public_verify.dart';

/// Public Hosting route `/verify/:code` — gatekeeper confirmation (no auth).
class TicketVerifyPage extends StatefulWidget {
  const TicketVerifyPage({
    super.key,
    required this.code,
    this.verifier,
  });

  final String code;
  final TicketPublicVerify? verifier;

  static const String routeName = 'verify';
  static const String routePath = '/verify/:code';

  @override
  State<TicketVerifyPage> createState() => _TicketVerifyPageState();
}

class _TicketVerifyPageState extends State<TicketVerifyPage> {
  late final Future<TicketVerifyResult> _future;

  @override
  void initState() {
    super.initState();
    final verifier = widget.verifier ?? TicketPublicVerify();
    _future = verifier.verifyAndCheckIn(widget.code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: FutureBuilder<TicketVerifyResult>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final result = snapshot.data ??
                TicketVerifyResult(
                  status: TicketVerifyStatus.notFound,
                  code: TicketPayload.parseCode(widget.code),
                );

            return _VerifyResultView(result: result);
          },
        ),
      ),
    );
  }
}

class _VerifyResultView extends StatelessWidget {
  const _VerifyResultView({required this.result});

  final TicketVerifyResult result;

  @override
  Widget build(BuildContext context) {
    final success = result.isSuccess;
    final color = success ? const Color(0xFF16A34A) : AppColors.error;
    final icon = success ? Icons.check_circle : Icons.cancel;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Quick Ticket Maker',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.4,
                    ),
              ),
              const SizedBox(height: 28),
              Material(
                color: color,
                borderRadius: BorderRadius.circular(20),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  child: Column(
                    children: [
                      Icon(icon, color: Colors.white, size: 72),
                      const SizedBox(height: 16),
                      Text(
                        result.headline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        result.detail,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                      if (result.code != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          result.code!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                success
                    ? 'Guest checked in successfully.'
                    : 'Do not admit this guest.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
