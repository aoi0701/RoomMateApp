import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/views/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Chưa đăng nhập'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          // loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // error
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          // no data
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không có dữ liệu user'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final fullName = data['fullName'] ?? 'User';
          final email = data['email'] ?? user.email ?? '';

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Bạn đã đăng nhập thành công',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // 👇 NEW
                  Text(
                    'Xin chào, $fullName 👋',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Email: $email',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      if (!context.mounted) return;

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}