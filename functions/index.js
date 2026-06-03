const functions = require('firebase-functions');
const admin     = require('firebase-admin');

admin.initializeApp();
const db   = admin.firestore();
const rtdb = admin.database();

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

// Batch-delete an array of QueryDocumentSnapshot.
async function batchDelete(docs) {
  if (!docs || docs.length === 0) return;
  for (let i = 0; i < docs.length; i += 500) {
    const batch = db.batch();
    docs.slice(i, i + 500).forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  }
}

// Merge two snapshot arrays without duplicates (by document id).
function mergeDocs(a, b) {
  const seen = new Set(a.map(d => d.id));
  return [...a, ...b.filter(d => !seen.has(d.id))];
}

// Xóa toàn bộ dữ liệu liên quan đến uid sau khi tài khoản bị đánh dấu deleted.
async function cascadeDeleteUser(uid) {
  // ── 1. Posts ──────────────────────────────────────────────────────────────
  const postsSnap = await db.collection('posts').where('ownerId', '==', uid).get();
  await batchDelete(postsSnap.docs);

  // ── 2. Roommate requests ──────────────────────────────────────────────────
  const [sentReqs, receivedReqs] = await Promise.all([
    db.collection('roommate_requests').where('requesterId', '==', uid).get(),
    db.collection('roommate_requests').where('postOwnerId', '==', uid).get(),
  ]);
  await batchDelete(mergeDocs(sentReqs.docs, receivedReqs.docs));

  // ── 3. Room groups ────────────────────────────────────────────────────────
  const deletedGroupIds = new Set();

  // 3a. Groups owned by this user → xóa group + toàn bộ expenses + shares
  const ownedGroupsSnap = await db.collection('room_groups')
    .where('ownerId', '==', uid).get();

  for (const groupDoc of ownedGroupsSnap.docs) {
    deletedGroupIds.add(groupDoc.id);
    const [expSnap, shrSnap] = await Promise.all([
      db.collection('expenses').where('roomGroupId', '==', groupDoc.id).get(),
      db.collection('expense_shares').where('roomGroupId', '==', groupDoc.id).get(),
    ]);
    await batchDelete([...expSnap.docs, ...shrSnap.docs, groupDoc]);
  }

  // 3b. Groups where user is a member (not owner — those are handled above)
  const memberGroupsSnap = await db.collection('room_groups')
    .where('memberIds', 'array-contains', uid).get();

  for (const groupDoc of memberGroupsSnap.docs) {
    if (deletedGroupIds.has(groupDoc.id)) continue;

    const data   = groupDoc.data();
    const newIds = (data.memberIds || []).filter(id => id !== uid);

    if (newIds.length < 2) {
      // Không đủ thành viên → giải tán nhóm
      deletedGroupIds.add(groupDoc.id);
      const [expSnap, shrSnap] = await Promise.all([
        db.collection('expenses').where('roomGroupId', '==', groupDoc.id).get(),
        db.collection('expense_shares').where('roomGroupId', '==', groupDoc.id).get(),
      ]);
      await batchDelete([...expSnap.docs, ...shrSnap.docs, groupDoc]);
    } else {
      // Còn đủ thành viên → chỉ rút uid ra
      await groupDoc.ref.update({ memberIds: newIds });
      // Xóa các expense_share liên quan đến uid trong nhóm này
      const [shrFrom, shrTo, expPaid] = await Promise.all([
        db.collection('expense_shares')
          .where('roomGroupId', '==', groupDoc.id)
          .where('fromUserId', '==', uid).get(),
        db.collection('expense_shares')
          .where('roomGroupId', '==', groupDoc.id)
          .where('toUserId', '==', uid).get(),
        db.collection('expenses')
          .where('roomGroupId', '==', groupDoc.id)
          .where('paidBy', '==', uid).get(),
      ]);
      await batchDelete(mergeDocs(shrFrom.docs, shrTo.docs));
      await batchDelete(expPaid.docs);
    }
  }

  // ── 4. Expense shares còn lại (ngoài các group đã xử lý) ─────────────────
  const [shrFrom, shrTo] = await Promise.all([
    db.collection('expense_shares').where('fromUserId', '==', uid).get(),
    db.collection('expense_shares').where('toUserId', '==', uid).get(),
  ]);
  await batchDelete(mergeDocs(shrFrom.docs, shrTo.docs));

  // ── 5. Expenses còn lại liên quan đến uid ────────────────────────────────
  const [expPaid, expParticipant] = await Promise.all([
    db.collection('expenses').where('paidBy', '==', uid).get(),
    db.collection('expenses').where('participantIds', 'array-contains', uid).get(),
  ]);
  await batchDelete(mergeDocs(expPaid.docs, expParticipant.docs));

  // ── 6. Chat (Realtime Database) ───────────────────────────────────────────
  const convSnap = await rtdb.ref(`user_conversations/${uid}`).get();
  if (convSnap.exists()) {
    const convData = convSnap.val() || {};
    const updates  = {};
    for (const [convId, conv] of Object.entries(convData)) {
      updates[`chats/${convId}`] = null;
      if (conv && conv.otherUserId) {
        updates[`user_conversations/${conv.otherUserId}/${convId}`] = null;
      }
    }
    updates[`user_conversations/${uid}`] = null;
    await rtdb.ref().update(updates);
  }
}

// ── Trigger: khi deleted đầu tiên được set thành true ────────────────────────
exports.onUserDeleted = functions.firestore
  .document('users/{uid}')
  .onWrite(async (change, context) => {
    const before = change.before.exists ? change.before.data() : null;
    const after  = change.after.exists  ? change.after.data()  : null;

    const wasDeleted = before && before.deleted === true;
    const isDeleted  = after  && after.deleted  === true;

    // Chỉ chạy khi deleted lần đầu tiên được set thành true
    if (!isDeleted || wasDeleted) return null;

    const uid = context.params.uid;
    await cascadeDeleteUser(uid);
    return null;
  });

// Soft-delete user — KHÔNG xóa Firebase Auth, chỉ đánh dấu deleted trên Firestore.
// Trigger onUserDeleted bên trên sẽ tự động xóa cascade toàn bộ dữ liệu liên quan.
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
