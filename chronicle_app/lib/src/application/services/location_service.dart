import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> reverseGeocode(double latitude, double longitude) async {
    final client = HttpClient();
    client.userAgent = 'ChronicleApp/1.0';
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=14',
      );
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        final jsonString = await response.transform(utf8.decoder).join();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'];
          final state = address['state'] ?? address['region'];
          final country = address['country'];

          final parts = <String>[];
          if (city != null) parts.add(city.toString());
          if (state != null) parts.add(state.toString());
          if (country != null && city == null) parts.add(country.toString());

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }

        final displayName = data['display_name'] as String?;
        if (displayName != null) {
          final parts = displayName.split(',');
          if (parts.length > 2) {
            return parts.take(2).join(', ').trim();
          }
          return displayName;
        }
      }
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
    return null;
  }
}
