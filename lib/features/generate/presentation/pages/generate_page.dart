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

class _GenerateView extends StatelessWidget {
  const _GenerateView();

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
                builder: (context, state) {
                  final ticket = state.ticket;
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        TicketHeaderSection(ticket: ticket),
                        const TicketPerforation(),
                        TicketDetailsSection(ticket: ticket),
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
