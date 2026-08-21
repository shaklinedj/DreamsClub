// Google Drive Upload Service
// Sube archivos a una carpeta pública de Google Drive usando OAuth2

const SCOPES = 'https://www.googleapis.com/auth/drive.file';

// ─── CONFIGURACIÓN ────────────────────────────────────────
// El usuario DEBE configurar estos valores:
// 1. CLIENT_ID: Obtenerlo en console.cloud.google.com → APIs & Services → Credentials → OAuth 2.0 Client IDs
// 2. FOLDER_ID: ID de la carpeta de Google Drive donde se subirán los archivos
//    (se extrae de la URL de la carpeta: https://drive.google.com/drive/folders/{FOLDER_ID})
const DRIVE_CONFIG = {
    CLIENT_ID: '326453914816-pr6a1p45fnii678conoarbsc3i942e5p.apps.googleusercontent.com',
    FOLDER_ID: '1NDeO2U8vxV-pGSDrqmVOseVOfDFPGILb',
};

let accessToken: string | null = null;
let gisLoaded = false;

/** Carga el script de Google Identity Services */
export function loadGoogleIdentityScript(): Promise<void> {
    if (gisLoaded) return Promise.resolve();
    return new Promise((resolve, reject) => {
        if (document.getElementById('gis-script')) {
            gisLoaded = true;
            resolve();
            return;
        }
        const script = document.createElement('script');
        script.id = 'gis-script';
        script.src = 'https://accounts.google.com/gsi/client';
        script.async = true;
        script.defer = true;
        script.onload = () => { gisLoaded = true; resolve(); };
        script.onerror = () => reject(new Error('No se pudo cargar Google Identity Services'));
        document.head.appendChild(script);
    });
}

/** Comprueba si la configuración está lista */
export function isDriveConfigured(): boolean {
    return DRIVE_CONFIG.CLIENT_ID.length > 10 && DRIVE_CONFIG.FOLDER_ID.length > 5;
}

/** Autenticación con Google OAuth2 (popup) */
export async function authenticateGoogle(): Promise<string> {
    await loadGoogleIdentityScript();

    return new Promise((resolve, reject) => {
        const google = (window as any).google;
        if (!google?.accounts?.oauth2) {
            reject(new Error('Google Identity Services no disponible. Recarga la página.'));
            return;
        }

        const tokenClient = google.accounts.oauth2.initTokenClient({
            client_id: DRIVE_CONFIG.CLIENT_ID,
            scope: SCOPES,
            callback: (response: any) => {
                if (response.error) {
                    reject(new Error(`Error OAuth: ${response.error}`));
                    return;
                }
                accessToken = response.access_token;
                resolve(accessToken!);
            },
        });

        tokenClient.requestAccessToken({ prompt: '' });
    });
}

/** Comprueba si ya tenemos token válido */
export function isAuthenticated(): boolean {
    return accessToken !== null;
}

/** Sube un archivo a Google Drive y lo hace público */
export async function uploadToDrive(file: File): Promise<{
    fileId: string;
    directUrl: string;
    viewUrl: string;
    fileName: string;
}> {
    // Asegurar autenticación
    if (!accessToken) {
        await authenticateGoogle();
    }

    // 1. Subir archivo con metadata (multipart upload)
    const timestamp = Date.now();
    const safeName = `dreams_${timestamp}_${file.name.replace(/[^a-zA-Z0-9._-]/g, '_')}`;

    const metadata = {
        name: safeName,
        parents: [DRIVE_CONFIG.FOLDER_ID],
    };

    const form = new FormData();
    form.append(
        'metadata',
        new Blob([JSON.stringify(metadata)], { type: 'application/json' })
    );
    form.append('file', file);

    const uploadRes = await fetch(
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,webViewLink,mimeType',
        {
            method: 'POST',
            headers: { Authorization: `Bearer ${accessToken}` },
            body: form,
        }
    );

    if (uploadRes.status === 401) {
        // Token expirado, re-autenticar
        accessToken = null;
        await authenticateGoogle();
        return uploadToDrive(file); // Retry
    }

    if (!uploadRes.ok) {
        const errText = await uploadRes.text();
        throw new Error(`Error subiendo a Drive (${uploadRes.status}): ${errText}`);
    }

    const data = await uploadRes.json();
    const fileId = data.id;

    // 2. Hacer el archivo público (anyone can read)
    const permRes = await fetch(
        `https://www.googleapis.com/drive/v3/files/${fileId}/permissions`,
        {
            method: 'POST',
            headers: {
                Authorization: `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                role: 'reader',
                type: 'anyone',
            }),
        }
    );

    if (!permRes.ok) {
        console.warn('No se pudo hacer público el archivo (puede requerir permisos del dominio)');
    }

    return {
        fileId,
        directUrl: `https://lh3.googleusercontent.com/d/${fileId}`,
        viewUrl: `https://drive.google.com/file/d/${fileId}/view`,
        fileName: safeName,
    };
}

/** Configura dinámicamente (para uso desde UI de configuración) */
export function setDriveConfig(clientId: string, folderId: string) {
    DRIVE_CONFIG.CLIENT_ID = clientId;
    DRIVE_CONFIG.FOLDER_ID = folderId;
    // Persistir en localStorage para uso futuro
    localStorage.setItem('drive_client_id', clientId);
    localStorage.setItem('drive_folder_id', folderId);
}

/** Carga configuración desde localStorage */
export function loadDriveConfig(): { clientId: string; folderId: string } {
    const clientId = localStorage.getItem('drive_client_id') || DRIVE_CONFIG.CLIENT_ID;
    const folderId = localStorage.getItem('drive_folder_id') || DRIVE_CONFIG.FOLDER_ID;
    if (clientId) DRIVE_CONFIG.CLIENT_ID = clientId;
    if (folderId) DRIVE_CONFIG.FOLDER_ID = folderId;
    return { clientId, folderId };
}

/** Extrae el ID de archivo de una URL de Drive y lo elimina de Google Drive */
export async function deleteFromDrive(url: string): Promise<boolean> {
    if (!url) return false;
    
    // Extraer ID
    const driveMatch = url.match(/\/file\/d\/([a-zA-Z0-9_-]+)/) ||
                       url.match(/id=([a-zA-Z0-9_-]+)/) ||
                       url.match(/\/d\/([a-zA-Z0-9_-]+)/);
                       
    if (!driveMatch || !driveMatch[1]) {
        console.warn('La URL no parece ser de Google Drive o no contiene un ID válido:', url);
        return false;
    }
    
    const fileId = driveMatch[1];
    
    // Asegurar autenticación
    if (!accessToken) {
        try {
            await authenticateGoogle();
        } catch (e) {
            console.error('No se pudo autenticar para eliminar en Drive', e);
            return false;
        }
    }

    try {
        const delRes = await fetch(
            `https://www.googleapis.com/drive/v3/files/${fileId}`,
            {
                method: 'DELETE',
                headers: { Authorization: `Bearer ${accessToken}` },
            }
        );

        if (delRes.status === 401) {
            accessToken = null;
            await authenticateGoogle();
            return deleteFromDrive(url); // Retry
        }

        if (!delRes.ok && delRes.status !== 404) {
            console.error('Error al eliminar de Drive', delRes.status);
            return false;
        }
        
        console.log(`Archivo ${fileId} eliminado exitosamente de Drive.`);
        return true;
    } catch (e) {
        console.error('Error de red al intentar eliminar archivo de Drive', e);
        return false;
    }
}
