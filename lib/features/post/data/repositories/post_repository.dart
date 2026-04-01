import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

class PostRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  PostRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<String> uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'dg9nhcbfu';
    const uploadPreset = 'sib1xtoq';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['secure_url'] as String;
    } else {
      throw Exception('Upload Cloudinary thất bại: $responseBody');
    }
  }

  Future<void> createPost({
    required String title,
    required String location,
    required int price,
    required int area,
    required int capacity,
    required String description,
    required File imageFile,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    final imageUrl = await uploadImageToCloudinary(imageFile);

    await _firestore.collection('posts').add({
      'title': title.trim(),
      'location': location.trim(),
      'price': price,
      'area': area,
      'capacity': capacity,
      'description': description.trim(),
      'imageUrl': imageUrl,
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePost({
    required String postId,
    required String title,
    required String location,
    required int price,
    required int area,
    required int capacity,
    required String description,
    File? imageFile,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final doc = await _firestore.collection('posts').doc(postId).get();

    if (!doc.exists) {
      throw Exception('Bài không tồn tại');
    }

    final data = doc.data()!;
    if (data['ownerId'] != user.uid) {
      throw Exception('Không có quyền sửa');
    }

    String imageUrl = data['imageUrl'];

    if (imageFile != null) {
      imageUrl = await uploadImageToCloudinary(imageFile);
    }

    await _firestore.collection('posts').doc(postId).update({
      'title': title.trim(),
      'location': location.trim(),
      'price': price,
      'area': area,
      'capacity': capacity,
      'description': description.trim(),
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final doc = await _firestore.collection('posts').doc(postId).get();

    if (!doc.exists) {
      throw Exception('Bài không tồn tại');
    }

    final data = doc.data()!;
    if (data['ownerId'] != user.uid) {
      throw Exception('Không có quyền xóa');
    }

    await _firestore.collection('posts').doc(postId).delete();
  }



  Stream<List<PostModel>> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromDocument(doc))
              .toList();
        });
  }

  Stream<List<PostModel>> getPostsByUser(String uid) {
  return _firestore
      .collection('posts')
      .where('ownerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => PostModel.fromDocument(doc))
            .toList();
      });
}
}