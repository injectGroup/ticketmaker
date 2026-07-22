import '../domain/entities/event.dart';

/// Curated sample events in Abuja (no network).
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
      id: 'garki-art-walk',
      title: 'Garki Art Walk',
      venue: 'Garki Area 3 Arts Corridor',
      city: city,
      eventAt: DateTime(2026, 8, 9, 11, 0),
      category: 'Culture',
      description: 'Gallery hop featuring contemporary Nigerian painters and sculptors.',
    ),
    Event(
      id: 'asokoro-food-fest',
      title: 'Asokoro Street Food Fest',
      venue: 'Shehu Shagari Way pop-up lane',
      city: city,
      eventAt: DateTime(2026, 8, 15, 12, 0),
      category: 'Food',
      description: 'Regional dishes, live grilling, and family-friendly tasting stalls.',
    ),
    Event(
      id: 'maitama-gospel-concert',
      title: 'Maitama Gospel Concert',
      venue: 'International Conference Centre',
      city: city,
      eventAt: DateTime(2026, 8, 22, 18, 0),
      category: 'Music',
      description: 'Choirs and contemporary gospel artists in a night of worship music.',
    ),
    Event(
      id: 'wuse-startup-pitch',
      title: 'Wuse Startup Pitch Night',
      venue: 'Co-Creation Hub Abuja, Wuse',
      city: city,
      eventAt: DateTime(2026, 8, 28, 17, 30),
      category: 'Tech',
      description: 'Early-stage founders pitch to local angels and mentors.',
    ),
    Event(
      id: 'millennium-park-picnic',
      title: 'Millennium Park Sunset Picnic',
      venue: 'Millennium Park',
      city: city,
      eventAt: DateTime(2026, 9, 5, 16, 30),
      category: 'Culture',
      description: 'Open-air acoustic sets, blankets welcome, soft drinks on site.',
    ),
    Event(
      id: 'kubwa-basketball-classic',
      title: 'Kubwa Basketball Classic',
      venue: 'Kubwa Indoor Sports Hall',
      city: city,
      eventAt: DateTime(2026, 9, 12, 15, 0),
      category: 'Sports',
      description: 'Inter-community tournament finals with youth exhibition games.',
    ),
  ];
}
