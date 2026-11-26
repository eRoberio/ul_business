import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'event_location.dart';

class AddressSuggestion {
  final String displayName;
  final double latitude;
  final double longitude;

  const AddressSuggestion({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}

class LocationException implements Exception {
  final String message;

  const LocationException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  static const _userAgent = 'ul_business/1.0 (agenda-crm-location)';
  static const _timeout = Duration(seconds: 8);

  final http.Client _client;

  LocationService({http.Client? client}) : _client = client ?? http.Client();

  Future<LatLng> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'O GPS está desativado no dispositivo. Ative a localização para capturar em tempo real.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          'Permissão de localização negada. Autorize o acesso ao GPS para marcar sua posição.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Permissão de localização bloqueada nas configurações do aparelho. Libere o acesso para usar o GPS.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  }

  Future<String> reverseGeocode(double latitude, double longitude) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'addressdetails': '1',
      'accept-language': 'pt-BR',
    });

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(_timeout);
      if (response.statusCode != 200) {
        return _fallbackAddress(latitude, longitude);
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return _fallbackAddress(latitude, longitude);
      }
      return formatNominatimAddress(body) ??
          _fallbackAddress(latitude, longitude);
    } catch (_) {
      return _fallbackAddress(latitude, longitude);
    }
  }

  Future<List<AddressSuggestion>> searchAddress(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'q': trimmed,
      'addressdetails': '1',
      'limit': '6',
      'countrycodes': 'br',
      'accept-language': 'pt-BR',
    });

    final response = await _client
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw const LocationException(
        'Não foi possível buscar o endereço no momento.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    final results = <AddressSuggestion>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final lat = double.tryParse('${item['lat'] ?? ''}');
      final lon = double.tryParse('${item['lon'] ?? ''}');
      if (lat == null || lon == null) continue;
      final formatted =
          formatNominatimAddress(item) ?? '${item['display_name'] ?? ''}'.trim();
      if (formatted.isEmpty) continue;
      results.add(
        AddressSuggestion(
          displayName: formatted,
          latitude: lat,
          longitude: lon,
        ),
      );
    }
    return results;
  }

  static String? formatNominatimAddress(Map<String, dynamic> payload) {
    final address = payload['address'];
    if (address is Map) {
      final road =
          address['road'] ??
          address['pedestrian'] ??
          address['footway'] ??
          address['street'];
      final houseNumber = address['house_number'];
      final suburb =
          address['suburb'] ??
          address['neighbourhood'] ??
          address['quarter'] ??
          address['city_district'];
      final city =
          address['city'] ??
          address['town'] ??
          address['village'] ??
          address['municipality'];
      final state = address['state'];

      final streetPart = [
        if (road != null && '$road'.trim().isNotEmpty) '$road'.trim(),
        if (houseNumber != null && '$houseNumber'.trim().isNotEmpty)
          '$houseNumber'.trim(),
      ].join(', ');

      final parts = [
        if (streetPart.isNotEmpty) streetPart,
        if (suburb != null && '$suburb'.trim().isNotEmpty) '$suburb'.trim(),
        if (city != null && '$city'.trim().isNotEmpty) '$city'.trim(),
        if (state != null && '$state'.trim().isNotEmpty) '$state'.trim(),
      ];

      if (parts.isNotEmpty) {
        return parts.join(' - ');
      }
    }

    final displayName = payload['display_name']?.toString().trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return null;
  }

  static Uri buildWazeAppUri(EventLocation location) {
    return Uri.parse(
      'waze://?ll=${location.latitude},${location.longitude}&navigate=yes',
    );
  }

  static Uri buildWazeWebUri(EventLocation location) {
    return Uri.https('waze.com', '/ul', {
      'll': '${location.latitude},${location.longitude}',
      'navigate': 'yes',
    });
  }

  static Uri buildGoogleMapsUri(EventLocation location) {
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${location.latitude},${location.longitude}',
    });
  }

  Future<bool> openInWaze(EventLocation location) async {
    final appUri = buildWazeAppUri(location);
    if (await canLaunchUrl(appUri)) {
      if (await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    }
    final webUri = buildWazeWebUri(location);
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  Future<bool> openInGoogleMaps(EventLocation location) async {
    final mapsUri = buildGoogleMapsUri(location);
    return launchUrl(mapsUri, mode: LaunchMode.externalApplication);
  }

  String _fallbackAddress(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}
