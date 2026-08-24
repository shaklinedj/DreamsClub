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

    // Las credenciales de la cuenta de servicio deben estar en las variables de entorno
    const privateKey = process.env.GDRIVE_PRIVATE_KEY?.replace(/\\n/g, '\n');
    const clientEmail = process.env.GDRIVE_CLIENT_EMAIL;
    const folderId = process.env.GDRIVE_FOLDER_ID;

    if (!privateKey || !clientEmail || !folderId) {
      return res.status(500).json({ error: 'Falta configuración de credenciales de Google Drive en Vercel' });
    }

    const auth = new google.auth.GoogleAuth({
      credentials: {
        client_email: clientEmail,
        private_key: privateKey,
      },
      scopes: ['https://www.googleapis.com/auth/drive.file'],
    });

    const drive = google.drive({ version: 'v3', auth });
    
    // Crear buffer desde Base64
    const buffer = Buffer.from(base64Data, 'base64');
    const stream = Readable.from(buffer);

    // Subir a Drive
    const response = await drive.files.create({
      requestBody: {
        name: fileName,
        parents: [folderId], // Guardar en la carpeta específica
      },
      media: {
        mimeType: mimeType || 'image/jpeg',
        body: stream,
      },
      fields: 'id',
    });

    const fileId = response.data.id;
    
    // Devolver el link directo usando el ID
    const directLink = `https://drive.google.com/uc?export=view&id=${fileId}`;

    return res.status(200).json({
      success: true,
      fileId,
      url: directLink
    });

  } catch (error) {
    console.error('Error subiendo a Google Drive:', error);
    return res.status(500).json({ error: 'Error interno del servidor', details: error.message });
  }
}
