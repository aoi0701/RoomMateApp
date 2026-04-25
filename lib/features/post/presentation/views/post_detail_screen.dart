import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    if (value == null) return 'Ch\u01B0a c\u1EADp nh\u1EADt';
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
    if (parts.isEmpty) return 'Ch\u01B0a c\u1EADp nh\u1EADt \u0111\u1ECBa ch\u1EC9';
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
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final owner = snapshot.hasData && snapshot.data!.exists
              ? UserModel.fromDocument(snapshot.data!)
              : null;

          final ownerName = owner?.fullName.trim().isNotEmpty == true
              ? owner!.fullName
              : 'Ng\u01B0\u1EDDi \u0111\u0103ng b\u00E0i';
          final subtitleParts = <String>[
            if (owner?.gender.trim().isNotEmpty == true) owner!.gender.trim(),
            if (owner?.address.trim().isNotEmpty == true) owner!.address.trim(),
          ];
          final ownerSubtitle = owner == null
              ? 'Ch\u01B0a c\u00F3 th\u00F4ng tin h\u1ED3 s\u01A1'
              : subtitleParts.isEmpty
                  ? 'Th\u00E0nh vi\u00EAn RoomMate'
                  : subtitleParts.join(' - ');
          final ownerContact = owner == null
              ? 'Kh\u00F4ng c\u00F3 th\u00F4ng tin li\u00EAn h\u1EC7'
              : owner.phone.trim().isNotEmpty
                  ? owner.phone.trim()
                  : owner.email.trim().isNotEmpty
                      ? owner.email.trim()
                      : 'Ch\u01B0a c\u1EADp nh\u1EADt li\u00EAn h\u1EC7';

          return Row(
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
                : 'B\u00E0i \u0111\u0103ng t\u00ECm b\u1EA1n \u1EDF gh\u00E9p',
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
                  label: 'Gi\u00E1',
                  value: post.price > 0
                      ? '${_formatMoney(post.price)}d/thang'
                      : 'Th\u1ECFa thu\u1EADn',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TopMetric(
                  icon: Icons.king_bed_outlined,
                  label: 'Lo\u1EA1i ph\u00F2ng',
                  value: post.roomType.trim().isNotEmpty
                      ? post.roomType.trim()
                      : 'Ch\u01B0a c\u1EADp nh\u1EADt',
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
            'Th\u00F4ng tin chi ti\u1EBFt',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
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
                    label: 'Di\u1EC7n t\u00EDch',
                    value: post.area > 0
                        ? '${post.area} m2'
                        : 'Ch\u01B0a c\u1EADp nh\u1EADt',
                  ),
                  _InfoTile(
                    icon: Icons.group_outlined,
                    label: 'S\u1EE9c ch\u1EE9a',
                    value: post.capacity > 0
                        ? '${post.capacity} ng\u01B0\u1EDDi'
                        : 'Ch\u01B0a c\u1EADp nh\u1EADt',
                  ),
                  _InfoTile(
                    icon: Icons.map_outlined,
                    label: 'T\u1EC9nh/Th\u00E0nh ph\u1ED1',
                    value: post.province.trim().isNotEmpty
                        ? post.province.trim()
                        : 'Ch\u01B0a c\u1EADp nh\u1EADt',
                  ),
                  _InfoTile(
                    icon: Icons.location_city_outlined,
                    label: 'Qu\u1EADn/Huy\u1EC7n',
                    value: post.district.trim().isNotEmpty
                        ? post.district.trim()
                        : 'Ch\u01B0a ch\u1ECDn',
                  ),
                  _InfoTile(
                    icon: Icons.calendar_today_outlined,
                    label: '\u0110\u0103ng l\u00FAc',
                    value: _formatDate(post.createdAt),
                  ),
                  _InfoTile(
                    icon: Icons.update_outlined,
                    label: 'C\u1EADp nh\u1EADt',
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
          const Text(
            'Ti\u1EC7n \u00EDch',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
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
                  const Text(
                    'Th\u00F3i quen sinh ho\u1EA1t',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
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
          const Text(
            'M\u00F4 t\u1EA3 chi ti\u1EBFt',
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
                : 'Ng\u01B0\u1EDDi \u0111\u0103ng b\u00E0i ch\u01B0a b\u1ED5 sung m\u00F4 t\u1EA3.',
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
            'H\u00ECnh \u1EA3nh kh\u00E1c',
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
      return const SizedBox.shrink();
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
                  content: Text(
                    'B\u1EA1n \u0111\u00E3 g\u1EEDi y\u00EAu c\u1EA7u cho b\u00E0i \u0111\u0103ng n\u00E0y r\u1ED3i',
                  ),
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
            'G\u1EEDi y\u00EAu c\u1EA7u \u1EDF gh\u00E9p',
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: PostDetailScreen.primaryBlue, size: 22),
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: PostDetailScreen.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: PostDetailScreen.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
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
          Expanded(
            child: _AmenityBox(label: visibleAmenities[i]),
          ),
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
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8CADFF)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 19, color: PostDetailScreen.primaryBlue),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6D86B5),
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
