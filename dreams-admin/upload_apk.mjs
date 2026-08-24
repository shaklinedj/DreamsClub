import { initializeApp, cert } from 'firebase-admin/app';
import { getStorage } from 'firebase-admin/storage';
import fs from 'fs';

const PROJECT_ID = 'dreams-casino-app';
const BUCKET = 'dreams-casino-app.firebasestorage.app';

const ALLOW_FIREBASE_UPLOAD = process.env.ALLOW_FIREBASE_APK_UPLOAD === 'true';

if (!ALLOW_FIREBASE_UPLOAD) {
    console.log('Upload de APK desactivado por defecto. Política: distribuir por GitHub Releases, no por Firebase Hosting ni Storage automatizado.');
    console.log('Para habilitarlo manualmente, ejecuta: ALLOW_FIREBASE_APK_UPLOAD=true node dreams-admin/upload_apk.mjs');
    process.exit(0);
}

const app = initializeApp({
    projectId: PROJECT_ID,
    storageBucket: BUCKET,
});

const bucket = getStorage(app).bucket();
const APK_PATH = 'E:\\DreamsClub-master\\DreamsClub-master\\build\\app\\outputs\\flutter-apk\\app-release.apk';

async function uploadApk() {
    if (!fs.existsSync(APK_PATH)) {
        console.error(`❌ No se encontró el archivo: ${APK_PATH}`);
        return;
    }

    const stats = fs.statSync(APK_PATH);
    console.log(`📦 Archivo APK detectado: ${(stats.size / (1024 * 1024)).toFixed(2)} MB`);

    const destination = 'releases/DreamsApp-v1.0.9.apk';
    console.log(`📤 Subiendo a Firebase Storage (${BUCKET}/${destination})...`);

    await bucket.upload(APK_PATH, {
        destination,
        metadata: {
            contentType: 'application/vnd.android.package-archive',
            contentDisposition: 'attachment; filename="DreamsApp-v1.0.9.apk"',
            metadata: {
                firebaseStorageDownloadTokens: 'dreamsclub-release-v1'
            }
        }
    });

    try {
        await bucket.file(destination).makePublic();
        console.log('✅ Archivo configurado como público');
    } catch (e) {
        console.log('ℹ️ Nota de permisos públicos:', e.message);
    }

    const tokenUrl = `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(destination)}?alt=media&token=dreamsclub-release-v1`;
    console.log(`\n🎉 ¡APK Subida Exitosamente!`);
    console.log(`🔗 URL Directa de Descarga: ${tokenUrl}`);
}

uploadApk().catch(console.error);
