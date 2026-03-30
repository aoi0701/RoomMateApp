import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/post_list_viewmodel.dart';
import 'create_post_screen.dart';
import 'user_profile_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;

  static const Color primaryBlue = Color(0xFF3B6EF5);
  static const Color bgColor = Color(0xFFF5F7FB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color lightBlue = Color(0xFFEAF2FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildQuickActions(context),
                    const SizedBox(height: 28),
                    _buildFeaturedSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      decoration: const BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xin chào 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tìm bạn ở ghép phù hợp',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: textSecondary, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Tìm phòng hoặc khu vực...',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 18,
                    ),
                  ),
                ),
                Icon(Icons.tune, color: textSecondary, size: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _QuickActionItem(icon: Icons.search, label: 'Tìm phòng'),
          const _QuickActionItem(icon: Icons.access_time, label: 'Gần đây'),
          const _QuickActionItem(icon: Icons.local_offer_outlined, label: 'Giá tốt'),
          const _QuickActionItem(icon: Icons.group_outlined, label: 'Ở ghép'),
          _QuickActionItem(
            icon: Icons.add,
            label: 'Đăng bài',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreatePostScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    final vm = context.read<PostListViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phòng trọ nổi bật',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F2D6B),
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: vm.postsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Lỗi: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.home_work_outlined,
                        size: 64,
                        color: textSecondary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Chưa có bài đăng nào',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Khi có người đăng bài, bài viết sẽ hiển thị ở đây',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.separated(
                itemCount: docs.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final post = docs[index].data();

                  final title = post['title'] ?? '';
                  final location = post['location'] ?? '';
                  final price = post['price'] ?? 0;
                  final area = post['area'] ?? 0;
                  final capacity = post['capacity'] ?? 0;
                  final imageUrl = post['imageUrl'] ?? '';

                  return _PostCard(
                    title: title,
                    location: location,
                    price: price,
                    area: area,
                    capacity: capacity,
                    imageUrl: imageUrl,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = const [
      {'icon': Icons.home_filled, 'label': 'Trang chủ'},
      {'icon': Icons.description_outlined, 'label': 'Yêu cầu'},
      {'icon': Icons.favorite_border, 'label': 'Đã lưu'},
      {'icon': Icons.chat_bubble_outline, 'label': 'Nhắn tin'},
      {'icon': Icons.person_outline, 'label': 'Cá nhân'},
    ];

    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          return _BottomNavItem(
            icon: items[index]['icon'] as IconData,
            label: items[index]['label'] as String,
            isActive: _selectedIndex == index,
            onTap: () {
              if (index == 4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserProfileScreen(),
                  ),
                );
              } else {
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
          );
        }),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: _UserHomeScreenState.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: _UserHomeScreenState.primaryBlue,
              size: 32,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _UserHomeScreenState.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String title;
  final String location;
  final int price;
  final int area;
  final int capacity;
  final String imageUrl;

  const _PostCard({
    required this.title,
    required this.location,
    required this.price,
    required this.area,
    required this.capacity,
    required this.imageUrl,
  });

  String _formatPrice(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    int count = 0;

    for (int i = text.length - 1; i >= 0; i--) {
      buffer.write(text[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }

    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 220,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 220,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image_outlined,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _UserHomeScreenState.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: _UserHomeScreenState.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      color: _UserHomeScreenState.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${_formatPrice(price)}đ',
                    style: const TextStyle(
                      color: _UserHomeScreenState.primaryBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(
                    text: ' / tháng',
                    style: TextStyle(
                      color: _UserHomeScreenState.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(
                  Icons.open_in_full,
                  color: _UserHomeScreenState.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  '${area}m²',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _UserHomeScreenState.textPrimary,
                  ),
                ),
                const SizedBox(width: 34),
                const Icon(
                  Icons.group_outlined,
                  color: _UserHomeScreenState.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  '$capacity Người',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _UserHomeScreenState.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? _UserHomeScreenState.primaryBlue
        : _UserHomeScreenState.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}