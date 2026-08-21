// Script para registrar stickers en Firestore via REST API
// No necesita firebase-admin ni credenciales especiales

const API_KEY = 'AIzaSyDXOo7MAZTLSJ3gXZjNOE0od4-7-1HfScs';
const PROJECT_ID = 'dreams-casino-app';
const BASE_URL = 'https://dreams-casino-app.web.app/stickers';

const stickers = [
    { name: 'Ficha Casino 3D', file: 'ficha_casino_3d.jpg' },
    { name: 'Corona VIP 3D', file: 'corona_vip_3d.jpg' },
    { name: 'Tragamonedas 3D', file: 'tragamonedas_3d.jpg' },
];

async function addSticker(sticker) {
    const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/stickers?key=${API_KEY}`;
    
    const now = new Date().toISOString();
    const body = {
        fields: {
            name: { stringValue: sticker.name },
            url: { stringValue: `${BASE_URL}/${sticker.file}` },
            createdAt: { timestampValue: now },
        }
    };

    const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
    });

    if (!response.ok) {
        const error = await response.text();
        throw new Error(`Error ${response.status}: ${error}`);
    }

    const result = await response.json();
    console.log(`   ✅ Documento creado: ${result.name}`);
    return result;
}

async function main() {
    console.log('🚀 Registrando stickers en Firestore...\n');

    for (const sticker of stickers) {
        console.log(`📤 ${sticker.name}...`);
        try {
            await addSticker(sticker);
            console.log(`   ✨ ¡Listo!\n`);
        } catch (err) {
            console.error(`   ❌ Error: ${err.message}\n`);
        }
    }

    console.log('🎉 ¡Proceso completado!');
}

main();
