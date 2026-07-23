import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/location_city_service.dart';

/// Resolves city via device GPS + reverse geocoding.
class GeolocatorCityService implements LocationCityService {
  GeolocatorCityService({Geocoding? geocoding})
    : _geocoding = geocoding ?? Geocoding();

  final Geocoding _geocoding;

  @override
  Future<String?> resolveCity() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );

    final placemarks = await _geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) return null;

    final place = placemarks.first;
    final locality = place.locality?.trim();
    if (locality != null && locality.isNotEmpty) return locality;

    final admin = place.administrativeArea?.trim();
    if (admin != null && admin.isNotEmpty) return admin;

    return null;
  }
}
