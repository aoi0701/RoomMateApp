import 'package:flutter/foundation.dart';

import '../../data/models/chat_conversation_model.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/repositories/chat_repository.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repository;

  bool _isSending = false;
  String? _errorMessage;

  ChatViewModel({required ChatRepository repository})
      : _repository = repository;

  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _repository.currentUserId;

  String getConversationId(String uid1, String uid2) =>
      _repository.getConversationId(uid1, uid2);

  Stream<List<ChatConversationModel>> getConversationsStream() =>
      _repository.getConversationsStream();

  Stream<List<ChatMessageModel>> getMessagesStream(String conversationId) =>
      _repository.getMessagesStream(conversationId);

  Future<void> ensureConversation({
    required String conversationId,
    required String otherUserId,
  }) async {
    await _repository.ensureConversation(
      conversationId: conversationId,
      otherUserId: otherUserId,
    );
  }

  Future<bool> sendMessage({
    required String conversationId,
    required String receiverId,
    required String text,
    required String receiverName,
    required String receiverAvatar,
  }) async {
    if (text.trim().isEmpty) return false;
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        text: text,
        receiverName: receiverName,
        receiverAvatar: receiverAvatar,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void clearSession() => _repository.clearStreamCaches();

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
    } catch (e) {
      debugPrint('[ChatViewModel] markAllAsRead failed: $e');
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await _repository.markAsRead(conversationId);
    } catch (e) {
      debugPrint('[ChatViewModel] markAsRead failed for $conversationId: $e');
    }
  }
}
