import 'package:map_launcher/map_launcher.dart';

class MapService {
  /// Opens the first available map app with directions to the specified coordinates
  Future<void> openDirections({
    required double latitude,
    required double longitude,
    required String locationName,
  }) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;

      if (availableMaps.isEmpty) {
        throw Exception('No hay aplicaciones de mapas instaladas');
      }

      // Abre directamente el primer mapa disponible (usualmente Google Maps)
      await availableMaps.first.showDirections(
        destination: Coords(latitude, longitude),
        destinationTitle: locationName,
      );
    } catch (e) {
      throw Exception('Error al abrir el mapa: $e');
    }
  }

  /// Shows a marker on the map
  Future<void> showMapMarker({
    required double latitude,
    required double longitude,
    required String locationName,
    String? description,
  }) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;

      if (availableMaps.isEmpty) {
        throw Exception('No hay aplicaciones de mapas instaladas');
      }

      // Abre directamente el primer mapa disponible
      await availableMaps.first.showMarker(
        coords: Coords(latitude, longitude),
        title: locationName,
        description: description,
      );
    } catch (e) {
      throw Exception('Error al abrir el mapa: $e');
    }
  }
}
