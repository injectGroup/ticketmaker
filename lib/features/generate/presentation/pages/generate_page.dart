import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/auth_gate.dart';
import '../../../tickets/presentation/bloc/tickets_cubit.dart';
import '../bloc/generate_cubit.dart';
import '../widgets/ticket_details_section.dart';
import '../widgets/ticket_header_section.dart';
import '../widgets/ticket_perforation.dart';

class GeneratePage extends StatelessWidget {
  const GeneratePage({super.key});

  static const String routeName = 'generate';
  static const String routePath = '/generate';

  @override
  Widget build(BuildContext context) {
    return const _GenerateView();
  }
}

class _GenerateView extends StatefulWidget {
  const _GenerateView();

  @override
  State<_GenerateView> createState() => _GenerateViewState();
}

class _GenerateViewState extends State<_GenerateView> {
  final TextEditingController _headerLabelController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final GlobalKey _ticketBoundaryKey = GlobalKey();
  bool _isSaving = false;

  /// Bumped after Save Ticket so brackets return for the next ticket.
  int _ticketSession = 0;

  @override
  void initState() {
    super.initState();
    final ticket = context.read<GenerateCubit>().state.ticket;
    _headerLabelController.text = ticket.headerLabel;
    _titleController.text = ticket.title;
    _subtitleController.text = ticket.subtitle;
    _venueController.text = ticket.venue;
  }

  @override
  void dispose() {
    _headerLabelController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _saveTicket() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      // Guests save locally — event photo from GenerateCubit; share composes
      // the full ticket later via SavedTicketView.
      await saveTicketAsGuest(context);
      if (mounted) {
        setState(() => _ticketSession++);
      }
    } on FirebaseException catch (e) {
      debugPrint('Failed to save ticket (FirebaseException): $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not save ticket. Try again.')),
        );
    } catch (e, st) {
      debugPrint('Failed to save ticket: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not save ticket. Try again.')),
        );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Quick Ticket Maker'),
          automaticallyImplyLeading: false,
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<GenerateCubit, GenerateState>(
              listenWhen: (previous, current) =>
                  previous.message != current.message &&
                  current.message != null,
              listener: (context, state) {
                final message = state.message;
                if (message == null) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(message)));
                context.read<GenerateCubit>().clearMessage();
              },
            ),
            BlocListener<GenerateCubit, GenerateState>(
              listenWhen: (previous, current) =>
                  previous.ticket.headerLabel != current.ticket.headerLabel ||
                  previous.ticket.title != current.ticket.title ||
                  previous.ticket.subtitle != current.ticket.subtitle ||
                  previous.ticket.venue != current.ticket.venue ||
                  previous.ticket.eventAt != current.ticket.eventAt,
              listener: (context, state) {
                _headerLabelController.text = state.ticket.headerLabel;
                _titleController.text = state.ticket.title;
                _subtitleController.text = state.ticket.subtitle;
                _venueController.text = state.ticket.venue;
              },
            ),
            BlocListener<TicketsCubit, TicketsState>(
              listenWhen: (previous, current) =>
                  previous.message != current.message &&
                  current.message != null,
              listener: (context, state) {
                final message = state.message;
                if (message == null) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(message)));
                context.read<TicketsCubit>().clearMessage();
              },
            ),
          ],
          child: SafeArea(
            child: ColoredBox(
              color: const Color(0xFFF8FAFC),
              child: BlocBuilder<GenerateCubit, GenerateState>(
                buildWhen: (previous, current) =>
                    previous.ticket != current.ticket ||
                    previous.imageBytes != current.imageBytes,
                builder: (context, state) {
                  final ticket = state.ticket;
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: keyboardInset > 0 ? keyboardInset + 24 : 28,
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: RepaintBoundary(
                              key: _ticketBoundaryKey,
                              child: Column(
                                children: [
                                  TicketHeaderSection(
                                    ticket: ticket,
                                    headerLabelController:
                                        _headerLabelController,
                                    bracketResetToken: _ticketSession,
                                  ),
                                  const TicketPerforation(),
                                  TicketDetailsSection(
                                    ticket: ticket,
                                    titleController: _titleController,
                                    subtitleController: _subtitleController,
                                    venueController: _venueController,
                                    bracketResetToken: _ticketSession,
                                    imageBytes: state.imageBytes,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _saveTicket,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.confirmation_number_outlined,
                                  ),
                            label: Text(
                              _isSaving ? 'Saving…' : 'Save Ticket',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
