import 'package:map_launcher/map_launcher.dart';

class MapService {
  /// Opens the default map app with directions to the specified coordinates
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

      // Use the first available map app (usually Google Maps or Apple Maps)
      await availableMaps.first.showDirections(
        destination: Coords(latitude, longitude),
        destinationTitle: locationName,
      );
    } catch (e) {
      throw Exception('Error al abrir el mapa: $e');
    }
  }

  /// Shows available map apps and lets user choose
  Future<void> showMapOptions({
    required double latitude,
    required double longitude,
    required String locationName,
  }) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;
      
      if (availableMaps.isEmpty) {
        throw Exception('No hay aplicaciones de mapas instaladas');
      }

      // If only one map app is available, use it directly
      if (availableMaps.length == 1) {
        await availableMaps.first.showDirections(
          destination: Coords(latitude, longitude),
          destinationTitle: locationName,
        );
        return;
      }

      // If multiple apps available, you could show a dialog to choose
      // For now, we'll just use the first one
      await availableMaps.first.showDirections(
        destination: Coords(latitude, longitude),
        destinationTitle: locationName,
      );
    } catch (e) {
      throw Exception('Error al abrir el mapa: $e');
    }
  }
}
