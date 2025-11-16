import 'package:geolocator/geolocator.dart';

class LocationService {
	Future<Position> getCurrentLocation() async {
		final serviceEnabled = await Geolocator.isLocationServiceEnabled();
		if (!serviceEnabled) {
			throw Exception('Los servicios de ubicación están desactivados.');
		}

		LocationPermission permission = await Geolocator.checkPermission();
		if (permission == LocationPermission.denied) {
			permission = await Geolocator.requestPermission();
		}

		if (permission == LocationPermission.denied) {
			throw Exception('Permiso de ubicación denegado.');
		}

		if (permission == LocationPermission.deniedForever) {
			throw Exception(
					'Permiso de ubicación denegado permanentemente. Habilítalo en ajustes.');
		}

		return Geolocator.getCurrentPosition(
			desiredAccuracy: LocationAccuracy.medium,
		);
	}
}

