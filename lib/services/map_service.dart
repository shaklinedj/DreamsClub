import 'package:url_launcher/url_launcher.dart';

class MapService {
  /// Opens Google Maps or default browser with directions to the specified coordinates
  Future<void> openDirections({
    required double latitude,
    required double longitude,
    required String locationName,
  }) async {
    try {
      final query = locationName.trim().isNotEmpty ? locationName.trim() : '$latitude,$longitude';
      final uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(query)}');
      
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
      
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
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
      final query = locationName.trim().isNotEmpty ? locationName.trim() : '$latitude,$longitude';
      final uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
      
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
      
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      throw Exception('Error al abrir el mapa: $e');
    }
  }
}


