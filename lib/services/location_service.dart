import 'package:geolocator/geolocator.dart';

class LocationService {
	Future<Position> getCurrentLocation() async {
		final serviceEnabled = await Geolocator.isLocationServiceEnabled();
		if (!serviceEnabled) {
			throw Exception('El servicio de ubicación está desactivado');
		}

		LocationPermission permission = await Geolocator.checkPermission();
		if (permission == LocationPermission.denied) {
			permission = await Geolocator.requestPermission();
		}

		if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
			throw Exception('Permiso de ubicación denegado');
		}

		return Geolocator.getCurrentPosition(
			locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
		);
	}
}
