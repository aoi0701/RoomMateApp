class ChatConversationModel {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ChatConversationModel({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatConversationModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final lastMessageAt = map['lastMessageAt'];
    final unreadCount = map['unreadCount'];

    return ChatConversationModel(
      id: id,
      otherUserId: (map['otherUserId'] as String?) ?? '',
      otherUserName: (map['otherUserName'] as String?) ?? '',
      otherUserAvatar: (map['otherUserAvatar'] as String?) ?? '',
      lastMessage: (map['lastMessage'] as String?) ?? '',
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(
        lastMessageAt is num ? lastMessageAt.toInt() : 0,
      ),
      unreadCount: unreadCount is num ? unreadCount.toInt() : 0,
    );
  }
}
