import { google } from 'googleapis';
import { Readable } from 'stream';

export default async function handler(req, res) {
  // Configurar CORS
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { base64Image, fileName, mimeType } = req.body;

    if (!base64Image || !fileName) {
      return res.status(400).json({ error: 'Faltan parámetros requeridos (base64Image, fileName)' });
    }

    // El base64 podría venir con el prefijo "data:image/jpeg;base64,"
    let base64Data = base64Image;
    if (base64Image.includes(',')) {
      base64Data = base64Image.split(',')[1];
    }

    // --- Carga de credenciales (2 modos) ---
    let credentials;
    let folderId;

    if (process.env.GDRIVE_SERVICE_ACCOUNT_B64) {
      // MODO RECOMENDADO: JSON completo en base64 → sin problemas de saltos de línea
      try {
        const decoded = Buffer.from(process.env.GDRIVE_SERVICE_ACCOUNT_B64, 'base64').toString('utf8');
        const json = JSON.parse(decoded);
        credentials = {
          client_email: json.client_email,
          private_key: json.private_key,
        };
        folderId = process.env.GDRIVE_FOLDER_ID;
      } catch (parseErr) {
        return res.status(500).json({ error: 'GDRIVE_SERVICE_ACCOUNT_B64 no es un JSON base64 válido', details: parseErr.message });
      }
    } else {
      // MODO ALTERNATIVO: variables individuales (puede tener problemas con \n)
      const rawKey = process.env.GDRIVE_PRIVATE_KEY ?? '';
      // Normalizar saltos de línea: maneja \n y \\n
      const privateKey = rawKey
        .replace(/\\n/g, '\n')
        .replace(/\\\\n/g, '\n');

      credentials = {
        client_email: process.env.GDRIVE_CLIENT_EMAIL,
        private_key: privateKey,
      };
      folderId = process.env.GDRIVE_FOLDER_ID;
    }

    if (!credentials.client_email || !credentials.private_key || !folderId) {
      return res.status(500).json({
        error: 'Faltan credenciales. Configura GDRIVE_SERVICE_ACCOUNT_B64 y GDRIVE_FOLDER_ID en Vercel.',
      });
    }

    const auth = new google.auth.GoogleAuth({
      credentials,
      scopes: ['https://www.googleapis.com/auth/drive'],
    });

    const drive = google.drive({ version: 'v3', auth });
    
    // Crear buffer desde Base64
    const buffer = Buffer.from(base64Data, 'base64');
    const stream = Readable.from(buffer);

    // Subir a la carpeta de Drive compartida con el service account
    const response = await drive.files.create({
      requestBody: {
        name: fileName,
        parents: [folderId],
      },
      media: {
        mimeType: mimeType || 'image/jpeg',
        body: stream,
      },
      fields: 'id',
      supportsAllDrives: true,
    });

    const fileId = response.data.id;

    // Hacer el archivo público (lectura para cualquiera)
    await drive.permissions.create({
      fileId,
      requestBody: {
        role: 'reader',
        type: 'anyone',
      },
    });

    const directLink = `https://drive.google.com/uc?export=view&id=${fileId}`;

    return res.status(200).json({
      success: true,
      fileId,
      url: directLink
    });

  } catch (error) {
    console.error('Error subiendo a Google Drive:', error.message ?? error);
    return res.status(500).json({ error: 'Error interno del servidor', details: error.message });
  }
}
