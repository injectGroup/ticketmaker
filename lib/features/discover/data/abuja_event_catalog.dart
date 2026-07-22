import '../domain/entities/event.dart';

/// Curated sample events in Abuja (no network).
/// Category labels align with Generate [TicketCategoryPalettes].
abstract final class AbujaEventCatalog {
  static const String city = 'Abuja';

  static List<Event> all() => List<Event>.unmodifiable(_events);

  static final List<Event> _events = [
    Event(
      id: 'abuja-jazz-night',
      title: 'Abuja Jazz Night',
      venue: 'Transcorp Hilton — Ballroom',
      city: city,
      eventAt: DateTime(2026, 7, 25, 20, 0),
      category: 'Music',
      description: 'Live jazz ensembles and guest vocalists under the city lights.',
    ),
    Event(
      id: 'jabi-lake-comedy',
      title: 'Jabi Lake Comedy Club',
      venue: 'Jabi Lake Mall Amphitheatre',
      city: city,
      eventAt: DateTime(2026, 7, 26, 19, 30),
      category: 'Comedy',
      description: 'Stand-up from Abuja and Lagos comics in an open-air set.',
    ),
    Event(
      id: 'flutter-abuja-meetup',
      title: 'Flutter Abuja Meetup',
      venue: 'Andela Learning Hub, Wuse II',
      city: city,
      eventAt: DateTime(2026, 8, 2, 14, 0),
      category: 'Tech',
      description: 'Talks on Flutter UI patterns, state management, and shipping apps.',
    ),
    Event(
      id: 'national-stadium-friendly',
      title: 'National Stadium Football Friendly',
      venue: 'Moshood Abiola National Stadium',
      city: city,
      eventAt: DateTime(2026, 8, 8, 16, 0),
      category: 'Sports',
      description: 'Exhibition match with youth academies from the FCT.',
    ),
    Event(
      id: 'asokoro-garden-wedding',
      title: 'Asokoro Garden Wedding Fair',
      venue: 'Shehu Musa Yar’Adua Centre gardens',
      city: city,
      eventAt: DateTime(2026, 8, 9, 11, 0),
      category: 'Wedding',
      description: 'Ivory & blush showcase of venues, planners, and live strings.',
    ),
    Event(
      id: 'wuse-birthday-bash',
      title: 'Wuse Kids Birthday Bash',
      venue: 'Jabi Lake Mall Kids Zone',
      city: city,
      eventAt: DateTime(2026, 8, 15, 12, 0),
      category: 'Birthday',
      description: 'Rainbow games, cake stations, and family-friendly DJ sets.',
    ),
    Event(
      id: 'maitama-anniversary-gala',
      title: 'Maitama Anniversary Gala',
      venue: 'Transcorp Hilton — Crystal Ballroom',
      city: city,
      eventAt: DateTime(2026, 8, 22, 18, 0),
      category: 'Anniversary',
      description: 'Gold & white evening celebrating milestone couples.',
    ),
    Event(
      id: 'uniabuja-graduation',
      title: 'UniAbuja Graduation Celebration',
      venue: 'University of Abuja Convocation Arena',
      city: city,
      eventAt: DateTime(2026, 8, 28, 10, 0),
      category: 'Graduation',
      description: 'Black, silver, and gold ceremony with family photo lanes.',
    ),
    Event(
      id: 'gwarinpa-general-party',
      title: 'Gwarinpa Rooftop Party',
      venue: 'Gwarinpa Estate Clubhouse',
      city: city,
      eventAt: DateTime(2026, 9, 5, 20, 0),
      category: 'General party',
      description: 'White & silver night with primary accent lighting and DJs.',
    ),
    Event(
      id: 'central-area-general-event',
      title: 'Central Area Civic Showcase',
      venue: 'International Conference Centre',
      city: city,
      eventAt: DateTime(2026, 9, 12, 15, 0),
      category: 'General event',
      description: 'Cream & gold civic program with exhibitors and guest speakers.',
    ),
  ];
}
