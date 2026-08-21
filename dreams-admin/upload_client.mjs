import { initializeApp } from "firebase/app";
import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { getAuth, signInWithEmailAndPassword } from "firebase/auth";
import fs from "fs";

const firebaseConfig = {
    apiKey: 'AIzaSyDXOo7MAZTLSJ3gXZjNOE0od4-7-1HfScs',
    appId: '1:326453914816:web:7dff6793ffc873fb291125',
    messagingSenderId: '326453914816',
    projectId: 'dreams-casino-app',
    authDomain: 'dreams-casino-app.firebaseapp.com',
    storageBucket: 'dreams-casino-app.firebasestorage.app',
};

const app = initializeApp(firebaseConfig);
const storage = getStorage(app);
const auth = getAuth(app);

const APK_PATH = 'E:\\DreamsClub-master\\DreamsClub-master\\build\\app\\outputs\\flutter-apk\\app-release.apk';

async function uploadViaClientSdk() {
    console.log("🔐 Autenticando con Firebase Auth...");
    try {
        await signInWithEmailAndPassword(auth, "coyhaique@dreams.cl", "Admin123!");
        console.log("✅ Autenticado como coyhaique@dreams.cl");
    } catch (e) {
        console.log("⚠️ Intento login 1 falló, probando admin@dreams.cl...");
        try {
            await signInWithEmailAndPassword(auth, "admin@dreams.cl", "Admin123!");
            console.log("✅ Autenticado como admin@dreams.cl");
        } catch (e2) {
            console.log("⚠️ Error autenticando:", e2.message);
        }
    }

    console.log("📦 Leyendo archivo APK...");
    const fileBuffer = fs.readFileSync(APK_PATH);
    console.log(`📦 Tamaño: ${(fileBuffer.length / (1024 * 1024)).toFixed(2)} MB`);

    console.log("📤 Subiendo a Firebase Storage en /releases/DreamsClub.apk ...");
    const storageRef = ref(storage, 'releases/DreamsClub.apk');

    const metadata = {
        contentType: 'application/vnd.android.package-archive',
        contentDisposition: 'attachment; filename="DreamsClub.apk"',
    };

    const snapshot = await uploadBytes(storageRef, fileBuffer, metadata);
    console.log("✅ Subida completada!");

    const downloadUrl = await getDownloadURL(snapshot.ref);
    console.log(`\n🎉 URL OFICIAL DE DESCARGA:`);
    console.log(downloadUrl);

    // Guardar URL en un archivo temporal
    fs.writeFileSync('apk_url.txt', downloadUrl);
}

uploadViaClientSdk().catch(console.error);
