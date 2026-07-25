import 'package:equatable/equatable.dart';

/// Action to run after successful authentication.
sealed class PendingAuthAction extends Equatable {
  const PendingAuthAction();
}

class PendingSaveTicketAction extends PendingAuthAction {
  const PendingSaveTicketAction();

  @override
  List<Object?> get props => const [];
}
