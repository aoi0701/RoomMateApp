import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/post_model.dart';
import '../../../home/data/models/room_search_filter_model.dart';

class PostsPageResult {
  final List<PostModel> posts;

  /// Cursor for the next page. `null` when this is the last page.
  final DocumentSnapshot<Map<String, dynamic>>? nextCursor;

  const PostsPageResult({required this.posts, this.nextCursor});

  bool get hasMore => nextCursor != null;
}

class PostRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  PostRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  User? get currentUser => _auth.currentUser;

  // Upload ảnh lên Cloudinary qua unsigned preset, trả về URL ảnh đã lưu
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

  // Tạo bài đăng mới: upload tối đa 5 ảnh lên Cloudinary rồi lưu metadata vào Firestore
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

  // Cập nhật bài đăng: xác minh quyền sở hữu, upload ảnh mới nếu có, cập nhật Firestore
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

  // Xóa bài đăng + tất cả roommate_requests liên quan trong 1 batch (cascade delete)
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
        .where('postOwnerId', isEqualTo: user.uid)
        .get();

    final batch = _firestore.batch();

    for (final requestDoc in relatedRequests.docs) {
      batch.delete(requestDoc.reference);
    }

    batch.delete(postDocRef);

    await batch.commit();
  }

  static const int pageSize = 25;

  // Xây dựng Firestore query theo bộ lọc (tỉnh, quận, loại phòng, giá, tiện ích)
  Query<Map<String, dynamic>> _buildFilteredQuery(RoomSearchFilterModel filter) {
    Query<Map<String, dynamic>> query = _firestore.collection('posts');

    if (filter.province.isNotEmpty) {
      query = query.where('province', isEqualTo: filter.province.trim());
    }
    if (filter.district.isNotEmpty) {
      query = query.where('district', isEqualTo: filter.district.trim());
    }
    if (filter.roomType.isNotEmpty) {
      query = query.where('roomType', isEqualTo: filter.roomType.trim());
    }
    // arrayContains only supports one value; multi-amenity is handled in-memory by the ViewModel.
    if (filter.amenities.length == 1) {
      query = query.where('amenities', arrayContains: filter.amenities.first.trim());
    }

    final range = filter.selectedPriceRange;
    if (range != null) {
      final minPrice = range.minPrice;
      final maxPrice = range.maxPrice;
      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }
      // Firestore requires orderBy on the range-filtered field before any other orderBy.
      query = query.orderBy('price');
    }

    return query.orderBy('createdAt', descending: true);
  }

  /// First-page live stream.  Emits whenever any of the matching posts change.
  /// Carries the last [DocumentSnapshot] so the ViewModel can use it as a
  /// cursor without making an extra Firestore round-trip.
  Stream<PostsPageResult> getPostsPageStream(RoomSearchFilterModel filter) {
    return _buildFilteredQuery(filter).limit(pageSize).snapshots().map((snapshot) {
      final posts = snapshot.docs.map(PostModel.fromDocument).toList();
      final nextCursor =
          snapshot.docs.length >= pageSize ? snapshot.docs.last : null;
      return PostsPageResult(posts: posts, nextCursor: nextCursor);
    });
  }

  /// Fetches the next page after [lastDoc].  One-shot, not a live stream.
  Future<PostsPageResult> loadMorePosts(
    DocumentSnapshot<Map<String, dynamic>> lastDoc,
    RoomSearchFilterModel filter,
  ) async {
    final snapshot = await _buildFilteredQuery(filter)
        .startAfterDocument(lastDoc)
        .limit(pageSize)
        .get();
    final posts = snapshot.docs.map(PostModel.fromDocument).toList();
    final nextCursor =
        snapshot.docs.length >= pageSize ? snapshot.docs.last : null;
    return PostsPageResult(posts: posts, nextCursor: nextCursor);
  }

  // Lấy tập ID của user bị xóa/block để ViewModel lọc ẩn bài đăng của họ khỏi feed
  Future<Set<String>> fetchHiddenOwnerIds() async {
    final results = await Future.wait([
      _firestore.collection('users').where('deleted', isEqualTo: true).get(),
      _firestore.collection('users').where('isBlocked', isEqualTo: true).get(),
    ]);
    return {
      for (final snap in results)
        for (final doc in snap.docs) doc.id,
    };
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
