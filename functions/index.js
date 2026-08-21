const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

// Hardcoded casino IDs as per requirements
const CASINO_IDS = ['1', '2', '3', '4', '5', '6', '7'];

/**
 * Rotates QR codes for all casinos every 60 minutes.
 * Updates the 'dynamic_qr' field in each casino document.
 */
exports.rotateQRCodes = functions.pubsub.schedule('every 60 minutes').onRun(async (context) => {
    const batch = admin.firestore().batch();
    const now = Date.now();

    CASINO_IDS.forEach(id => {
        const casinoRef = admin.firestore().collection('casinos').doc(id);
        // Format: CASINO_ID|TIMESTAMP|RANDOM_SUFFIX
        const randomSuffix = Math.floor(Math.random() * 1000000);
        const newCode = `${id}|${now}|${randomSuffix}`;

        batch.update(casinoRef, {
            dynamic_qr: newCode,
            last_qr_update: admin.firestore.FieldValue.serverTimestamp()
        });
    });

    try {
        await batch.commit();
        console.log('Successfully rotated QR codes for casinos:', CASINO_IDS);
        return null;
    } catch (error) {
        console.error('Error rotating QR codes:', error);
        return null;
    }
});

/**
 * Registers a user visit by validating the scanned QR code.
 * params: { qrCode: string }
 * returns: { success: true, casinoName: string }
 */
exports.registerVisit = functions.https.onCall(async (data, context) => {
    // 1. Authenticate User (DEBUG MODE: ALLOW UNAUTHENTICATED)
    let uid;
    if (!context.auth) {
        // throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
        console.warn('DEBUG MODE: Request was unauthenticated. Using DEBUG_USER_ID.');
        uid = 'debug-hernan-laurel'; // Debug ID for testing
    } else {
        uid = context.auth.uid;
    }
    const scannedCode = data.qrCode;

    if (!scannedCode || typeof scannedCode !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid QR code.');
    }

    // 2. Validate QR Code format
    const parts = scannedCode.split('|');
    if (parts.length !== 3) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid QR code format.');
    }

    const casinoId = parts[0];

    try {
        // 3. Verify Casino Code in DB
        const casinoRef = admin.firestore().collection('casinos').doc(casinoId);
        const casinoDoc = await casinoRef.get();

        if (!casinoDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Casino not found.');
        }

        const casinoData = casinoDoc.data();

        // Strictly match the current active QR code
        if (casinoData.dynamic_qr !== scannedCode) {
            throw new functions.https.HttpsError('failed-precondition', 'QR code has expired or is invalid.');
        }

        // Use 'ciudad' as the casino name per user request, fallback to 'name' or ID
        const casinoName = casinoData.ciudad || casinoData.name || `Casino ${casinoId}`;

        // 4. Check for previous visits today
        const visitsRef = admin.firestore().collection('users').doc(uid).collection('visits');
        const lastVisitSnapshot = await visitsRef.orderBy('timestamp', 'desc').limit(1).get();

        let isFirstVisitOfDay = true;
        let streak = 0; // Default, will fetch real value if needed
        let totalVisits = 0;

        // Fetch current user stats
        const userRef = admin.firestore().collection('users').doc(uid);
        const userDoc = await userRef.get();
        const userData = userDoc.exists ? userDoc.data() : {};

        streak = userData.streak || 0;
        totalVisits = userData.totalVisits || 0;

        if (!lastVisitSnapshot.empty) {
            const lastVisitData = lastVisitSnapshot.docs[0].data();
            const lastVisitTime = lastVisitData.timestamp.toDate(); // Firestore Timestamp to Date
            const now = new Date();

            // Reset time part to compare dates only (using simple server time logic)
            // Note: Ideally use user's timezone, but server time/UTC is standard for consistency.
            const isSameDay = lastVisitTime.getDate() === now.getDate() &&
                lastVisitTime.getMonth() === now.getMonth() &&
                lastVisitTime.getFullYear() === now.getFullYear();

            if (isSameDay) {
                isFirstVisitOfDay = false;
            } else {
                // Check for consecutive day for streak
                // If last visit was yesterday (approx difference < 48h and diff days)
                // Simplified streak logic: checks if last visit was "yesterday"
                const yesterday = new Date(now);
                yesterday.setDate(now.getDate() - 1);

                const isYesterday = lastVisitTime.getDate() === yesterday.getDate() &&
                    lastVisitTime.getMonth() === yesterday.getMonth() &&
                    lastVisitTime.getFullYear() === yesterday.getFullYear();

                if (isYesterday) {
                    streak += 1;
                } else {
                    streak = 1; // Reset streak if missed a day (or first ever)
                }
            }
        } else {
            // First visit ever
            streak = 1;
        }

        // 5. Update User Stats (Only if first visit of day)
        if (isFirstVisitOfDay) {
            totalVisits += 1;
            await userRef.set({
                streak: streak,
                totalVisits: totalVisits,
                lastVisitDate: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
        }

        // 6. Register Visit
        await visitsRef.add({
            casinoId: casinoId,
            casinoName: casinoName,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            method: 'dynamic_qr',
            isDailyFirst: isFirstVisitOfDay
        });

        // 7. Return success context
        return {
            success: true,
            casinoName: casinoName,
            isFirstVisitOfDay: isFirstVisitOfDay,
            streak: streak,
            totalVisits: totalVisits
        };

    } catch (error) {
        console.error('Visit registration error:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', 'Internal server error processing visit.');
    }
});

/**
 * Automatically triggers when a new notification is added to Firestore.
 * Dispatches real FCM push notifications to all eligible users based on segment filters.
 */
exports.sendPushNotificationOnCreate = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snapshot, context) => {
        const notificationData = snapshot.data();
        if (!notificationData) return null;

        const title = notificationData.title || 'Dreams Club';
        const body = notificationData.body || '';
        const isBroadcast = notificationData.broadcast === true;
        const targetSegment = notificationData.targetSegment || {};

        console.log(`Sending push notification: "${title}" - Broadcast: ${isBroadcast}`);

        try {
            // 1. Fetch all users from Firestore
            const usersSnapshot = await admin.firestore().collection('users').get();
            const tokens = [];

            for (const userDoc of usersSnapshot.docs) {
                const userData = userDoc.data();
                const token = userData.fcmToken;
                if (!token) continue;

                // 2. Apply segment filters if not a broadcast
                if (!isBroadcast) {
                    // a) Consent Filter
                    const consentOnly = targetSegment.consentOnly === true;
                    const contactConsent = userData.contactConsent ?? userData.wantsContact ?? true;
                    if (consentOnly && contactConsent !== true) {
                        continue;
                    }

                    // b) Streak Filter
                    const streakFilter = targetSegment.streak || 'all';
                    const streak = userData.currentStreak ?? userData.streak ?? 0;
                    if (streakFilter === 'active' && streak < 1) continue;
                    if (streakFilter === 'high' && streak < 5) continue;
                    if (streakFilter === 'vip' && streak < 10) continue;
                    if (streakFilter === 'none' && streak > 0) continue;

                    // c) Presence / Inactivity Filter
                    const presenceFilter = targetSegment.presence || 'all';
                    const lastVisitRaw = userData.lastVisitDate || userData.lastVisit;
                    let lastVisitDate;
                    if (lastVisitRaw) {
                        lastVisitDate = lastVisitRaw.toDate ? lastVisitRaw.toDate() : new Date(lastVisitRaw);
                    }

                    const daysInactive = !lastVisitDate ? 999 : Math.floor((Date.now() - lastVisitDate.getTime()) / (1000 * 60 * 60 * 24));
                    const isPresentToday = userData.isPresentToday === true;

                    if (presenceFilter === 'today' && !isPresentToday && daysInactive > 0) {
                        continue;
                    }
                    if (presenceFilter === 'inactive5' && daysInactive < 5) {
                        continue;
                    }
                    if (presenceFilter === 'inactive10' && daysInactive < 10) {
                        continue;
                    }
                }

                tokens.push(token);
            }

            if (tokens.length === 0) {
                console.log('No eligible users with FCM tokens found.');
                return null;
            }

            console.log(`Sending multicast push notification to ${tokens.length} tokens...`);

            // 3. Construct FCM Message payload
            const message = {
                notification: {
                    title: title,
                    body: body,
                },
                data: {
                    route: `/notification-detail/${snapshot.id}`,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                tokens: tokens,
            };

            const response = await admin.messaging().sendEachForMulticast(message);
            console.log(`Successfully sent ${response.successCount} push notifications. Failures: ${response.failureCount}`);

            return null;
        } catch (error) {
            console.error('Error sending multicast FCM notification:', error);
            return null;
        }
    });

