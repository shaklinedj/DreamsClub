import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const PROJECT_ID = 'dreams-casino-app';

const app = initializeApp({
    projectId: PROJECT_ID,
});

const db = getFirestore(app);

async function updateVersion() {
    // Read version from pubspec.yaml in root folder
    const pubspecPath = path.resolve(__dirname, '../pubspec.yaml');
    if (!fs.existsSync(pubspecPath)) {
        console.error(`❌ No se encontró pubspec.yaml en: ${pubspecPath}`);
        return;
    }

    const content = fs.readFileSync(pubspecPath, 'utf8');
    const versionMatch = content.match(/version:\s*([^\s+]+)/);
    if (!versionMatch) {
        console.error('❌ No se encontró la línea "version:" en pubspec.yaml');
        return;
    }

    const version = versionMatch[1];
    console.log(`📦 Versión de pubspec.yaml detectada: ${version}`);

    console.log(`📤 Actualizando Firestore config/app con latestVersion: "${version}"...`);

    await db.collection('config').doc('app').set({
        latestVersion: version,
        downloadUrl: 'https://dreams-casino-app.web.app/download',
        updatedAt: new Date()
    }, { merge: true });

    console.log(`🎉 ¡Firestore actualizado con éxito! latestVersion es ahora ${version}`);
}

updateVersion().catch(console.error);
