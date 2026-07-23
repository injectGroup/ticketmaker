import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../presentation/atoms/app_button.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/widgets/auth_flow_sheet.dart';
import '../../../discover/data/event_catalog.dart';
import '../../../generate/data/ticket_category_palettes.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, this.personalize = false});

  static const String routeName = 'account';
  static const String routePath = '/account';

  final bool personalize;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  static const _interestOptions = [
    TicketCategoryPalettes.music,
    TicketCategoryPalettes.tech,
    TicketCategoryPalettes.sports,
    'Arts',
    TicketCategoryPalettes.comedy,
  ];

  final _personalizeKey = GlobalKey();
  String? _preferredCity;
  late Set<String> _interests;

  @override
  void initState() {
    super.initState();
    _syncFromUser(context.read<AuthCubit>().state);
    if (widget.personalize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _personalizeKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            alignment: 0.1,
          );
        }
      });
    }
  }

  void _syncFromUser(AuthState state) {
    final user = state.user;
    _preferredCity = user?.preferredCity;
    _interests = {...?user?.interests};
  }

  Future<void> _saveProfile() async {
    await context.read<AuthCubit>().updateProfile(
      preferredCity: _preferredCity,
      interests: _interests.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cities = EventCatalog.cities();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Account'),
        automaticallyImplyLeading: false,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (p, c) =>
            p.message != c.message && c.message != null ||
            p.user != c.user,
        listener: (context, state) {
          if (state.user != null) {
            setState(() => _syncFromUser(state));
          }
          final message = state.message;
          if (message == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
          context.read<AuthCubit>().clearMessage();
        },
        builder: (context, state) {
          if (!state.isAuthenticated) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outlined,
                      size: 56,
                      color: AppColors.secondaryText.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text('Your account', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to book spots, save tickets, and personalize Discover.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Sign In / Sign Up',
                      icon: Icons.login,
                      onPressed: () => showAuthFlow(context),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = state.user!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Card(
                color: AppColors.secondaryBackground,
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user.displayName),
                  subtitle: Text(user.email),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                key: _personalizeKey,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.personalize
                      ? AppColors.primary.withValues(alpha: 0.06)
                      : AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: widget.personalize
                      ? Border.all(color: AppColors.primary.withValues(alpha: 0.35))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Profile preferences',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.personalize) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Choose your city and interests to finish setup.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text('Preferred location / city', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final city in cities)
                          ChoiceChip(
                            label: Text(city),
                            selected: _preferredCity == city,
                            onSelected: (selected) {
                              setState(() {
                                _preferredCity = selected ? city : null;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Favorite genres / interests',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final interest in _interestOptions)
                          FilterChip(
                            label: Text(interest),
                            selected: _interests.contains(interest),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _interests.add(interest);
                                } else {
                                  _interests.remove(interest);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: state.isSubmitting ? 'Saving…' : 'Save preferences',
                      onPressed: state.isSubmitting ? null : _saveProfile,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.read<AuthCubit>().signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}
