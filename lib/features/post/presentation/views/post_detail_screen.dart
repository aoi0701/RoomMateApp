import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/viewmodels/user_profile_viewmodel.dart';
import '../../../profile/presentation/views/user_profile_screen.dart';
import '../../../roommate/presentation/viewmodels/roommate_request_viewmodel.dart';
import '../../../roommate/presentation/views/send_request_screen.dart';
import '../../data/models/post_model.dart';

class PostDetailScreen extends StatelessWidget {
  final PostModel post;
  final String? currentUserId;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.currentUserId,
  });

  static const Color primaryBlue = Color(0xFF3B6EF5);
  static const Color bgColor = Color(0xFFF5F7FB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color lightBlue = Color(0xFFEAF2FF);

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
    if (value == null) return 'Chua cap nhat';
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
    if (parts.isEmpty) return 'Chua cap nhat dia chi';
    return parts.join(', ');
  }

  List<String> _galleryImages() {
    if (post.imageUrls.isNotEmpty) return post.imageUrls;
    if (post.imageUrl.trim().isNotEmpty) return [post.imageUrl];
    return const [];
  }

  Future<void> _openOwnerProfile(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: post.ownerId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final galleryImages = _galleryImages();

    return Scaffold(
      backgroundColor: bgColor,
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
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final owner = snapshot.hasData && snapshot.data!.exists
              ? UserModel.fromDocument(snapshot.data!)
              : null;

          final ownerName = owner?.fullName.trim().isNotEmpty == true
              ? owner!.fullName
              : 'Nguoi dang bai';
          final ownerSubtitle = owner == null
              ? 'Chua co thong tin ho so'
              : [
                  if (owner.gender.trim().isNotEmpty) owner.gender.trim(),
                  if (owner.address.trim().isNotEmpty) owner.address.trim(),
                ].isEmpty
                  ? 'Thanh vien RoomMate'
                  : [
                      if (owner.gender.trim().isNotEmpty) owner.gender.trim(),
                      if (owner.address.trim().isNotEmpty) owner.address.trim(),
                    ].join(' • ');

          final ownerContact = owner == null
              ? 'Khong co thong tin lien he'
              : owner.phone.trim().isNotEmpty
                ? owner.phone.trim()
                : owner.email.trim().isNotEmpty
                  ? owner.email.trim()
                  : 'Chua cap nhat lien he';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: lightBlue,
                    child: Icon(Icons.person, color: primaryBlue, size: 30),
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
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ownerSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ownerContact,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _openOwnerProfile(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryBlue),
                    foregroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Xem ho so',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
            post.title.trim().isNotEmpty ? post.title.trim() : 'Bai dang tim ban o ghep',
            style: const TextStyle(
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _buildAddress(),
                  style: const TextStyle(
                    fontSize: 15,
                    color: textSecondary,
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
                  label: 'Gia',
                  value: post.price > 0
                      ? '${_formatMoney(post.price)}d/thang'
                      : 'Thoa thuan',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TopMetric(
                  icon: Icons.king_bed_outlined,
                  label: 'Loai phong',
                  value: post.roomType.trim().isNotEmpty
                      ? post.roomType.trim()
                      : 'Chua cap nhat',
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
          const Text(
            'Thong tin chi tiet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _InfoTile(
                icon: Icons.square_foot_outlined,
                label: 'Dien tich',
                value: post.area > 0 ? '${post.area} m2' : 'Chua cap nhat',
              ),
              _InfoTile(
                icon: Icons.group_outlined,
                label: 'Suc chua',
                value: post.capacity > 0 ? '${post.capacity} nguoi' : 'Chua cap nhat',
              ),
              _InfoTile(
                icon: Icons.map_outlined,
                label: 'Tinh/Thanh pho',
                value: post.province.trim().isNotEmpty
                    ? post.province.trim()
                    : 'Chua cap nhat',
              ),
              _InfoTile(
                icon: Icons.location_city_outlined,
                label: 'Quan/Huyen',
                value: post.district.trim().isNotEmpty
                    ? post.district.trim()
                    : 'Chua chon',
              ),
              _InfoTile(
                icon: Icons.calendar_today_outlined,
                label: 'Dang luc',
                value: _formatDate(post.createdAt),
              ),
              _InfoTile(
                icon: Icons.update_outlined,
                label: 'Cap nhat',
                value: _formatDate(post.updatedAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesCard() {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tien ich',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: post.amenities
                .where((item) => item.trim().isNotEmpty)
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mo ta chi tiet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            post.description.trim().isNotEmpty
                ? post.description.trim()
                : 'Nguoi dang bai chua bo sung mo ta.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: textSecondary,
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
          const Text(
            'Hinh anh khac',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
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
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    imageUrl,
                    width: 140,
                    height: 108,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 140,
                      height: 108,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported_outlined),
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
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(
            child: Text(
              'Day la bai dang cua ban',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () async {
            final viewModel = context.read<RoommateRequestViewModel>();
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);

            final hasRequested = await viewModel.hasPendingRequest(post.id);

            if (hasRequested) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Ban da gui yeu cau cho bai dang nay roi'),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'Gui yeu cau o ghep',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_outlined,
                    size: 56,
                    color: Colors.grey,
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
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 56,
                          color: Colors.grey,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
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
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox(width: 2),
          Icon(icon, color: PostDetailScreen.primaryBlue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: PostDetailScreen.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: PostDetailScreen.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
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
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: PostDetailScreen.primaryBlue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: PostDetailScreen.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: PostDetailScreen.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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

  const _CircleButton({
    required this.icon,
    this.onTap,
  });

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
          child: Icon(icon, color: Colors.black87, size: 20),
        ),
      ),
    );
  }
}
