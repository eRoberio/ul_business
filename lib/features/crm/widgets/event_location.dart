import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class EventLocation {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime? capturedAt;
  final String? capturedBy;

  const EventLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.capturedAt,
    this.capturedBy,
  });

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  LatLng get latLng => LatLng(latitude, longitude);

  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  String get displayAddress =>
      address.trim().isNotEmpty ? address.trim() : coordinatesLabel;

  EventLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    DateTime? capturedAt,
    String? capturedBy,
  }) {
    return EventLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      capturedAt: capturedAt ?? this.capturedAt,
      capturedBy: capturedBy ?? this.capturedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'endereco': address.trim(),
      'capturado_em': capturedAt != null
          ? Timestamp.fromDate(capturedAt!)
          : FieldValue.serverTimestamp(),
      if (capturedBy != null && capturedBy!.trim().isNotEmpty)
        'capturado_por': capturedBy!.trim(),
    };
  }

  static EventLocation? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final lat = (map['latitude'] as num?)?.toDouble();
    final lng = (map['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final rawDate = map['capturado_em'];
    DateTime? capturedAt;
    if (rawDate is Timestamp) {
      capturedAt = rawDate.toDate();
    } else if (rawDate is DateTime) {
      capturedAt = rawDate;
    }

    final location = EventLocation(
      latitude: lat,
      longitude: lng,
      address: (map['endereco'] ?? map['address'] ?? '').toString(),
      capturedAt: capturedAt,
      capturedBy: map['capturado_por']?.toString(),
    );
    return location.isValid ? location : null;
  }
}
