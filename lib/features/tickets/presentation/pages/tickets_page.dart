import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Placeholder tickets list — expands when persistence is added.
class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  static const String routeName = 'tickets';
  static const String routePath = '/tickets';

  static const _sampleTickets = [
    (
      title: 'Circu Du Freak',
      subtitle: 'Vision & Sound Experience',
      code: '1234-5678-910',
      when: 'Sat, Jul 18 · 8:00 PM',
    ),
    (
      title: 'Neon Nights',
      subtitle: 'Live DJ Set',
      code: '2468-1357-902',
      when: 'Fri, Aug 1 · 10:00 PM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('My Tickets'),
        automaticallyImplyLeading: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _sampleTickets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final ticket = _sampleTickets[index];
          return Material(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.confirmation_number_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ticket.title, style: theme.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            ticket.subtitle,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.when,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      ticket.code,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
