// // import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../../post/presentation/viewmodels/post_list_viewmodel.dart';
// import '../../../post/presentation/views/create_post_screen.dart';
// import '../../../profile/presentation/views/user_profile_screen.dart';
// import '../../../post/data/models/post_model.dart';


// import '../../../post/presentation/views/post_detail_screen.dart';


// class UserHomeScreen extends StatefulWidget {
//   const UserHomeScreen({super.key});

//   @override
//   State<UserHomeScreen> createState() => _UserHomeScreenState();
// }

// class _UserHomeScreenState extends State<UserHomeScreen> {
//   int _selectedIndex = 0;

//   static const Color primaryBlue = Color(0xFF3B6EF5);
//   static const Color bgColor = Color(0xFFF5F7FB);
//   static const Color textPrimary = Color(0xFF111827);
//   static const Color textSecondary = Color(0xFF6B7280);
//   static const Color lightBlue = Color(0xFFEAF2FF);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bgColor,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     _buildHeader(),
//                     const SizedBox(height: 20),
//                     _buildQuickActions(context),
//                     const SizedBox(height: 28),
//                     _buildFeaturedSection(),
//                     const SizedBox(height: 24),
//                   ],
//                 ),
//               ),
//             ),
//             _buildBottomNav(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
//       decoration: const BoxDecoration(
//         color: primaryBlue,
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(32),
//           bottomRight: Radius.circular(32),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Xin chào 👋',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 24,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 6),
//           const Text(
//             'Tìm bạn ở ghép phù hợp',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 24,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 24),
//           Container(
//             height: 64,
//             padding: const EdgeInsets.symmetric(horizontal: 18),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(22),
//             ),
//             child: const Row(
//               children: [
//                 Icon(Icons.search, color: textSecondary, size: 32),
//                 SizedBox(width: 14),
//                 Expanded(
//                   child: Text(
//                     'Tìm phòng hoặc khu vực...',
//                     style: TextStyle(
//                       color: textSecondary,
//                       fontSize: 18,
//                     ),
//                   ),
//                 ),
//                 Icon(Icons.tune, color: textSecondary, size: 30),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickActions(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const _QuickActionItem(icon: Icons.search, label: 'Tìm phòng'),
//           const _QuickActionItem(icon: Icons.access_time, label: 'Gần đây'),
//           const _QuickActionItem(icon: Icons.local_offer_outlined, label: 'Giá tốt'),
//           const _QuickActionItem(icon: Icons.group_outlined, label: 'Ở ghép'),
//           _QuickActionItem(
//             icon: Icons.add,
//             label: 'Đăng bài',
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const CreatePostScreen(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFeaturedSection() {
//     final vm = context.read<PostListViewModel>();

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Phòng trọ nổi bật',
//             style: TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.w800,
//               color: Color(0xFF0F2D6B),
//             ),
//           ),
//           const SizedBox(height: 20),

//           StreamBuilder<List<PostModel>>(
//             stream: vm.postsStream,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(
//                   child: Padding(
//                     padding: EdgeInsets.all(30),
//                     child: CircularProgressIndicator(),
//                   ),
//                 );
//               }

//               if (snapshot.hasError) {
//                 return Center(
//                   child: Text('Lỗi: ${snapshot.error}'),
//                 );
//               }

//               if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                 return Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(24),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Color(0x14000000),
//                         blurRadius: 18,
//                         offset: Offset(0, 8),
//                       ),
//                     ],
//                   ),
//                   child: const Column(
//                     children: [
//                       Icon(
//                         Icons.home_work_outlined,
//                         size: 64,
//                         color: textSecondary,
//                       ),
//                       SizedBox(height: 12),
//                       Text(
//                         'Chưa có bài đăng nào',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                           color: textPrimary,
//                         ),
//                       ),
//                       SizedBox(height: 6),
//                       Text(
//                         'Khi có người đăng bài, bài viết sẽ hiển thị ở đây',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: textSecondary,
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }

//               final posts = snapshot.data!;

//               return ListView.separated(
//                 itemCount: posts.length,
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 separatorBuilder: (context, index) => const SizedBox(height: 18),
//                 itemBuilder: (context, index) {
//                   final post = posts[index];

//                   return _PostCard(
//                     post: post,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => PostDetailScreen(post: post),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           )

//         ],
//       ),
//     );
//   }

//   Widget _buildBottomNav() {
//     final items = const [
//       {'icon': Icons.home_filled, 'label': 'Trang chủ'},
//       {'icon': Icons.description_outlined, 'label': 'Yêu cầu'},
//       {'icon': Icons.favorite_border, 'label': 'Đã lưu'},
//       {'icon': Icons.chat_bubble_outline, 'label': 'Nhắn tin'},
//       {'icon': Icons.person_outline, 'label': 'Cá nhân'},
//     ];

//     return Container(
//       height: 86,
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Color(0x0F000000),
//             blurRadius: 10,
//             offset: Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: List.generate(items.length, (index) {
//           return _BottomNavItem(
//             icon: items[index]['icon'] as IconData,
//             label: items[index]['label'] as String,
//             isActive: _selectedIndex == index,
//             onTap: () {
//               if (index == 4) {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const UserProfileScreen(),
//                   ),
//                 );
//               } else {
//                 setState(() {
//                   _selectedIndex = index;
//                 });
//               }
//             },
//           );
//         }),
//       ),
//     );
//   }
// }

// class _QuickActionItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback? onTap;

//   const _QuickActionItem({
//     required this.icon,
//     required this.label,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           Container(
//             width: 64,
//             height: 64,
//             decoration: const BoxDecoration(
//               color: _UserHomeScreenState.lightBlue,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               icon,
//               color: _UserHomeScreenState.primaryBlue,
//               size: 32,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w500,
//               color: _UserHomeScreenState.textPrimary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PostCard extends StatelessWidget {
//   final PostModel post;
//   final VoidCallback? onTap;

//   const _PostCard({
//     required this.post,
//     this.onTap,
//   });

//   String _formatPrice(int value) {
//     final text = value.toString();
//     final buffer = StringBuffer();
//     int count = 0;

//     for (int i = text.length - 1; i >= 0; i--) {
//       buffer.write(text[i]);
//       count++;
//       if (count == 3 && i != 0) {
//         buffer.write('.');
//         count = 0;
//       }
//     }

//     return buffer.toString().split('').reversed.join();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(28),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x14000000),
//               blurRadius: 18,
//               offset: Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(24),
//                 child: post.imageUrl.isNotEmpty
//                     ? Image.network(
//                         post.imageUrl,
//                         height: 220,
//                         width: double.infinity,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Container(
//                             height: 220,
//                             width: double.infinity,
//                             color: Colors.grey.shade200,
//                             child: const Icon(
//                               Icons.image_not_supported_outlined,
//                               size: 50,
//                               color: Colors.grey,
//                             ),
//                           );
//                         },
//                       )
//                     : Container(
//                         height: 220,
//                         width: double.infinity,
//                         color: Colors.grey.shade200,
//                         child: const Icon(
//                           Icons.image_outlined,
//                           size: 50,
//                           color: Colors.grey,
//                         ),
//                       ),
//               ),
//               const SizedBox(height: 18),
//               Text(
//                 post.title,
//                 style: const TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.w800,
//                   color: _UserHomeScreenState.textPrimary,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   const Icon(
//                     Icons.location_on_outlined,
//                     color: _UserHomeScreenState.textSecondary,
//                     size: 22,
//                   ),
//                   const SizedBox(width: 6),
//                   Expanded(
//                     child: Text(
//                       post.location,
//                       style: const TextStyle(
//                         color: _UserHomeScreenState.textSecondary,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 14),
//               FittedBox(
//                 fit: BoxFit.scaleDown,
//                 alignment: Alignment.centerLeft,
//                 child: RichText(
//                   text: TextSpan(
//                     children: [
//                       TextSpan(
//                         text: '${_formatPrice(post.price)}đ',
//                         style: const TextStyle(
//                           color: _UserHomeScreenState.primaryBlue,
//                           fontSize: 22,
//                           fontWeight: FontWeight.w800,
//                         ),
//                       ),
//                       const TextSpan(
//                         text: ' / tháng',
//                         style: TextStyle(
//                           color: _UserHomeScreenState.textPrimary,
//                           fontSize: 22,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 18),
//               const Divider(height: 1, color: Color(0xFFE5E7EB)),
//               const SizedBox(height: 18),
//               Row(
//                 children: [
//                   const Icon(
//                     Icons.open_in_full,
//                     color: _UserHomeScreenState.textSecondary,
//                     size: 24,
//                   ),
//                   const SizedBox(width: 10),
//                   Text(
//                     '${post.area}m²',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: _UserHomeScreenState.textPrimary,
//                     ),
//                   ),
//                   const SizedBox(width: 34),
//                   const Icon(
//                     Icons.group_outlined,
//                     color: _UserHomeScreenState.textSecondary,
//                     size: 24,
//                   ),
//                   const SizedBox(width: 10),
//                   Text(
//                     '${post.capacity} Người',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: _UserHomeScreenState.textPrimary,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _BottomNavItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool isActive;
//   final VoidCallback onTap;

//   const _BottomNavItem({
//     required this.icon,
//     required this.label,
//     required this.isActive,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color = isActive
//         ? _UserHomeScreenState.primaryBlue
//         : _UserHomeScreenState.textSecondary;

//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: color, size: 30),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               color: color,
//               fontSize: 13,
//               fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../post/presentation/viewmodels/post_list_viewmodel.dart';
import '../../../post/presentation/views/create_post_screen.dart';
import '../../../profile/presentation/views/user_profile_screen.dart';
import '../../../post/data/models/post_model.dart';
import '../../../post/presentation/views/post_detail_screen.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedLocation;
  int? _selectedCapacity;
  int? _maxPrice;

  static const Color primaryBlue = Color(0xFF3B6EF5);
  static const Color bgColor = Color(0xFFF5F7FB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color lightBlue = Color(0xFFEAF2FF);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _selectedLocation != null || _selectedCapacity != null || _maxPrice != null;

  List<PostModel> _applyFilters(List<PostModel> posts) {
    return posts.where((post) {
      final query = _searchQuery.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          post.title.toLowerCase().contains(query) ||
          post.location.toLowerCase().contains(query);

      final matchesLocation = _selectedLocation == null ||
          post.location.toLowerCase().contains(_selectedLocation!.toLowerCase());

      final matchesCapacity =
          _selectedCapacity == null || post.capacity >= _selectedCapacity!;

      final matchesPrice = _maxPrice == null || post.price <= _maxPrice!;

      return matchesSearch &&
          matchesLocation &&
          matchesCapacity &&
          matchesPrice;
    }).toList();
  }

  Future<void> _openFilterSheet(List<PostModel> posts) async {
    final locations = posts
        .map((e) => e.location.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    String? tempLocation = _selectedLocation;
    int? tempCapacity = _selectedCapacity;
    int? tempMaxPrice = _maxPrice;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildChoiceChip({
              required String label,
              required bool selected,
              required VoidCallback onTap,
            }) {
              return GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? primaryBlue : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: SizedBox(
                      width: 48,
                      child: Divider(
                        thickness: 4,
                        color: Color(0xFFD1D5DB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Lọc bài đăng',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Khu vực',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      buildChoiceChip(
                        label: 'Tất cả',
                        selected: tempLocation == null,
                        onTap: () {
                          setModalState(() {
                            tempLocation = null;
                          });
                        },
                      ),
                      ...locations.map(
                        (location) => buildChoiceChip(
                          label: location,
                          selected: tempLocation == location,
                          onTap: () {
                            setModalState(() {
                              tempLocation =
                                  tempLocation == location ? null : location;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),
                  const Text(
                    'Số người',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      buildChoiceChip(
                        label: 'Tất cả',
                        selected: tempCapacity == null,
                        onTap: () {
                          setModalState(() {
                            tempCapacity = null;
                          });
                        },
                      ),
                      ...[1, 2, 3, 4].map(
                        (capacity) => buildChoiceChip(
                          label: 'Từ $capacity người',
                          selected: tempCapacity == capacity,
                          onTap: () {
                            setModalState(() {
                              tempCapacity =
                                  tempCapacity == capacity ? null : capacity;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),
                  const Text(
                    'Giá tối đa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      buildChoiceChip(
                        label: 'Tất cả',
                        selected: tempMaxPrice == null,
                        onTap: () {
                          setModalState(() {
                            tempMaxPrice = null;
                          });
                        },
                      ),
                      ...[1000000, 2000000, 3000000, 5000000].map(
                        (price) => buildChoiceChip(
                          label: '≤ ${_formatMoney(price)}đ',
                          selected: tempMaxPrice == price,
                          onTap: () {
                            setModalState(() {
                              tempMaxPrice =
                                  tempMaxPrice == price ? null : price;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedLocation = null;
                              _selectedCapacity = null;
                              _maxPrice = null;
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryBlue),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Xóa lọc',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedLocation = tempLocation;
                              _selectedCapacity = tempCapacity;
                              _maxPrice = tempMaxPrice;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Áp dụng',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _formatMoney(int value) {
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
            child: Row(
              children: [
                const Icon(Icons.search, color: textSecondary, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Tìm theo tiêu đề hoặc địa điểm...',
                      hintStyle: TextStyle(
                        color: textSecondary,
                        fontSize: 18,
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: const Icon(Icons.close, color: textSecondary, size: 24),
                  ),
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
          Consumer<PostListViewModel>(
            builder: (context, _, __) {
              return StreamBuilder<List<PostModel>>(
                stream: vm.postsStream,
                builder: (context, snapshot) {
                  final posts = snapshot.data ?? [];

                  return Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Phòng trọ nổi bật',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F2D6B),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Lọc bài đăng',
                        onPressed: posts.isEmpty
                            ? null
                            : () => _openFilterSheet(posts),
                        icon: const Icon(
                          Icons.tune,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 10),

          if (_searchQuery.isNotEmpty || _hasActiveFilters)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_searchQuery.isNotEmpty)
                  _FilterChipLabel(
                    label: 'Tìm: $_searchQuery',
                    onRemove: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                if (_selectedLocation != null)
                  _FilterChipLabel(
                    label: 'Khu vực: $_selectedLocation',
                    onRemove: () {
                      setState(() {
                        _selectedLocation = null;
                      });
                    },
                  ),
                if (_selectedCapacity != null)
                  _FilterChipLabel(
                    label: 'Từ $_selectedCapacity người',
                    onRemove: () {
                      setState(() {
                        _selectedCapacity = null;
                      });
                    },
                  ),
                if (_maxPrice != null)
                  _FilterChipLabel(
                    label: '≤ ${_formatMoney(_maxPrice!)}đ',
                    onRemove: () {
                      setState(() {
                        _maxPrice = null;
                      });
                    },
                  ),
              ],
            ),

          const SizedBox(height: 20),

          StreamBuilder<List<PostModel>>(
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

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

              final filteredPosts = _applyFilters(snapshot.data!);

              if (filteredPosts.isEmpty) {
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
                        Icons.search_off,
                        size: 64,
                        color: textSecondary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Không tìm thấy bài đăng phù hợp',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Hãy thử đổi từ khóa tìm kiếm hoặc bộ lọc',
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

              return ListView.separated(
                itemCount: filteredPosts.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final post = filteredPosts[index];

                  return _PostCard(
                    post: post,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // builder: (_) => PostDetailScreen(post: post),
                          builder: (_) => PostDetailScreen(
                            post: post,
                            currentUserId: context.read<AuthViewModel>().user?.uid,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          )
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
  final PostModel post;
  final VoidCallback? onTap;

  const _PostCard({
    required this.post,
    this.onTap,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                child: post.imageUrl.isNotEmpty
                    ? Image.network(
                        post.imageUrl,
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
                post.title,
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
                      post.location,
                      style: const TextStyle(
                        color: _UserHomeScreenState.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${_formatPrice(post.price)}đ',
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
                    '${post.area}m²',
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
                    '${post.capacity} Người',
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

class _FilterChipLabel extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChipLabel({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 8, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: _UserHomeScreenState.lightBlue,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _UserHomeScreenState.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 18,
              color: _UserHomeScreenState.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}