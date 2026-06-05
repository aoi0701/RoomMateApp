import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rxdart/rxdart.dart';

import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';

class ChatRepository {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db;

  // Per-id caches so repeated calls (e.g. widget rebuilds) always return the
  // same stream object and never open more than one Firebase listener per path.
  // shareValueSeeded uses refCount, so the underlying listener is cancelled
  // automatically when the last subscriber unsubscribes.
  // On stream error the entry is removed so the next subscriber gets a fresh
  // listener rather than a closed BehaviorSubject.
  final _messageStreams = <String, Stream<List<ChatMessageModel>>>{};
  final _conversationStreams = <String, Stream<List<ChatConversationModel>>>{};

  ChatRepository({
    required FirebaseAuth auth,
    required FirebaseDatabase db,
  })  : _auth = auth,
        _db = db;

  User? get _currentUser => _auth.currentUser;

  String? get currentUserId => _currentUser?.uid;

  // Tạo ID hội thoại duy nhất từ 2 userId bằng cách sắp xếp để luôn nhất quán
  String getConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return sorted.join('_');
  }

  List<String> _getSortedParticipants(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return sorted;
  }

  /// Creates the conversation node the first time it is needed.
  ///
  /// Checks for the document's existence before writing so that subsequent
  /// calls (e.g. every [sendMessage]) are a single cheap read rather than a
  /// redundant write. The immutable fields (participantAId, participantBId,
  /// createdAt) are written exactly once and never overwritten.
  Future<void> ensureConversation({
    required String conversationId,
    required String otherUserId,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not authenticated');

    final snap = await _db
        .ref('chats/$conversationId/participantAId')
        .get()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Timed out while creating chat'),
        );

    if (snap.exists) return;

    final participants = _getSortedParticipants(user.uid, otherUserId);
    await _db.ref('chats/$conversationId').update({
      'participantAId': participants[0],
      'participantBId': participants[1],
      'createdAt': ServerValue.timestamp,
    }).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Timed out while creating chat'),
    );
  }

  // Gửi tin nhắn: đảm bảo hội thoại tồn tại, lưu message vào Realtime DB,
  // rồi cập nhật metadata (lastMessage, unreadCount) cho cả 2 phía
  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String text,
    required String receiverName,
    required String receiverAvatar,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not authenticated');

    await ensureConversation(
      conversationId: conversationId,
      otherUserId: receiverId,
    );

    final trimmedText = text.trim();
    final createdAt = ServerValue.timestamp;
    final messagesRef = _db.ref('chats/$conversationId/messages').push();
    final messageId = messagesRef.key!;
    final senderName = user.displayName ?? '';
    final senderAvatar = user.photoURL ?? '';

    final messageUpdates = <String, dynamic>{
      'chats/$conversationId/messages/$messageId/senderId': user.uid,
      'chats/$conversationId/messages/$messageId/senderName': senderName,
      'chats/$conversationId/messages/$messageId/senderAvatar': senderAvatar,
      'chats/$conversationId/messages/$messageId/text': trimmedText,
      'chats/$conversationId/messages/$messageId/createdAt': createdAt,
      'chats/$conversationId/messages/$messageId/isRead': false,
    };

    try {
      await _db.ref().update(messageUpdates).timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Timed out while sending message'),
          );
    } on FirebaseException catch (e) {
      throw Exception(
        'Failed to save message: ${e.message ?? e.code}',
      );
    }

    await _updateConversationMetadata(
      conversationId: conversationId,
      currentUserId: user.uid,
      currentUserName: senderName,
      currentUserAvatar: senderAvatar,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverAvatar: receiverAvatar,
      lastMessageId: messageId,
      lastMessage: trimmedText,
      lastMessageAt: createdAt,
    );
  }

  /// Updates the per-user conversation index entries for both participants
  /// after a message is sent. Separated from message creation so the two
  /// concerns can evolve independently.
  Future<void> _updateConversationMetadata({
    required String conversationId,
    required String currentUserId,
    required String currentUserName,
    required String currentUserAvatar,
    required String receiverId,
    required String receiverName,
    required String receiverAvatar,
    required String lastMessageId,
    required String lastMessage,
    required Object lastMessageAt,
  }) async {
    final updates = <String, dynamic>{
      'user_conversations/$currentUserId/$conversationId/otherUserId':
          receiverId,
      'user_conversations/$currentUserId/$conversationId/otherUserName':
          receiverName,
      'user_conversations/$currentUserId/$conversationId/otherUserAvatar':
          receiverAvatar,
      'user_conversations/$currentUserId/$conversationId/lastMessageId':
          lastMessageId,
      'user_conversations/$currentUserId/$conversationId/lastMessage':
          lastMessage,
      'user_conversations/$currentUserId/$conversationId/lastMessageAt':
          lastMessageAt,
      'user_conversations/$currentUserId/$conversationId/unreadCount': 0,
      'user_conversations/$receiverId/$conversationId/otherUserId':
          currentUserId,
      'user_conversations/$receiverId/$conversationId/otherUserName':
          currentUserName,
      'user_conversations/$receiverId/$conversationId/otherUserAvatar':
          currentUserAvatar,
      'user_conversations/$receiverId/$conversationId/lastMessageId':
          lastMessageId,
      'user_conversations/$receiverId/$conversationId/lastMessage': lastMessage,
      'user_conversations/$receiverId/$conversationId/lastMessageAt':
          lastMessageAt,
      'user_conversations/$receiverId/$conversationId/unreadCount':
          ServerValue.increment(1),
    };

    try {
      await _db.ref().update(updates).timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw Exception('Timed out while updating conversation index'),
          );
    } on FirebaseException catch (e) {
      throw Exception(
        'Failed to update conversation metadata: ${e.message ?? e.code}',
      );
    }
  }

  /// Returns a shared, ref-counted stream of messages for [conversationId].
  ///
  /// The underlying Firebase listener is opened on the first subscription and
  /// cancelled when the last subscriber unsubscribes — no stale listeners.
  /// [shareValueSeeded] seeds with [] so subscribers never see a waiting state;
  /// the first frame always has data (empty or cached), removing the need for
  /// manual timers or a secondary StreamController.
  Stream<List<ChatMessageModel>> getMessagesStream(String conversationId) {
    return _messageStreams[conversationId] ??= _db
        .ref('chats/$conversationId/messages')
        .orderByChild('createdAt')
        .onValue
        .map((event) {
          final data = event.snapshot.value;
          if (data == null) return const <ChatMessageModel>[];
          if (data is! Map) return const <ChatMessageModel>[];
          final map = Map<dynamic, dynamic>.from(data);
          return (map.entries.map((entry) {
            final value = entry.value;
            if (value is! Map) return null;
            final msgMap = Map<dynamic, dynamic>.from(value);
            return ChatMessageModel.fromMap(entry.key as String, msgMap);
          }).whereType<ChatMessageModel>().toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
        })
        .doOnError((_, _) => _messageStreams.remove(conversationId))
        .shareValueSeeded(const <ChatMessageModel>[]);
  }

  /// Returns a shared, ref-counted stream of conversations for the current user.
  ///
  /// Same lifecycle guarantees as [getMessagesStream].
  Stream<List<ChatConversationModel>> getConversationsStream() {
    final user = _currentUser;
    if (user == null) {
      return Stream<List<ChatConversationModel>>.error(
        Exception('Not authenticated'),
      );
    }

    return _conversationStreams[user.uid] ??= _db
        .ref('user_conversations/${user.uid}')
        .orderByChild('lastMessageAt')
        .onValue
        .map((event) {
          final data = event.snapshot.value;
          if (data == null) return const <ChatConversationModel>[];
          if (data is! Map) return const <ChatConversationModel>[];
          final map = Map<dynamic, dynamic>.from(data);
          return (map.entries.map((entry) {
            final value = entry.value;
            if (value is! Map) return null;
            final conversationMap = Map<dynamic, dynamic>.from(value);
            return ChatConversationModel.fromMap(
              entry.key as String,
              conversationMap,
            );
          }).whereType<ChatConversationModel>().toList()
            ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt)));
        })
        .doOnError((_, _) => _conversationStreams.remove(user.uid))
        .shareValueSeeded(const <ChatConversationModel>[]);
  }

  /// Clears all cached stream objects. Call this on logout so that
  /// BehaviorSubjects from the previous session do not retain stale message
  /// data in memory or leak to a subsequent user on the same device.
  void clearStreamCaches() {
    _messageStreams.clear();
    _conversationStreams.clear();
  }

  /// Fetches all conversations for the current user and resets every
  /// non-zero [unreadCount] to zero in a single multi-path update.
  ///
  /// This does NOT mark individual messages as [isRead] because the per-
  /// conversation [markAsRead] (called when the user opens a chat) handles
  /// that.  Clearing [unreadCount] here is sufficient to remove the badge;
  /// the next time the user opens a conversation, [markAsRead] will catch
  /// up on message-level read status.
  // Đặt unreadCount = 0 cho TẤT CẢ hội thoại của user hiện tại (xóa badge tổng)
  Future<void> markAllAsRead() async {
    final user = _currentUser;
    if (user == null) return;

    final snapshot = await _db
        .ref('user_conversations/${user.uid}')
        .get()
        .timeout(const Duration(seconds: 10));

    if (!snapshot.exists || snapshot.value == null) return;
    final raw = snapshot.value;
    if (raw is! Map) return;

    final updates = <String, dynamic>{};
    for (final entry in raw.entries) {
      final convId = entry.key as String;
      final convData = entry.value;
      if (convData is! Map) continue;
      final unreadCount = convData['unreadCount'];
      if (unreadCount is num && unreadCount > 0) {
        updates[
            'user_conversations/${user.uid}/$convId/unreadCount'] = 0;
      }
    }

    if (updates.isNotEmpty) {
      await _db.ref().update(updates).timeout(const Duration(seconds: 10));
    }
  }

  // Đánh dấu đã đọc cho 1 hội thoại: reset unreadCount rồi cập nhật isRead từng tin nhắn
  Future<void> markAsRead(String conversationId) async {
    final user = _currentUser;
    if (user == null) return;

    final unreadSnap = await _db
        .ref('user_conversations/${user.uid}/$conversationId/unreadCount')
        .get()
        .timeout(const Duration(seconds: 10));
    final unread = unreadSnap.value;
    if (unread == null || (unread is num && unread <= 0)) return;

    final messagesSnap = await _db
        .ref('chats/$conversationId/messages')
        .orderByChild('isRead')
        .equalTo(false)
        .get()
        .timeout(const Duration(seconds: 10));

    // Reset the badge immediately — this write is independent so a later
    // isRead failure cannot roll it back.
    await _db
        .ref('user_conversations/${user.uid}/$conversationId/unreadCount')
        .set(0)
        .timeout(const Duration(seconds: 10));

    final isReadUpdates = <String, dynamic>{};

    if (messagesSnap.exists && messagesSnap.value != null) {
      final raw = messagesSnap.value;
      if (raw is Map) {
        final map = Map<dynamic, dynamic>.from(raw);
        for (final entry in map.entries) {
          final value = entry.value;
          if (value is! Map) continue;
          final msgData = Map<dynamic, dynamic>.from(value);
          final senderId = msgData['senderId'] as String? ?? '';
          final isRead = msgData['isRead'] as bool? ?? false;
          if (senderId != user.uid && !isRead) {
            isReadUpdates['chats/$conversationId/messages/${entry.key}/isRead'] =
                true;
          }
        }
      }
    }

    if (isReadUpdates.isNotEmpty) {
      await _db.ref().update(isReadUpdates).timeout(const Duration(seconds: 10));
    }
  }
}
