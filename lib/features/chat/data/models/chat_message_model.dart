class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.text,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessageModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return ChatMessageModel(
      id: id,
      senderId: (map['senderId'] as String?) ?? '',
      senderName: (map['senderName'] as String?) ?? '',
      senderAvatar: (map['senderAvatar'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? 0,
      ),
      isRead: (map['isRead'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'text': text,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isRead': isRead,
      };
}
