part of 'auth_cubit.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.message,
    this.justSignedUp = false,
    this.pendingAction,
  });

  final AuthStatus status;
  final AppUser? user;
  final bool isSubmitting;
  final String? message;
  final bool justSignedUp;
  final PendingAuthAction? pendingAction;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isSubmitting,
    String? message,
    bool? justSignedUp,
    PendingAuthAction? pendingAction,
    bool clearUser = false,
    bool clearMessage = false,
    bool clearPending = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      message: clearMessage ? null : (message ?? this.message),
      justSignedUp: justSignedUp ?? this.justSignedUp,
      pendingAction: clearPending
          ? null
          : (pendingAction ?? this.pendingAction),
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    isSubmitting,
    message,
    justSignedUp,
    pendingAction,
  ];
}
