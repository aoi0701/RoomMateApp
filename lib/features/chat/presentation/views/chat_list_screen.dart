import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../data/models/chat_conversation_model.dart';
import '../viewmodels/chat_viewmodel.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${time.day}/${time.month}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ChatViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Nhắn tin', style: AppTextStyles.h2),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<ChatConversationModel>>(
        stream: vm.conversationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Đang tải tin nhắn...');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Không tải được tin nhắn',
              message: snapshot.error.toString(),
            );
          }

          final convs = snapshot.data ?? [];
          if (convs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Chưa có tin nhắn',
              message:
                  'Bắt đầu trò chuyện từ trang cá nhân hoặc bài đăng',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: convs.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1,
              indent: 82,
              endIndent: 20,
              color: AppColors.border,
            ),
            itemBuilder: (context, index) {
              final conv = convs[index];
              return _ConversationTile(
                conv: conv,
                timeText: _formatTime(conv.lastMessageAt),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      otherUserId: conv.otherUserId,
                      otherUserName: conv.otherUserName,
                      otherUserAvatar: conv.otherUserAvatar,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversationModel conv;
  final String timeText;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conv,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conv.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            AppAvatar(
              name: conv.otherUserName,
              avatarUrl: conv.otherUserAvatar.isNotEmpty
                  ? conv.otherUserAvatar
                  : null,
              size: 52,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.otherUserName.isNotEmpty
                        ? conv.otherUserName
                        : 'Người dùng',
                    style: hasUnread
                        ? AppTextStyles.labelLg
                        : AppTextStyles.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conv.lastMessage.isNotEmpty
                        ? conv.lastMessage
                        : 'Bắt đầu cuộc trò chuyện',
                    style: AppTextStyles.body.copyWith(
                      color: hasUnread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: hasUnread
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeText,
                  style: AppTextStyles.caption.copyWith(
                    color: hasUnread
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      conv.unreadCount > 99
                          ? '99+'
                          : '${conv.unreadCount}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
