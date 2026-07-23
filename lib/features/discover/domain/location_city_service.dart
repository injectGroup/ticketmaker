/// Resolves the user's current city for Discover filtering.
abstract class LocationCityService {
  Future<String?> resolveCity();
}

/// Always returns a fixed city — used in widget tests.
class FakeLocationCityService implements LocationCityService {
  FakeLocationCityService([this.city = 'Abuja']);

  final String? city;

  @override
  Future<String?> resolveCity() async => city;
}
