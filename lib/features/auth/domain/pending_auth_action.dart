import 'package:equatable/equatable.dart';

import '../../discover/domain/entities/event.dart';

/// Action to run after successful authentication.
sealed class PendingAuthAction extends Equatable {
  const PendingAuthAction();
}

class PendingBookAction extends PendingAuthAction {
  const PendingBookAction(this.event);
  final Event event;

  @override
  List<Object?> get props => [event];
}

class PendingSaveTicketAction extends PendingAuthAction {
  const PendingSaveTicketAction();

  @override
  List<Object?> get props => const [];
}
