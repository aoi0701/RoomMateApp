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

  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String text,
    required String receiverName,
    required String receiverAvatar,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final now = ServerValue.timestamp;
    final messagesRef =
        _db.ref('chats/$conversationId/messages').push();
    final messageId = messagesRef.key!;

    final messageData = {
      'senderId': user.uid,
      'senderName': user.displayName ?? '',
      'senderAvatar': user.photoURL ?? '',
      'text': text.trim(),
      'createdAt': now,
      'isRead': false,
    };

    final senderConvData = {
      'otherUserId': receiverId,
      'otherUserName': receiverName,
      'otherUserAvatar': receiverAvatar,
      'lastMessage': text.trim(),
      'lastMessageAt': now,
      'unreadCount': 0,
    };

    final receiverConvData = {
      'otherUserId': user.uid,
      'otherUserName': user.displayName ?? '',
      'otherUserAvatar': user.photoURL ?? '',
      'lastMessage': text.trim(),
      'lastMessageAt': now,
    };

    // Increment receiver's unreadCount atomically
    final receiverUnreadRef =
        _db.ref('user_conversations/$receiverId/$conversationId/unreadCount');

    await _db.ref().update({
      'chats/$conversationId/messages/$messageId': messageData,
      'user_conversations/${user.uid}/$conversationId': senderConvData,
      'user_conversations/$receiverId/$conversationId/otherUserId':
          receiverConvData['otherUserId'],
      'user_conversations/$receiverId/$conversationId/otherUserName':
          receiverConvData['otherUserName'],
      'user_conversations/$receiverId/$conversationId/otherUserAvatar':
          receiverConvData['otherUserAvatar'],
      'user_conversations/$receiverId/$conversationId/lastMessage':
          receiverConvData['lastMessage'],
      'user_conversations/$receiverId/$conversationId/lastMessageAt':
          receiverConvData['lastMessageAt'],
    });

    // Increment unread count for receiver separately
    await receiverUnreadRef.set(ServerValue.increment(1));
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
      final convs = map.entries.map((entry) {
        final convMap = Map<dynamic, dynamic>.from(entry.value as Map);
        return ChatConversationModel.fromMap(entry.key as String, convMap);
      }).toList();

      convs.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return convs;
    });
  }

  Future<void> markAsRead(String conversationId) async {
    final user = _currentUser;
    if (user == null) return;

    await _db
        .ref('user_conversations/${user.uid}/$conversationId/unreadCount')
        .set(0);

    // Mark all unread messages in this conversation as read
    final messagesSnap =
        await _db.ref('chats/$conversationId/messages').get();
    if (!messagesSnap.exists || messagesSnap.value == null) return;

    final map =
        Map<dynamic, dynamic>.from(messagesSnap.value as Map);
    final updates = <String, dynamic>{};
    for (final entry in map.entries) {
      final msgData =
          Map<dynamic, dynamic>.from(entry.value as Map);
      final senderId = msgData['senderId'] as String? ?? '';
      final isRead = msgData['isRead'] as bool? ?? false;
      if (senderId != user.uid && !isRead) {
        updates['chats/$conversationId/messages/${entry.key}/isRead'] = true;
      }
    }
    if (updates.isNotEmpty) {
      await _db.ref().update(updates);
    }
  }
}
