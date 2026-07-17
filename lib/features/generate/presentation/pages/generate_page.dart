import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
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
    return BlocProvider(
      create: (_) => GenerateCubit(),
      child: const _GenerateView(),
    );
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
        body: BlocListener<GenerateCubit, GenerateState>(
          listenWhen: (previous, current) =>
              previous.message != current.message && current.message != null,
          listener: (context, state) {
            final message = state.message;
            if (message == null) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
            context.read<GenerateCubit>().clearMessage();
          },
          child: SafeArea(
            child: ColoredBox(
              color: AppColors.secondaryBackground,
              child: BlocBuilder<GenerateCubit, GenerateState>(
                buildWhen: (previous, current) {
                  final p = previous.ticket;
                  final c = current.ticket;
                  return p.code != c.code ||
                      p.qrData != c.qrData ||
                      p.imageUrl != c.imageUrl ||
                      p.eyeColor != c.eyeColor ||
                      p.dataModuleColor != c.dataModuleColor ||
                      p.isSquare != c.isSquare ||
                      p.topGradientStart != c.topGradientStart ||
                      p.topGradientEnd != c.topGradientEnd ||
                      p.bottomGradientStart != c.bottomGradientStart ||
                      p.bottomGradientEnd != c.bottomGradientEnd ||
                      p.dateLabel != c.dateLabel ||
                      p.timeLabel != c.timeLabel;
                },
                builder: (context, state) {
                  final ticket = state.ticket;
                  final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      children: [
                        TicketHeaderSection(
                          ticket: ticket,
                          headerLabelController: _headerLabelController,
                        ),
                        const TicketPerforation(),
                        TicketDetailsSection(
                          ticket: ticket,
                          titleController: _titleController,
                          subtitleController: _subtitleController,
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
