import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/viewmodels/user_profile_viewmodel.dart';
import '../../../roommate/presentation/viewmodels/roommate_request_viewmodel.dart';
import '../../../roommate/presentation/views/send_request_screen.dart';
import '../../data/models/post_model.dart';
import '../widgets/amenity_grid.dart';
import '../widgets/lifestyle_habit_wrap.dart';

class PostDetailScreen extends StatelessWidget {
  final PostModel post;
  final String? currentUserId;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.currentUserId,
  });

  bool get _isOwner => currentUserId != null && currentUserId == post.ownerId;

  String _formatMoney(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = text.length - 1; i >= 0; i--) {
      buffer.write(text[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Chưa cập nhật';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  String _buildAddress() {
    final parts = <String>[
      if (post.location.trim().isNotEmpty) post.location.trim(),
      if (post.district.trim().isNotEmpty) post.district.trim(),
      if (post.province.trim().isNotEmpty) post.province.trim(),
    ];
    if (parts.isEmpty) return 'Chưa cập nhật địa chỉ';
    return parts.join(', ');
  }

  List<String> _galleryImages() {
    if (post.imageUrls.isNotEmpty) return post.imageUrls;
    if (post.imageUrl.trim().isNotEmpty) return [post.imageUrl];
    return const [];
  }

  List<String> _resolveLifestyleHabits(UserModel? owner) {
    if (post.lifestyleHabits.isNotEmpty) {
      return post.lifestyleHabits;
    }

    if (owner == null) {
      return const [];
    }

    return owner.habits
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final galleryImages = _galleryImages();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _HeaderGallery(
                      imageUrls: galleryImages,
                      onBack: () => Navigator.pop(context),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildOwnerCard(context),
                            const SizedBox(height: 16),
                            _buildSummaryCard(),
                            const SizedBox(height: 16),
                            _buildInfoGridCard(),
                            const SizedBox(height: 16),
                            if (post.amenities.isNotEmpty) ...[
                              _buildAmenitiesCard(),
                              const SizedBox(height: 16),
                            ],
                            _buildLifestyleHabitsCard(context),
                            _buildDescriptionCard(),
                            if (galleryImages.length > 1) ...[
                              const SizedBox(height: 16),
                              _buildGalleryCard(galleryImages),
                            ],
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerCard(BuildContext context) {
    final profileVm = context.read<UserProfileViewModel>();

    return _CardShell(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: profileVm.getUserProfileStream(post.ownerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 92,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final owner = snapshot.hasData && snapshot.data!.exists
              ? UserModel.fromDocument(snapshot.data!)
              : null;

          final ownerName = owner?.fullName.trim().isNotEmpty == true
              ? owner!.fullName
              : 'Người đăng bài';
          final subtitleParts = <String>[
            if (owner?.gender.trim().isNotEmpty == true) owner!.gender.trim(),
            if (owner?.address.trim().isNotEmpty == true) owner!.address.trim(),
          ];
          final ownerSubtitle = owner == null
              ? 'Chưa có thông tin hồ sơ'
              : subtitleParts.isEmpty
                  ? 'Thành viên RoomMate'
                  : subtitleParts.join(' - ');
          final ownerContact = owner == null
              ? 'Không có thông tin liên hệ'
              : owner.phone.trim().isNotEmpty
                  ? owner.phone.trim()
                  : owner.email.trim().isNotEmpty
                      ? owner.email.trim()
                      : 'Chưa cập nhật liên hệ';

          return Row(
            children: [
              AppAvatar(
                name: ownerName,
                avatarUrl: owner?.avatarUrl.isNotEmpty == true
                    ? owner!.avatarUrl
                    : null,
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ownerSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ownerContact,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.title.trim().isNotEmpty
                ? post.title.trim()
                : 'Bài đăng tìm bạn ở ghép',
            style: AppTextStyles.h1.copyWith(fontSize: 24, height: 1.2),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _buildAddress(),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _TopMetric(
                  icon: Icons.payments_outlined,
                  label: 'Giá',
                  value: post.price > 0
                      ? '${_formatMoney(post.price)}đ/tháng'
                      : 'Thỏa thuận',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TopMetric(
                  icon: Icons.king_bed_outlined,
                  label: 'Loại phòng',
                  value: post.roomType.trim().isNotEmpty
                      ? post.roomType.trim()
                      : 'Chưa cập nhật',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGridCard() {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin chi tiết', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final aspectRatio = constraints.maxWidth < 380 ? 1.28 : 1.55;
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: aspectRatio,
                children: [
                  _InfoTile(
                    icon: Icons.square_foot_outlined,
                    label: 'Diện tích',
                    value: post.area > 0
                        ? '${post.area} m²'
                        : 'Chưa cập nhật',
                  ),
                  _InfoTile(
                    icon: Icons.group_outlined,
                    label: 'Sức chứa',
                    value: post.capacity > 0
                        ? '${post.capacity} người'
                        : 'Chưa cập nhật',
                  ),
                  _InfoTile(
                    icon: Icons.map_outlined,
                    label: 'Tỉnh/Thành phố',
                    value: post.province.trim().isNotEmpty
                        ? post.province.trim()
                        : 'Chưa cập nhật',
                  ),
                  _InfoTile(
                    icon: Icons.location_city_outlined,
                    label: 'Quận/Huyện',
                    value: post.district.trim().isNotEmpty
                        ? post.district.trim()
                        : 'Chưa chọn',
                  ),
                  _InfoTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Đăng lúc',
                    value: _formatDate(post.createdAt),
                  ),
                  _InfoTile(
                    icon: Icons.update_outlined,
                    label: 'Cập nhật',
                    value: _formatDate(post.updatedAt),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesCard() {
    final amenities = post.amenities
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tiện ích', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          if (amenities.isNotEmpty)
            _AmenityEqualRow(amenities: amenities),
        ],
      ),
    );
  }

  Widget _buildLifestyleHabitsCard(BuildContext context) {
    final profileVm = context.read<UserProfileViewModel>();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profileVm.getUserProfileStream(post.ownerId),
      builder: (context, snapshot) {
        final owner = snapshot.hasData && snapshot.data!.exists
            ? UserModel.fromDocument(snapshot.data!)
            : null;
        final habits = _resolveLifestyleHabits(owner);

        if (habits.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            _CardShell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thói quen sinh hoạt', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  LifestyleHabitWrap(
                    habitIds: habits,
                    equalWidth: true,
                    columns: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildDescriptionCard() {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mô tả chi tiết', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Text(
            post.description.trim().isNotEmpty
                ? post.description.trim()
                : 'Người đăng bài chưa bổ sung mô tả.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryCard(List<String> imageUrls) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hình ảnh khác', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final imageUrl = imageUrls[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    width: 140,
                    height: 108,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 140,
                      height: 108,
                      color: AppColors.inputFill,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    if (_isOwner) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: AppPrimaryButton(
        label: 'Gửi yêu cầu ở ghép',
        onTap: () async {
          final viewModel = context.read<RoommateRequestViewModel>();
          final messenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);

          final hasRequested = await viewModel.hasPendingRequest(post.id);

          if (hasRequested) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Bạn đã gửi yêu cầu cho bài đăng này rồi'),
              ),
            );
            return;
          }

          if (!context.mounted) return;

          navigator.push(
            MaterialPageRoute(
              builder: (_) => SendRequestScreen(postId: post.id),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderGallery extends StatelessWidget {
  final List<String> imageUrls;
  final VoidCallback onBack;

  const _HeaderGallery({
    required this.imageUrls,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 310,
          child: imageUrls.isEmpty
              ? Container(
                  width: double.infinity,
                  color: AppColors.inputFill,
                  child: const Icon(
                    Icons.image_outlined,
                    size: 56,
                    color: AppColors.textHint,
                  ),
                )
              : PageView.builder(
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    final imageUrl = imageUrls[index];
                    return Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.inputFill,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 56,
                          color: AppColors.textHint,
                        ),
                      ),
                    );
                  },
                ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: _CircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
        ),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;

  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TopMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TopMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenityEqualRow extends StatelessWidget {
  final List<String> amenities;

  const _AmenityEqualRow({required this.amenities});

  @override
  Widget build(BuildContext context) {
    final visibleAmenities = amenities.take(4).toList(growable: false);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < visibleAmenities.length; i++) ...[
          Expanded(child: _AmenityBox(label: visibleAmenities[i])),
          if (i != visibleAmenities.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _AmenityBox extends StatelessWidget {
  final String label;

  const _AmenityBox({required this.label});

  @override
  Widget build(BuildContext context) {
    final data = AmenityCatalog.resolve(label);

    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}
