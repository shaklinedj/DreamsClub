import { initializeApp, getApp, getApps, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { title, body, tokens, recipients, notificationId, customRoute } = req.body;

  const hasTokens = tokens && Array.isArray(tokens) && tokens.length > 0;
  const hasRecipients = recipients && Array.isArray(recipients) && recipients.length > 0;

  if (!title || !body || (!hasTokens && !hasRecipients)) {
    return res.status(400).json({ error: 'Missing parameters. Required: title, body, and either tokens or recipients array' });
  }

  try {
    // Initialize Firebase Admin SDK using Environment Variables (secure)
    let app;
    if (getApps().length === 0) {
      const privateKey = process.env.FIREBASE_PRIVATE_KEY 
        ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n') 
        : undefined;

      app = initializeApp({
        credential: cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: privateKey,
        }),
      });
    } else {
      app = getApp();
    }

    let response;
    if (hasRecipients) {
      const messages = recipients.map(r => ({
        notification: {
          title: r.title || title,
          body: r.body || body,
        },
        data: {
          route: r.customRoute || `/notification-detail/${notificationId || ''}`,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        token: r.token,
      }));
      response = await getMessaging(app).sendEach(messages);
    } else {
      const message = {
        notification: {
          title,
          body,
        },
        data: {
          route: customRoute || `/notification-detail/${notificationId || ''}`,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        tokens,
      };
      response = await getMessaging(app).sendEachForMulticast(message);
    }
    
    console.log(`Multicast results: Successes: ${response.successCount}, Failures: ${response.failureCount}`);
    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(`Token at index ${idx} failed to send. Error:`, resp.error);
        }
      });
    }

    return res.status(200).json({
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  } catch (error) {
    console.error('Error sending multicast FCM notification:', error);
    return res.status(500).json({ error: error.message || 'Internal Server Error' });
  }
}
