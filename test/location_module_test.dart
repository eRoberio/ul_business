import 'package:flutter_test/flutter_test.dart';
import 'package:ul_business/features/crm/widgets/event_location.dart';
import 'package:ul_business/features/crm/widgets/location_service.dart';

void main() {
  group('EventLocation', () {
    test('fromMap rejeita coordenadas ausentes ou fora da faixa', () {
      expect(EventLocation.fromMap(null), isNull);
      expect(EventLocation.fromMap({'latitude': -23.5}), isNull);
      expect(
        EventLocation.fromMap({'latitude': 95.0, 'longitude': -46.6}),
        isNull,
      );
      expect(
        EventLocation.fromMap({'latitude': -23.5, 'longitude': 190.0}),
        isNull,
      );
    });

    test('fromMap e toMap preservam dados válidos', () {
      final location = EventLocation.fromMap({
        'latitude': -23.55052,
        'longitude': -46.633308,
        'endereco': 'Praça da Sé - Centro - São Paulo',
        'capturado_por': 'Agendista A',
      });

      expect(location, isNotNull);
      expect(location!.isValid, isTrue);
      expect(location.displayAddress, 'Praça da Sé - Centro - São Paulo');
      expect(location.toMap()['latitude'], -23.55052);
      expect(location.toMap()['longitude'], -46.633308);
      expect(location.toMap()['endereco'], 'Praça da Sé - Centro - São Paulo');
      expect(location.toMap()['capturado_por'], 'Agendista A');
    });
  });

  group('LocationService', () {
    test('formatNominatimAddress formata endereço brasileiro completo', () {
      final formatted = LocationService.formatNominatimAddress({
        'address': {
          'road': 'Avenida Paulista',
          'house_number': '1000',
          'suburb': 'Bela Vista',
          'city': 'São Paulo',
          'state': 'São Paulo',
        },
      });

      expect(
        formatted,
        'Avenida Paulista, 1000 - Bela Vista - São Paulo - São Paulo',
      );
    });

    test('URIs de Waze e Google Maps apontam para as coordenadas corretas', () {
      const location = EventLocation(
        latitude: -23.561414,
        longitude: -46.655881,
        address: 'Av. Paulista, 1578',
      );

      expect(
        LocationService.buildWazeAppUri(location).toString(),
        'waze://?ll=-23.561414,-46.655881&navigate=yes',
      );
      expect(
        LocationService.buildWazeWebUri(location).toString(),
        'https://waze.com/ul?ll=-23.561414%2C-46.655881&navigate=yes',
      );
      expect(
        LocationService.buildGoogleMapsUri(location).toString(),
        'https://www.google.com/maps/dir/?api=1&destination=-23.561414%2C-46.655881',
      );
    });
  });
}
