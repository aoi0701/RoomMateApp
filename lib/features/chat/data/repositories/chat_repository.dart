import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';

class ChatRepository {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db;

  static const _dbUrl =
      'https://roommateapp-fbb4f-default-rtdb.asia-southeast1.firebasedatabase.app';

  ChatRepository({
    FirebaseAuth? auth,
    FirebaseDatabase? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: _dbUrl,
            );

  User? get _currentUser => _auth.currentUser;

  String getConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return sorted.join('_');
  }

  List<String> _getSortedParticipants(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return sorted;
  }

  Future<void> ensureConversation({
    required String conversationId,
    required String otherUserId,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not authenticated');

    final participantARef =
        _db.ref('chats/$conversationId/participantAId');
    final participantASnapshot = await participantARef.get();
    if (participantASnapshot.exists) return;

    final participants = _getSortedParticipants(user.uid, otherUserId);
    await _db.ref().update({
      'chats/$conversationId/participantAId': participants[0],
      'chats/$conversationId/participantBId': participants[1],
    });
  }

  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String text,
    required String receiverName,
    required String receiverAvatar,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('Not authenticated');

    final participants = _getSortedParticipants(user.uid, receiverId);
    final trimmedText = text.trim();
    final createdAt = ServerValue.timestamp;
    final messagesRef = _db.ref('chats/$conversationId/messages').push();
    final messageId = messagesRef.key!;
    final senderName = user.displayName ?? '';
    final senderAvatar = user.photoURL ?? '';

    final updates = <String, dynamic>{
      'chats/$conversationId/participantAId': participants[0],
      'chats/$conversationId/participantBId': participants[1],
      'chats/$conversationId/messages/$messageId/senderId': user.uid,
      'chats/$conversationId/messages/$messageId/senderName': senderName,
      'chats/$conversationId/messages/$messageId/senderAvatar': senderAvatar,
      'chats/$conversationId/messages/$messageId/text': trimmedText,
      'chats/$conversationId/messages/$messageId/createdAt': createdAt,
      'chats/$conversationId/messages/$messageId/isRead': false,
      'user_conversations/${user.uid}/$conversationId/otherUserId': receiverId,
      'user_conversations/${user.uid}/$conversationId/otherUserName':
          receiverName,
      'user_conversations/${user.uid}/$conversationId/otherUserAvatar':
          receiverAvatar,
      'user_conversations/${user.uid}/$conversationId/lastMessageId':
          messageId,
      'user_conversations/${user.uid}/$conversationId/lastMessage':
          trimmedText,
      'user_conversations/${user.uid}/$conversationId/lastMessageAt':
          createdAt,
      'user_conversations/${user.uid}/$conversationId/unreadCount': 0,
      'user_conversations/$receiverId/$conversationId/otherUserId': user.uid,
      'user_conversations/$receiverId/$conversationId/otherUserName':
          senderName,
      'user_conversations/$receiverId/$conversationId/otherUserAvatar':
          senderAvatar,
      'user_conversations/$receiverId/$conversationId/lastMessageId':
          messageId,
      'user_conversations/$receiverId/$conversationId/lastMessage':
          trimmedText,
      'user_conversations/$receiverId/$conversationId/lastMessageAt':
          createdAt,
      'user_conversations/$receiverId/$conversationId/unreadCount':
          ServerValue.increment(1),
    };

    try {
      await _db.ref().update(updates);
    } on FirebaseException catch (e) {
      throw Exception(
        'Failed to update chat conversation metadata for both participants: ${e.message ?? e.code}',
      );
    }
  }

  Stream<List<ChatMessageModel>> getMessagesStream(String conversationId) {
    return _db
        .ref('chats/$conversationId/messages')
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return <ChatMessageModel>[];

      final map = Map<dynamic, dynamic>.from(data as Map);
      final messages = map.entries.map((entry) {
        final msgMap = Map<dynamic, dynamic>.from(entry.value as Map);
        return ChatMessageModel.fromMap(entry.key as String, msgMap);
      }).toList();

      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });
  }

  Stream<List<ChatConversationModel>> getConversationsStream() {
    final user = _currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .ref('user_conversations/${user.uid}')
        .orderByChild('lastMessageAt')
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return <ChatConversationModel>[];

      final map = Map<dynamic, dynamic>.from(data as Map);
      final conversations = map.entries.map((entry) {
        final conversationMap = Map<dynamic, dynamic>.from(entry.value as Map);
        return ChatConversationModel.fromMap(
          entry.key as String,
          conversationMap,
        );
      }).toList();

      conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return conversations;
    });
  }

  Future<void> markAsRead(String conversationId) async {
    final user = _currentUser;
    if (user == null) return;

    final messagesSnap =
        await _db
            .ref('chats/$conversationId/messages')
            .orderByChild('isRead')
            .equalTo(false)
            .get();

    final updates = <String, dynamic>{
      'user_conversations/${user.uid}/$conversationId/unreadCount': 0,
    };

    if (messagesSnap.exists && messagesSnap.value != null) {
      final map =
          Map<dynamic, dynamic>.from(messagesSnap.value as Map);
      for (final entry in map.entries) {
        final msgData =
            Map<dynamic, dynamic>.from(entry.value as Map);
        final senderId = msgData['senderId'] as String? ?? '';
        final isRead = msgData['isRead'] as bool? ?? false;
        if (senderId != user.uid && !isRead) {
          updates['chats/$conversationId/messages/${entry.key}/isRead'] =
              true;
        }
      }
    }

    await _db.ref().update(updates);
  }
}
