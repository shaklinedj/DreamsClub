import 'package:appwrite/appwrite.dart';
import 'appwrite_config.dart';

/// Servicio central para manejar la conexión con Appwrite.
/// Úsalo como un Singleton o inyéctalo con Riverpod.
class AppwriteService {
  static final AppwriteService _instance =
      AppwriteService._internal(); // Singleton simple

  late Client client;
  late Databases databases;
  late Account account;
  late Storage storage;
  late Realtime realtime;

  factory AppwriteService() {
    return _instance;
  }

  AppwriteService._internal() {
    client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId)
        .setSelfSigned(
            status:
                true); // TRUE solo para desarrollo local (certificados autofirmados)

    databases = Databases(client);
    account = Account(client);
    storage = Storage(client);
    realtime = Realtime(client);
  }
}
