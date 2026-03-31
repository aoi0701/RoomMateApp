import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roommateapp/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:roommateapp/features/post/presentation/viewmodels/post_list_viewmodel.dart';
import 'package:roommateapp/features/post/data/models/post_model.dart';
import 'package:roommateapp/features/post/presentation/views/post_detail_screen.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.read<AuthViewModel>();
    final postVm = context.read<PostListViewModel>();

    final user = authVm.user;
    // print('UID hiện tại: ${user?.uid}');

    // 🔒 Chưa đăng nhập
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
          // ⏳ Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ Không có dữ liệu
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa có bài đăng nào',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final posts = snapshot.data!;

          // 📋 Danh sách bài
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
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),

                  // 🖼️ Ảnh
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      post.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  ),

                  // 📝 Title + location
                  title: Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    post.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 💰 Giá
                  trailing: Text(
                    '${post.price}đ',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // 👉 Click vào chi tiết
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(post: post),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}