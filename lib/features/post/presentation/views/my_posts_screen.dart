import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roommateapp/core/utils/format_utils.dart';

import 'package:roommateapp/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:roommateapp/features/post/data/models/post_model.dart';
import 'package:roommateapp/features/post/presentation/viewmodels/post_list_viewmodel.dart';
import 'package:roommateapp/features/post/presentation/viewmodels/post_viewmodel.dart';
import 'package:roommateapp/features/post/presentation/views/post_detail_screen.dart';
import 'package:roommateapp/features/post/presentation/views/edit_post_screen.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_state_widgets.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  Future<void> _showPostActions(
    BuildContext context,
    PostModel post,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                title: Text('Sửa bài đăng', style: AppTextStyles.label),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: Text(
                  'Xóa bài đăng',
                  style: AppTextStyles.label.copyWith(color: AppColors.danger),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) return;

    if (action == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditPostScreen(post: post)),
      );
    }

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Xác nhận xóa', style: AppTextStyles.h3),
          content: Text(
            'Bạn có chắc muốn xóa bài đăng này không?',
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Xóa',
                style: AppTextStyles.label.copyWith(color: AppColors.danger),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      final vm = context.read<PostViewModel>();
      final success = await vm.deletePost(post.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Xóa bài đăng thành công'
                : (vm.errorMessage ?? 'Xóa bài đăng thất bại'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.read<AuthViewModel>();
    final postVm = context.read<PostListViewModel>();

    final user = authVm.user;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text('Chưa đăng nhập', style: AppTextStyles.body),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bài đăng của tôi')),
      body: StreamBuilder<List<PostModel>>(
        stream: postVm.getPostsByUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Đang tải bài đăng...');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Không tải được bài đăng',
              message: '${snapshot.error}',
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const AppEmptyState(
              title: 'Chưa có bài đăng',
              message: 'Các bài đăng của bạn sẽ hiển thị ở đây.',
              icon: Icons.article_outlined,
            );
          }

          final posts = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: posts.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final post = posts[index];

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(
                            post: post,
                            currentUserId: user.uid,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              post.imageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, _) => Container(
                                width: 64,
                                height: 64,
                                color: AppColors.inputFill,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelLg,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  post.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                FormatUtils.formatMoney(post.price),
                                maxLines: 1,
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _showPostActions(context, post),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.more_vert,
                                    size: 20,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
