/**
 * Tiny Chicken — Firebase Cloud Functions
 *
 * Deploy:
 *   1. firebase login
 *   2. cd functions && npm install
 *   3. firebase deploy --only functions
 *
 * Triggers:
 *   - onOrderStatusChange: Sends FCM push when an order's status field changes
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Listens for order status changes on any user's order document.
 * When status changes, sends a push notification to that user's device.
 */
exports.onOrderStatusChange = functions.firestore
  .document('users/{userId}/orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const { userId, orderId } = context.params;

    // Only fire if status actually changed
    if (before.status === after.status) return null;

    const newStatus = after.status;
    const orderShortId = orderId.substring(0, 8).toUpperCase();

    // Get user's FCM token
    const userDoc = await admin
      .firestore()
      .collection('users')
      .doc(userId)
      .get();

    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) {
      console.log(`No FCM token for user ${userId}, skipping push.`);
      return null;
    }

    // Build notification payload
    const payload = {
      notification: {
        title: `Order ${newStatus}`,
        body: `Your order #${orderShortId} is now ${newStatus.toLowerCase()}.`,
      },
      data: {
        screen: `order:${orderId}`,
        orderId: orderId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      token: fcmToken,
    };

    try {
      await admin.messaging().send(payload);
      console.log(
        `Push sent to ${userId} for order ${orderShortId}: ${newStatus}`
      );
    } catch (err) {
      console.error(`Push failed for ${userId}:`, err);
    }

    return null;
  });

/**
 * Seeds a default welcome notification when a new user is created.
 */
exports.onUserCreate = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const { userId } = context.params;

    await admin
      .firestore()
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .add({
        title: 'Welcome! 🎉',
        body: 'Thanks for joining Tiny Chicken. Start exploring our collection!',
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    console.log(`Welcome notification sent to new user ${userId}`);
    return null;
  });
