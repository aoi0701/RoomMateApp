const functions = require('firebase-functions');
const admin     = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Kiểm tra caller có phải admin không
async function requireAdmin(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Yêu cầu đăng nhập.');
  }
  const snap = await db.collection('users').doc(context.auth.uid).get();
  if (!snap.exists || snap.data().role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Chỉ admin mới có quyền thực hiện.');
  }
}

// Soft-delete user — KHÔNG xóa Firebase Auth, chỉ đánh dấu deleted trên Firestore.
// Dùng Spark Plan: không cần Blaze, không cần Cloud Functions.
// Admin Dashboard tự gọi Firestore trực tiếp; function này là fallback nếu cần.
exports.softDeleteUser = functions.https.onCall(async (data, context) => {
  await requireAdmin(context);

  const { uid } = data;
  if (!uid || typeof uid !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Thiếu uid hợp lệ.');
  }

  await db.collection('users').doc(uid).update({
    deleted:   true,
    deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    isBlocked: true,
  });

  return { success: true };
});
