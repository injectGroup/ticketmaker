import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
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
  late final TextEditingController _headerLabelController;
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  bool _isSaving = false;

  /// Bumped after Save Ticket so bracket hints return for the next ticket.
  int _ticketSession = 0;

  @override
  void initState() {
    super.initState();
    final ticket = context.read<GenerateCubit>().state.ticket;
    _headerLabelController = TextEditingController(text: ticket.headerLabel);
    _titleController = TextEditingController(text: ticket.title);
    _subtitleController = TextEditingController(text: ticket.subtitle);
  }

  @override
  void dispose() {
    _headerLabelController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  void _syncControllersFromTicket() {
    final ticket = context.read<GenerateCubit>().state.ticket;
    _headerLabelController.text = ticket.headerLabel;
    _titleController.text = ticket.title;
    _subtitleController.text = ticket.subtitle;
  }

  Future<void> _saveTicket() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await requireAuthThenSaveTicket(context);
      if (!mounted) return;
      _syncControllersFromTicket();
      _ticketSession++;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
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
                  previous.ticket.eventAt != current.ticket.eventAt,
              listener: (context, state) {
                _headerLabelController.text = state.ticket.headerLabel;
                _titleController.text = state.ticket.title;
                _subtitleController.text = state.ticket.subtitle;
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
              color: AppColors.secondaryBackground,
              child: BlocBuilder<GenerateCubit, GenerateState>(
                buildWhen: (previous, current) =>
                    previous.ticket != current.ticket,
                builder: (context, state) {
                  final ticket = state.ticket;
                  final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: bottomInset + 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      children: [
                        TicketHeaderSection(
                          ticket: ticket,
                          headerLabelController: _headerLabelController,
                          bracketResetToken: _ticketSession,
                        ),
                        const TicketPerforation(),
                        TicketDetailsSection(
                          ticket: ticket,
                          titleController: _titleController,
                          subtitleController: _subtitleController,
                          bracketResetToken: _ticketSession,
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isSaving ? null : _saveTicket,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _isSaving ? 'Saving…' : 'Save Ticket',
                              ),
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
