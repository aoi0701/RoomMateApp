import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../data/models/chat_message_model.dart';
import '../viewmodels/chat_viewmodel.dart';

class ChatDetailScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;

  const ChatDetailScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  String? _conversationId;
  String? _currentUserId;
  bool _isAtBottom = true;
  bool _isConversationReady = false;
  bool _initialized = false;
  String? _screenError;
  // Cached stream - created once so Firebase never opens more than one listener
  // on the same path regardless of how many times the widget rebuilds.
  Stream<List<ChatMessageModel>>? _messagesStream;

  @override
  void initState() {
    super.initState();
    final chatVm = context.read<ChatViewModel>();
    final currentUserId = chatVm.currentUserId;
    if (currentUserId == null) {
      _screenError = 'Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.';
      return;
    }

    _currentUserId = currentUserId;
    _conversationId = chatVm.getConversationId(currentUserId, widget.otherUserId);
    if (!_initialized) {
      _initialized = true;
      _initializeConversation();
    }
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      _isAtBottom = pos.pixels >= pos.maxScrollExtent - 100;
    });
  }

  Future<void> _initializeConversation() async {
    final conversationId = _conversationId;
    if (conversationId == null) return;

    final chatVm = context.read<ChatViewModel>();
    try {
      await chatVm.ensureConversation(
        conversationId: conversationId,
        otherUserId: widget.otherUserId,
      );
      // markAsRead runs once here, not inside any repeating listener callback.
      await chatVm.markAsRead(conversationId);
      if (!mounted) return;
      setState(() {
        // Create the stream exactly once. StreamBuilder keeps this subscription
        // alive for the lifetime of the screen and cancels it on dispose.
        _messagesStream = chatVm.getMessagesStream(conversationId);
        _isConversationReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _screenError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final conversationId = _conversationId;
    if (text.isEmpty || conversationId == null) return;

    _textController.clear();
    final vm = context.read<ChatViewModel>();
    final success = await vm.sendMessage(
      conversationId: conversationId,
      receiverId: widget.otherUserId,
      text: text,
      receiverName: widget.otherUserName,
      receiverAvatar: widget.otherUserAvatar,
    );

    if (!mounted) return;
    if (!success) {
      _textController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Không gửi được tin nhắn'),
        ),
      );
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId;
    final conversationId = _conversationId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            AppAvatar(
              name: widget.otherUserName,
              avatarUrl: widget.otherUserAvatar.isNotEmpty
                  ? widget.otherUserAvatar
                  : null,
              size: 38,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName
                    : 'Người dùng',
                style: AppTextStyles.labelLg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _screenError != null
                ? AppErrorState(
                    title: 'Không thể mở cuộc trò chuyện',
                    message: _screenError!,
                  )
                : !_isConversationReady
                ? const AppLoadingState(
                    message: 'Đang chuẩn bị cuộc trò chuyện...',
                  )
                : currentUserId == null || conversationId == null
                ? const AppErrorState(
                    title: 'Không thể mở cuộc trò chuyện',
                    message: 'Thiếu thông tin người dùng hiện tại.',
                  )
                : StreamBuilder<List<ChatMessageModel>>(
                    // Use the cached stream - same object reference every rebuild
                    // means StreamBuilder never opens a second Firebase listener.
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const AppLoadingState(
                          message: 'Đang tải tin nhắn...',
                        );
                      }

                      if (snapshot.hasError) {
                        return AppErrorState(
                          title: 'Lỗi tải tin nhắn',
                          message: snapshot.error.toString(),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return const AppEmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Chưa có tin nhắn',
                          message: 'Hãy gửi lời nhắn đầu tiên!',
                        );
                      }

                      final lastMessage = messages.isNotEmpty
                          ? messages.last
                          : null;
                      final isMine = lastMessage?.senderId == currentUserId;
                      if (_isAtBottom || isMine) {
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToBottom(),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMine = msg.senderId == currentUserId;
                          final showTimestamp =
                              index == 0 ||
                              messages[index].createdAt
                                      .difference(messages[index - 1].createdAt)
                                      .inMinutes
                                      .abs() >
                                  5;

                          return _MessageItem(
                            message: msg,
                            isMine: isMine,
                            showTimestamp: showTimestamp,
                          );
                        },
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.textHint,
                ),
                filled: true,
                fillColor: AppColors.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 6),
          Consumer<ChatViewModel>(
            builder: (context, vm, _) => SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: vm.isSending ? null : _sendMessage,
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;
  final bool showTimestamp;

  const _MessageItem({
    required this.message,
    required this.isMine,
    required this.showTimestamp,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              _buildTimestampLabel(message.createdAt),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMine
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isMine
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                border: isMine ? null : Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: AppTextStyles.body.copyWith(
                      color: isMine ? Colors.white : AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _buildTimestampLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDay).inDays;

    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return 'Hôm nay $timeStr';
    if (diff == 1) return 'Hôm qua $timeStr';
    return '${dt.day}/${dt.month}/${dt.year} $timeStr';
  }
}
