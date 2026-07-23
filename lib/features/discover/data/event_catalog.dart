import '../domain/entities/event.dart';

/// Curated sample events across cities.
/// Category labels align with Generate [TicketCategoryPalettes].
/// Hero photos use stable picsum seeds (HTTPS); palette fallback on load failure.
abstract final class EventCatalog {
  static const String defaultCity = 'Abuja';

  static String _photo(String seed) =>
      'https://picsum.photos/seed/$seed/800/450';

  static List<Event> all() => List<Event>.unmodifiable(_events);

  static List<String> cities() {
    final set = <String>{};
    for (final event in _events) {
      set.add(event.city);
    }
    final list = set.toList()..sort();
    return List<String>.unmodifiable(list);
  }

  static final List<Event> _events = [
    Event(
      id: 'abuja-jazz-night',
      title: 'Abuja Jazz Night',
      venue: 'Transcorp Hilton — Ballroom',
      city: 'Abuja',
      eventAt: DateTime(2026, 7, 25, 20, 0),
      category: 'Music',
      description:
          'Live jazz ensembles and guest vocalists under the city lights.',
      host: 'Capital Jazz Collective',
      priceLabel: '₦8,500',
      imageUrl: _photo('abuja-jazz-night'),
    ),
    Event(
      id: 'jabi-lake-comedy',
      title: 'Jabi Lake Comedy Club',
      venue: 'Jabi Lake Mall Amphitheatre',
      city: 'Abuja',
      eventAt: DateTime(2026, 7, 26, 19, 30),
      category: 'Comedy',
      description: 'Stand-up from Abuja and Lagos comics in an open-air set.',
      host: 'Laugh Yard Abuja',
      priceLabel: '₦4,000',
      imageUrl: _photo('jabi-lake-comedy'),
    ),
    Event(
      id: 'flutter-abuja-meetup',
      title: 'Flutter Abuja Meetup',
      venue: 'Andela Learning Hub, Wuse II',
      city: 'Abuja',
      eventAt: DateTime(2026, 8, 2, 14, 0),
      category: 'Tech',
      description:
          'Talks on Flutter UI patterns, state management, and shipping apps.',
      host: 'Flutter Abuja',
      priceLabel: 'Free',
      imageUrl: _photo('flutter-abuja-meetup'),
    ),
    Event(
      id: 'national-stadium-friendly',
      title: 'National Stadium Football Friendly',
      venue: 'Moshood Abiola National Stadium',
      city: 'Abuja',
      eventAt: DateTime(2026, 8, 8, 16, 0),
      category: 'Sports',
      description: 'Exhibition match with youth academies from the FCT.',
      host: 'FCT Sports Council',
      priceLabel: '₦2,000',
      imageUrl: _photo('national-stadium-friendly'),
    ),
    Event(
      id: 'asokoro-garden-wedding',
      title: 'Asokoro Garden Wedding Fair',
      venue: 'Shehu Musa Yar’Adua Centre gardens',
      city: 'Abuja',
      eventAt: DateTime(2026, 8, 9, 11, 0),
      category: 'Wedding',
      description: 'Ivory & blush showcase of venues, planners, and live strings.',
      host: 'Bloom Events NG',
      priceLabel: '₦3,500',
      imageUrl: _photo('asokoro-garden-wedding'),
    ),
    Event(
      id: 'wuse-birthday-bash',
      title: 'Wuse Kids Birthday Bash',
      venue: 'Jabi Lake Mall Kids Zone',
      city: 'Abuja',
      eventAt: DateTime(2026, 8, 15, 12, 0),
      category: 'Birthday',
      description: 'Rainbow games, cake stations, and family-friendly DJ sets.',
      host: 'Party Pop Kids',
      priceLabel: '₦6,000',
      imageUrl: _photo('wuse-birthday-bash'),
    ),
    Event(
      id: 'maitama-anniversary-gala',
      title: 'Maitama Anniversary Gala',
      venue: 'Transcorp Hilton — Crystal Ballroom',
      city: 'Abuja',
      eventAt: DateTime(2026, 8, 22, 18, 0),
      category: 'Anniversary',
      description: 'Gold & white evening celebrating milestone couples.',
      host: 'Golden Hour Hosts',
      priceLabel: '₦15,000',
      imageUrl: _photo('maitama-anniversary-gala'),
    ),
    Event(
      id: 'uniabuja-graduation',
      title: 'UniAbuja Graduation Celebration',
      venue: 'University of Abuja Convocation Arena',
      city: 'Abuja',
      eventAt: DateTime(2026, 8, 28, 10, 0),
      category: 'Graduation',
      description: 'Black, silver, and gold ceremony with family photo lanes.',
      host: 'UniAbuja Alumni',
      priceLabel: 'Free',
      imageUrl: _photo('uniabuja-graduation'),
    ),
    Event(
      id: 'gwarinpa-general-party',
      title: 'Gwarinpa Rooftop Party',
      venue: 'Gwarinpa Estate Clubhouse',
      city: 'Abuja',
      eventAt: DateTime(2026, 9, 5, 20, 0),
      category: 'General party',
      description: 'White & silver night with primary accent lighting and DJs.',
      host: 'Rooftop Society',
      priceLabel: '₦7,500',
      imageUrl: _photo('gwarinpa-general-party'),
    ),
    Event(
      id: 'central-area-general-event',
      title: 'Central Area Civic Showcase',
      venue: 'International Conference Centre',
      city: 'Abuja',
      eventAt: DateTime(2026, 9, 12, 15, 0),
      category: 'General event',
      description: 'Cream & gold civic program with exhibitors and guest speakers.',
      host: 'FCT Civic Arts',
      priceLabel: 'Free',
      imageUrl: _photo('central-area-general-event'),
    ),
    Event(
      id: 'lagos-afrobeats-night',
      title: 'Lagos Afrobeats Night',
      venue: 'Eko Convention Centre',
      city: 'Lagos',
      eventAt: DateTime(2026, 7, 28, 21, 0),
      category: 'Music',
      description: 'High-energy Afrobeats showcase with rising Lagos artists.',
      host: 'Mainland Sound',
      priceLabel: '₦12,000',
      imageUrl: _photo('lagos-afrobeats-night'),
    ),
    Event(
      id: 'lagos-tech-summit',
      title: 'Lagos Mobile Dev Summit',
      venue: 'Landmark Event Centre, Victoria Island',
      city: 'Lagos',
      eventAt: DateTime(2026, 8, 5, 9, 0),
      category: 'Tech',
      description: 'Workshops on Flutter, Kotlin, and shipping to production.',
      host: 'DevCircle Lagos',
      priceLabel: '₦5,000',
      imageUrl: _photo('lagos-tech-summit'),
    ),
    Event(
      id: 'lagos-comedy-basement',
      title: 'Comedy Basement VI',
      venue: 'Terra Kulture, Victoria Island',
      city: 'Lagos',
      eventAt: DateTime(2026, 8, 14, 19, 0),
      category: 'Comedy',
      description: 'Intimate stand-up night with Lagos circuit headliners.',
      host: 'Basement Tickets',
      priceLabel: '₦6,500',
      imageUrl: _photo('lagos-comedy-basement'),
    ),
    Event(
      id: 'ph-riverfront-sports',
      title: 'Port Harcourt Riverfront Run',
      venue: 'Alfred Diete-Spiff Civic Centre grounds',
      city: 'Port Harcourt',
      eventAt: DateTime(2026, 8, 16, 7, 0),
      category: 'Sports',
      description: '5K community run along the waterfront with live drumming.',
      host: 'Garden City Run Club',
      priceLabel: '₦2,500',
      imageUrl: _photo('ph-riverfront-sports'),
    ),
    Event(
      id: 'ph-graduation-gala',
      title: 'Rivers Graduates Gala',
      venue: 'Hotel Presidential Banquet Hall',
      city: 'Port Harcourt',
      eventAt: DateTime(2026, 9, 1, 17, 0),
      category: 'Graduation',
      description: 'Formal celebration for new graduates and families.',
      host: 'Rivers Alumni Network',
      priceLabel: '₦10,000',
      imageUrl: _photo('ph-graduation-gala'),
    ),
  ];
}
