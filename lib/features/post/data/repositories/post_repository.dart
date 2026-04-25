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

    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['secure_url'] as String;
    }

    throw Exception('Upload Cloudinary thất bại: $responseBody');
  }

  Future<void> createPost({
    required String title,
    required String location,
    required String province,
    required String district,
    required String roomType,
    required List<String> amenities,
    required List<String> lifestyleHabits,
    required int price,
    required int area,
    required int capacity,
    required String description,
    required List<File> imageFiles,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    final selectedImages = imageFiles.take(5).toList();
    final imageUrls = <String>[];
    for (final imageFile in selectedImages) {
      imageUrls.add(await uploadImageToCloudinary(imageFile));
    }

    await _firestore.collection('posts').add({
      'title': title.trim(),
      'location': location.trim(),
      'province': province.trim(),
      'district': district.trim(),
      'roomType': roomType.trim(),
      'amenities': amenities.toSet().toList(),
      'lifestyleHabits': lifestyleHabits.toSet().toList(),
      'price': price,
      'area': area,
      'capacity': capacity,
      'description': description.trim(),
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : '',
      'imageUrls': imageUrls,
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePost({
    required String postId,
    required String title,
    required String location,
    required String province,
    required String district,
    required String roomType,
    required List<String> amenities,
    required List<String> lifestyleHabits,
    required int price,
    required int area,
    required int capacity,
    required String description,
    List<File>? imageFiles,
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

    var imageUrl = data['imageUrl'] as String? ?? '';
    var imageUrls = List<String>.from(data['imageUrls'] ?? const []);
    if (imageUrls.isEmpty && imageUrl.trim().isNotEmpty) {
      imageUrls = [imageUrl];
    }

    final selectedImages = (imageFiles ?? const <File>[]).take(5).toList();
    if (selectedImages.isNotEmpty) {
      imageUrls = <String>[];
      for (final imageFile in selectedImages) {
        imageUrls.add(await uploadImageToCloudinary(imageFile));
      }
      imageUrl = imageUrls.first;
    }

    await _firestore.collection('posts').doc(postId).update({
      'title': title.trim(),
      'location': location.trim(),
      'province': province.trim(),
      'district': district.trim(),
      'roomType': roomType.trim(),
      'amenities': amenities.toSet().toList(),
      'lifestyleHabits': lifestyleHabits.toSet().toList(),
      'price': price,
      'area': area,
      'capacity': capacity,
      'description': description.trim(),
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    final postDocRef = _firestore.collection('posts').doc(postId);
    final doc = await postDocRef.get();

    if (!doc.exists) {
      throw Exception('Bài không tồn tại');
    }

    final data = doc.data()!;
    if (data['ownerId'] != user.uid) {
      throw Exception('Không có quyền xóa');
    }

    final relatedRequests = await _firestore
        .collection('roommate_requests')
        .where('postId', isEqualTo: postId)
        .get();

    final batch = _firestore.batch();

    for (final requestDoc in relatedRequests.docs) {
      batch.delete(requestDoc.reference);
    }

    batch.delete(postDocRef);

    await batch.commit();
  }

  Stream<List<PostModel>> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(PostModel.fromDocument).toList();
    });
  }

  Stream<List<PostModel>> getPostsByUser(String uid) {
    return _firestore
        .collection('posts')
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(PostModel.fromDocument).toList();
    });
  }
}
