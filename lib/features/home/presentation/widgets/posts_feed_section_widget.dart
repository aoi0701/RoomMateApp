import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/helpers/home_formatters.dart';
import '../../../post/data/models/post_model.dart';
import '../../../post/presentation/viewmodels/post_list_viewmodel.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/viewmodels/user_profile_viewmodel.dart';

// Widget hiển thị feed bài đăng phòng trọ trên màn hình Home, hỗ trợ infinite scroll
class PostsFeedSectionWidget extends StatelessWidget {
  final void Function(PostModel) onViewPost;

  const PostsFeedSectionWidget({super.key, required this.onViewPost});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Bài đăng nổi bật', style: AppTextStyles.h2),
        ),
        const SizedBox(height: 16),
        Consumer<PostListViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _PostCardShimmer(),
              );
            }

            if (vm.errorMessage != null) {
              final isIndexBuilding = vm.errorMessage!.contains('index') &&
                  (vm.errorMessage!.contains('being built') ||
                      vm.errorMessage!.contains('currently') ||
                      vm.errorMessage!.contains('requires an index'));
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _InlineMessage(
                  icon: isIndexBuilding
                      ? Icons.hourglass_top_rounded
                      : Icons.error_outline_rounded,
                  title: isIndexBuilding
                      ? 'Đang chuẩn bị dữ liệu'
                      : 'Không tải được bài đăng',
                  subtitle: isIndexBuilding
                      ? 'Hệ thống đang được thiết lập, vui lòng thử lại sau vài phút.'
                      : vm.errorMessage!,
                ),
              );
            }

            final posts = vm.filteredPosts;

            if (posts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _InlineMessage(
                  icon: Icons.home_work_outlined,
                  title: 'Chưa có bài đăng nào',
                  subtitle:
                      'Khi có người đăng bài, nội dung sẽ hiển thị tại đây.',
                ),
              );
            }

            return Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _FeaturedPostCard(
                      post: post,
                      onViewDetail: () => onViewPost(post),
                    );
                  },
                ),
                if (vm.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Featured post card ────────────────────────────────────────────────────────

class _FeaturedPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onViewDetail;

  const _FeaturedPostCard({required this.post, required this.onViewDetail});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewDetail,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 8,
                child: post.imageUrl.trim().isNotEmpty
                    ? Image.network(
                        post.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, _) =>
                            _PostImageFallback(title: post.title),
                      )
                    : _PostImageFallback(title: post.title),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PostOwnerHeader(post: post),
                  const SizedBox(height: 12),
                  Text(
                    post.title.isNotEmpty
                        ? post.title
                        : 'Bài đăng tìm bạn ở ghép',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3,
                  ),
                  if (post.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      post.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _buildPostTags(post),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton(
                      onPressed: onViewDetail,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: AppTextStyles.buttonSm.copyWith(height: 1.2),
                        minimumSize: const Size(0, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Xem chi tiết'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostOwnerHeader extends StatelessWidget {
  final PostModel post;
  const _PostOwnerHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final profileVm = context.read<UserProfileViewModel>();

    return FutureBuilder<UserModel?>(
      future: profileVm.getUserProfile(post.ownerId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final displayName = formatLastTwoWords(user?.fullName ?? '');
        final displayAddress = formatReadableAddress(
          fullAddress: user?.address ?? '',
          preferredLocation: user?.preferredLocation ?? '',
          district: post.district,
          province: post.province,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppAvatar(
              name: displayName,
              avatarUrl: user?.avatarUrl ?? '',
              size: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label,
                  ),
                  Text(
                    displayAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                post.price > 0
                    ? '${FormatUtils.formatMoney(post.price)}đ'
                    : 'Thỏa thuận',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

List<Widget> _buildPostTags(PostModel post) {
  final tags = <String>[];
  if (post.amenities.isNotEmpty) tags.addAll(post.amenities.take(2));
  if (tags.isEmpty && post.roomType.trim().isNotEmpty) {
    tags.add(post.roomType.trim());
  }
  if (tags.length < 3 && post.area > 0) tags.add('${post.area} m²');
  if (tags.length < 3 && post.capacity > 0) tags.add('${post.capacity} người');
  return tags.take(3).map((item) => _TagChip(label: item)).toList();
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _PostImageFallback extends StatelessWidget {
  final String title;
  const _PostImageFallback({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.home_work_outlined,
              color: AppColors.primary,
              size: 36,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InlineMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _PostCardShimmer extends StatelessWidget {
  const _PostCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: _ShimmerBox(
              width: double.infinity,
              height: 180,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _ShimmerBox(
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBox(width: 120, height: 13),
                        const SizedBox(height: 6),
                        _ShimmerBox(width: 80, height: 11),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ShimmerBox(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                _ShimmerBox(width: 200, height: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (ctx, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFFE2E8F0),
            const Color(0xFFF1F5F9),
            _animation.value,
          ),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}
