import { initializeApp, getApp, getApps, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

export default async function handler(req, res) {
  // Allow Vercel Cron triggers only
  const isCron = req.headers['x-vercel-cron'] === '1';
  const isAdminRequest = req.headers['authorization'] === `Bearer ${process.env.CRON_SECRET}`;

  if (!isCron && !isAdminRequest && process.env.NODE_ENV === 'production') {
    return res.status(401).json({ error: 'Unauthorized. Only crons are allowed.' });
  }

  try {
    // 1. Initialize Firebase Admin SDK
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

    const db = getFirestore(app);
    const messaging = getMessaging(app);

    // 2. Load Scheduled Campaigns
    const campaignsSnap = await db.collection('scheduled_campaigns')
      .where('status', '==', 'active')
      .get();

    if (campaignsSnap.empty) {
      return res.status(200).json({ message: 'No active scheduled campaigns found.' });
    }

    const today = new Date();
    const todayStr = today.toISOString().split('T')[0]; // YYYY-MM-DD
    const results = [];

    // Helper: calculate age
    const calculateAge = (birthday) => {
      if (!birthday) return 999;
      const date = birthday.toDate ? birthday.toDate() : new Date(birthday);
      const ageDifMs = Date.now() - date.getTime();
      const ageDate = new Date(ageDifMs);
      return Math.abs(ageDate.getUTCFullYear() - 1970);
    };

    // Helper: check if today is birthday
    const isBirthdayToday = (birthday) => {
      if (!birthday) return false;
      const date = birthday.toDate ? birthday.toDate() : new Date(birthday);
      return date.getDate() === today.getDate() && date.getMonth() === today.getMonth();
    };

    // 3. Process each campaign
    for (const doc of campaignsSnap.docs) {
      const campaign = doc.data();
      const campaignId = doc.id;

      if (campaign.type === 'birthday') {
        // --- A. BIRTHDAY CAMPAIGN (DAILY RUN) ---
        console.log(`🎂 Running birthday campaign: "${campaign.title}"`);
        
        // Fetch all users with FCM tokens
        const usersSnap = await db.collection('users').get();
        const targets = [];

        for (const userDoc of usersSnap.docs) {
          const userData = userDoc.data();
          if (userData.fcmToken && isBirthdayToday(userData.birthday)) {
            targets.push({
              uid: userDoc.id,
              name: userData.name || userData.displayName || 'Socio',
              token: userData.fcmToken
            });
          }
        }

        if (targets.length > 0) {
          // Send push notifications individually to customize names
          for (const target of targets) {
            const personalizedTitle = campaign.title.replace(/{name}/g, target.name);
            const personalizedBody = campaign.body.replace(/{name}/g, target.name);

            // Add notification to history
            const notifRef = await db.collection('notifications').add({
              title: personalizedTitle,
              body: personalizedBody,
              type: 'promo',
              casinoId: '4', // Coyhaique
              createdAt: FieldValue.serverTimestamp(),
              status: 'sent',
              userId: target.uid, // Targeted to this user
              broadcast: false,
            });

            await messaging.send({
              notification: {
                title: personalizedTitle,
                body: personalizedBody,
              },
              data: {
                route: `/notification-detail/${notifRef.id}`,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
              },
              token: target.token,
            });
          }
          results.push({ campaignId, type: 'birthday', sentTo: targets.length });
        }

      } else if (campaign.type === 'prize_reminder') {
        // --- B. PRIZE EXPIRATION REMINDER CAMPAIGN ---
        console.log(`🎁 Running prize expiration reminder campaign: "${campaign.title}"`);

        // Fetch user prizes expiring in approximately 24 hours (12 to 36 hours from now)
        const now = Date.now();
        const minExpiry = new Date(now + 12 * 60 * 60 * 1000);
        const maxExpiry = new Date(now + 36 * 60 * 60 * 1000);

        const prizesSnap = await db.collection('user_prizes')
          .where('status', '==', 'disponible')
          .get();

        const targets = [];

        for (const prizeDoc of prizesSnap.docs) {
          const prizeData = prizeDoc.data();
          if (prizeData.expiresAt && prizeData.userId) {
            const expiryDate = prizeData.expiresAt.toDate ? prizeData.expiresAt.toDate() : new Date(prizeData.expiresAt);
            if (expiryDate >= minExpiry && expiryDate <= maxExpiry) {
              // Fetch user data
              const userDoc = await db.collection('users').doc(prizeData.userId).get();
              if (userDoc.exists) {
                const userData = userDoc.data();
                if (userData.fcmToken) {
                  targets.push({
                    uid: prizeData.userId,
                    name: userData.name || userData.displayName || 'Socio',
                    token: userData.fcmToken,
                    prizeName: prizeData.prizeName || 'Premio'
                  });
                }
              }
            }
          }
        }

        if (targets.length > 0) {
          for (const target of targets) {
            const personalizedTitle = campaign.title
              .replace(/{name}/g, target.name)
              .replace(/{prize}/g, target.prizeName);
            const personalizedBody = campaign.body
              .replace(/{name}/g, target.name)
              .replace(/{prize}/g, target.prizeName);

            // Add notification to history
            const notifRef = await db.collection('notifications').add({
              title: personalizedTitle,
              body: personalizedBody,
              type: 'alert',
              casinoId: '4',
              createdAt: FieldValue.serverTimestamp(),
              status: 'sent',
              userId: target.uid,
              broadcast: false,
            });

            await messaging.send({
              notification: {
                title: personalizedTitle,
                body: personalizedBody,
              },
              data: {
                route: `/notification-detail/${notifRef.id}`,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
              },
              token: target.token,
            });
          }
          results.push({ campaignId, type: 'prize_reminder', sentTo: targets.length });
        }

      } else if (campaign.type === 'custom') {
        // --- C. CUSTOM CAMPAIGN (SINGLE RUN ON TARGET DATE) ---
        if (campaign.targetDate === todayStr) {
          console.log(`📅 Running custom campaign for date ${todayStr}: "${campaign.title}"`);
          
          // Fetch users with FCM tokens
          const usersSnap = await db.collection('users').get();
          const targetTokens = [];
          const targetUids = [];

          // Optional filters from targetFilters
          const filters = campaign.targetFilters || {};

          for (const userDoc of usersSnap.docs) {
            const userData = userDoc.data();
            if (!userData.fcmToken) continue;

            // Apply age filter if configured
            if (filters.ageMax) {
              const age = calculateAge(userData.birthday);
              if (age > filters.ageMax) continue;
            }
            if (filters.ageMin) {
              const age = calculateAge(userData.birthday);
              if (age < filters.ageMin) continue;
            }

            // Apply streak filter if configured
            if (filters.streak && filters.streak !== 'all') {
              const streak = userData.currentStreak || userData.streak || 0;
              if (filters.streak === 'active' && streak < 1) continue;
              if (filters.streak === 'high' && streak < 5) continue;
              if (filters.streak === 'vip' && streak < 10) continue;
              if (filters.streak === 'none' && streak > 0) continue;
            }

            targetTokens.push(userData.fcmToken);
            targetUids.push(userDoc.id);
          }

          if (targetTokens.length > 0) {
            // Write notification history
            const notifRef = await db.collection('notifications').add({
              title: campaign.title,
              body: campaign.body,
              type: 'promo',
              casinoId: '4',
              createdAt: FieldValue.serverTimestamp(),
              status: 'sent',
              broadcast: true,
            });

            // Send multicast
            const message = {
              notification: {
                title: campaign.title,
                body: campaign.body,
              },
              data: {
                route: `/notification-detail/${notifRef.id}`,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
              },
              tokens: targetTokens,
            };

            await messaging.sendEachForMulticast(message);

            // Mark campaign as completed so it doesn't run again
            await db.collection('scheduled_campaigns').doc(campaignId).update({
              status: 'completed',
              runAt: FieldValue.serverTimestamp(),
            });

            results.push({ campaignId, type: 'custom', sentTo: targetTokens.length });
          }
        }
      }
    }

    return res.status(200).json({ success: true, results });
  } catch (error) {
    console.error('Error running scheduled campaigns cron:', error);
    return res.status(500).json({ error: error.message || 'Internal Server Error' });
  }
}
