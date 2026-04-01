// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import 'package:roommateapp/features/auth/presentation/viewmodels/auth_viewmodel.dart';
// import 'package:roommateapp/features/post/data/models/post_model.dart';
// import 'package:roommateapp/features/post/presentation/viewmodels/post_list_viewmodel.dart';
// import 'package:roommateapp/features/post/presentation/viewmodels/post_viewmodel.dart';
// import 'package:roommateapp/features/post/presentation/views/post_detail_screen.dart';
// import 'package:roommateapp/features/post/presentation/views/edit_post_screen.dart';


// class MyPostsScreen extends StatelessWidget {
//   const MyPostsScreen({super.key});

//   Future<void> _showPostActions(
//     BuildContext context,
//     PostModel post,
//   ) async {
//     final action = await showModalBottomSheet<String>(
//       context: context,
//       builder: (_) {
//         return SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.edit_outlined),
//                 title: const Text('Sửa bài đăng'),
//                 onTap: () {
//                   Navigator.pop(context, 'edit');
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.delete_outline, color: Colors.red),
//                 title: const Text(
//                   'Xóa bài đăng',
//                   style: TextStyle(color: Colors.red),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context, 'delete');
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );

//     if (!context.mounted || action == null) return;

//     if (action == 'edit') {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => EditPostScreen(post: post),
//         ),
//       );
//     }

//     if (action == 'delete') {
//       final confirmed = await showDialog<bool>(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text('Xác nhận xóa'),
//           content: const Text('Bạn có chắc muốn xóa bài đăng này không?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Hủy'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text(
//                 'Xóa',
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           ],
//         ),
//       );

//       if (confirmed != true || !context.mounted) return;

//       final vm = context.read<PostViewModel>();
//       final success = await vm.deletePost(post.id);

//       if (!context.mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             success
//                 ? 'Xóa bài đăng thành công'
//                 : (vm.errorMessage ?? 'Xóa bài đăng thất bại'),
//           ),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authVm = context.read<AuthViewModel>();
//     final postVm = context.read<PostListViewModel>();

//     final user = authVm.user;

//     if (user == null) {
//       return const Scaffold(
//         body: Center(
//           child: Text(
//             'Chưa đăng nhập',
//             style: TextStyle(fontSize: 16),
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bài đăng của tôi'),
//         centerTitle: true,
//       ),
//       body: StreamBuilder<List<PostModel>>(
//         stream: postVm.getPostsByUser(user.uid),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(
//               child: Text('Có lỗi xảy ra: ${snapshot.error}'),
//             );
//           }

//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(
//               child: Text(
//                 'Bạn chưa có bài đăng nào',
//                 style: TextStyle(fontSize: 16),
//               ),
//             );
//           }

//           final posts = snapshot.data!;

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: posts.length,
//             itemBuilder: (context, index) {
//               final post = posts[index];

//               return Container(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withValues(alpha: 0.05),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(12),
//                   leading: ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: Image.network(
//                       post.imageUrl,
//                       width: 60,
//                       height: 60,
//                       fit: BoxFit.cover,
//                       errorBuilder: (_, _, _) =>
//                           const Icon(Icons.image_not_supported),
//                     ),
//                   ),
//                   title: Text(
//                     post.title,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(
//                     post.location,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   trailing: SizedBox(
//                     width: 80,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           '${post.price}đ',
//                           style: const TextStyle(
//                             color: Colors.red,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.more_vert),
//                           onPressed: () => _showPostActions(context, post),
//                           padding: EdgeInsets.zero,
//                           constraints: const BoxConstraints(),
//                         ),
//                       ],
//                     ),
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => PostDetailScreen(post: post),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roommateapp/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:roommateapp/features/post/data/models/post_model.dart';
import 'package:roommateapp/features/post/presentation/viewmodels/post_list_viewmodel.dart';
import 'package:roommateapp/features/post/presentation/viewmodels/post_viewmodel.dart';
import 'package:roommateapp/features/post/presentation/views/post_detail_screen.dart';
import 'package:roommateapp/features/post/presentation/views/edit_post_screen.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  Future<void> _showPostActions(
    BuildContext context,
    PostModel post,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Sửa bài đăng'),
                onTap: () {
                  Navigator.pop(context, 'edit');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Xóa bài đăng',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context, 'delete');
                },
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) return;

    if (action == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditPostScreen(post: post),
        ),
      );
    }

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc muốn xóa bài đăng này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Xóa',
                style: TextStyle(color: Colors.red),
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
      return const Scaffold(
        body: Center(
          child: Text(
            'Chưa đăng nhập',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài đăng của tôi'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: postVm.getPostsByUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Có lỗi xảy ra: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa có bài đăng nào',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final posts = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(post: post),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              post.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  post.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
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
                                '${post.price}đ',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _showPostActions(context, post),
                                borderRadius: BorderRadius.circular(20),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.more_vert, size: 20),
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