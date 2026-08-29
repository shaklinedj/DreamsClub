# Guía de Migración Definitiva: De Firebase a Appwrite (BaaS Autoalojado)

Esta guía detalla cómo migrar por completo la infraestructura de **Dreams Club** desde Firebase hacia **Appwrite**, el reemplazo autoalojado de código abierto más cercano y equivalente a la suite de Firebase.

---

## 🗺️ Mapeo de Servicios (Firebase vs. Appwrite)

| Servicio en Firebase | Equivalente en Appwrite | Rol en Dreams Club |
| :--- | :--- | :--- |
| **Firebase Auth** | **Appwrite Account API** | Registro, inicio de sesión y gestión de la sesión persistente del usuario. |
| **Cloud Firestore** | **Appwrite Databases** | Almacenamiento NoSQL estructurado en Colecciones y Documentos (JSON). |
| **Firebase Storage** | **Appwrite Storage** | Buckets para fotos de perfil, imágenes de eventos y promociones. |
| **Cloud Functions** | **Appwrite Functions** | Lógica de servidor (cómputo de puntos, verificación GPS, mini-juegos). |
| **Firestore Snapshots** | **Appwrite Realtime** | Escucha en vivo de chats, comentarios, likes y feed dinámico. |
| **Firebase Cloud Messaging**| **Appwrite Messaging** | Envío de notificaciones push nativas a iOS y Android desde la consola. |

---

## 🚀 Paso 1: Despliegue de Appwrite en tu Servidor (VPS)

Appwrite requiere **Docker** y **Docker Compose** en tu servidor VPS (Ubuntu recomendado). 

1. Conéctate a tu VPS por SSH:
   ```bash
   ssh root@tu-servidor-ip
   ```
2. Ejecuta el comando oficial de instalación:
   ```bash
   docker run -it --rm \
     --volume /var/run/docker.sock:/var/run/docker.sock \
     --volume "$(pwd)"/appwrite:/usr/src/code/appwrite:rw \
     --entrypoint "upgrade" \
     appwrite/appwrite:latest
   ```
3. El asistente te preguntará:
   - **HTTP Port** (por defecto 80)
   - **HTTPS Port** (por defecto 443)
   - **CNAME/Domain** (ingresa tu dominio, ej: `api.dreamsclub.cl` para generar SSL automáticamente con Let's Encrypt).
4. Una vez finalizado, ingresa a tu dominio o IP en el navegador y regístrate como administrador.

---

## 🛠️ Paso 2: Equivalencias de Código en Dart (Firebase vs. Appwrite)

En Flutter, los servicios se consumen de manera conceptualmente idéntica. A continuación se muestran los ejemplos comparados:

### 1. Autenticación (Auth)

#### Firebase:
```dart
// Registrarse
final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);
```

#### Appwrite:
```dart
// Registrarse
final account = AppwriteService().account;
final user = await account.create(
  userId: ID.unique(), // Autogenerar ID único
  email: email,
  password: password,
  name: name,
);

// Iniciar Sesión (Crea una sesión persistente en el dispositivo)
await account.createEmailPasswordSession(
  email: email,
  password: password,
);
```

---

### 2. Base de Datos (Firestore vs. Appwrite Databases)

En Appwrite, primero debes ir a la Consola Web, crear una Base de Datos y una Colección (ej: `casinos`), y definir sus Atributos (ej: `nombre` de tipo String, `latitud` de tipo Float).

#### Firebase:
```dart
// Obtener Documentos
final snapshot = await FirebaseFirestore.instance.collection('casinos').get();
final list = snapshot.docs.map((doc) => doc.data()).toList();
```

#### Appwrite:
```dart
// Obtener Documentos
final databases = AppwriteService().databases;
final response = await databases.listDocuments(
  databaseId: AppwriteConfig.databaseId,
  collectionId: AppwriteConfig.collectionCasinos,
);
final list = response.documents.map((doc) => doc.data).toList();
```

---

### 3. Escucha en Tiempo Real (Realtime)

#### Firebase:
```dart
FirebaseFirestore.instance.collection('comments')
    .snapshots()
    .listen((snapshot) {
      // Manejar cambios
    });
```

#### Appwrite:
```dart
final realtime = AppwriteService().realtime;

final subscription = realtime.subscribe([
  'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.collectionComments}.documents'
]);

subscription.stream.listen((event) {
  // event.payload contiene el documento JSON modificado o creado
  // event.events contiene el tipo de evento (ej: database.documents.create)
  print(event.payload);
});
```

---

### 4. Almacenamiento (Storage)

#### Firebase:
```dart
final ref = FirebaseStorage.instance.ref().child('avatars/user123.jpg');
await ref.putFile(file);
final url = await ref.getDownloadURL();
```

#### Appwrite:
```dart
final storage = AppwriteService().storage;

// Subir Archivo
final response = await storage.createFile(
  bucketId: AppwriteConfig.bucketImages,
  fileId: ID.unique(),
  file: InputFile.fromPath(path: localPath),
);

// Obtener URL de visualización pública
final uri = storage.getFileView(
  bucketId: AppwriteConfig.bucketImages,
  fileId: response.$id,
);
final String url = uri.toString();
```

---

## 🔔 Paso 3: Notificaciones Push Autoalojadas (Appwrite Messaging)

A partir de la versión 1.5, Appwrite incluye un panel completo de **Messaging** (Mensajería) que unifica el envío de notificaciones push nativas.

### Configuración en la Consola Web de Appwrite:
1. Entra a tu Consola de Appwrite.
2. Ve a **Messaging** (en la barra lateral) ➡️ **Providers** (Proveedores).
3. Añade un nuevo proveedor de tipo **Push**:
   - **APNS (Apple):** Sube tu llave `.p8`, ingresa tu Key ID, Team ID y Bundle ID.
   - **FCM (Google):** Sube el archivo JSON de tu clave privada de cuenta de servicio generado en Firebase Console.
4. En Flutter, los usuarios se suscriben a "temas" o registran su token de dispositivo utilizando el SDK de Appwrite:
   ```dart
   // Registrar token del dispositivo en el usuario autenticado
   final messaging = AppwriteService().messaging; // Instancia de Messaging
   await messaging.createSubscriber(
     topicId: 'announcements',
     subscriberId: ID.unique(),
     target: 'FCM_TOKEN_DEL_DISPOSITIVO',
   );
   ```

---

## 📥 Paso 4: Script de Migración de Datos (Firestore a Appwrite)

Puedes usar este script de Node.js para extraer tus datos de Firestore y cargarlos directamente en tu nueva base de datos de Appwrite:

```javascript
const admin = require('firebase-admin');
const { Client, Databases, ID } = require('node-appwrite');
const fs = require('fs');

// 1. Inicializar Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(require('./firebase-key.json'))
});
const firestore = admin.firestore();

// 2. Inicializar Appwrite SDK Admin
const client = new Client()
  .setEndpoint('https://api.dreamsclub.cl/v1')
  .setProject('dreams-club-prod')
  .setKey('TU_API_KEY_DE_CONSOLA_APPWRITE'); // Requiere permisos de Database

const databases = new Databases(client);

const databaseId = 'dreams_main_db';
const collectionId = 'casinos';

async function migrate() {
  console.log('Obteniendo datos de Firestore...');
  const snapshot = await firestore.collection('casinos').get();
  
  for (const doc of snapshot.docs) {
    const data = doc.data();
    console.log(`Migrando casino: ${data.nombre}`);
    
    try {
      await databases.createDocument(
        databaseId,
        collectionId,
        ID.unique(),
        {
          nombre: data.nombre,
          direccion: data.direccion,
          ciudad: data.ciudad,
          latitud: parseFloat(data.latitud),
          longitud: parseFloat(data.longitud)
        }
      );
    } catch (e) {
      console.error(`Error al migrar ${data.nombre}:`, e.message);
    }
  }
  console.log('Migración completada 🎉');
}

migrate();
```
