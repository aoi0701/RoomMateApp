import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/repositories/post_repository.dart';

class PostViewModel extends ChangeNotifier {
  final PostRepository _repository;

  PostViewModel({PostRepository? repository})
      : _repository = repository ?? PostRepository();

  bool isLoading = false;
  String? errorMessage;

  Future<bool> createPost({
    required String title,
    required String location,
    required String priceText,
    required String areaText,
    required String capacityText,
    required String descriptionText,
    required File? imageFile,
  }) async {
    final price = int.tryParse(priceText.trim());
    final area = int.tryParse(areaText.trim());
    final capacity = int.tryParse(capacityText.trim());

    if (title.trim().isEmpty ||
        location.trim().isEmpty ||
        descriptionText.trim().isEmpty ||
        imageFile == null ||
        price == null || price <= 0 ||
        area == null || area <= 0 ||
        capacity == null || capacity <= 0) {
      errorMessage = 'Vui lòng nhập đầy đủ thông tin hợp lệ';
      notifyListeners();
      return false;
    }

    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _repository.createPost(
        title: title,
        location: location,
        price: price,
        area: area,
        capacity: capacity,
        description: descriptionText,
        imageFile: imageFile,
      );

      return true;
    } catch (e) {
      errorMessage = 'Đăng bài thất bại: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePost({
    required String postId,
    required String title,
    required String location,
    required String priceText,
    required String areaText,
    required String capacityText,
    required String descriptionText,
    File? imageFile,
  }) async {
    final price = int.tryParse(priceText.trim());
    final area = int.tryParse(areaText.trim());
    final capacity = int.tryParse(capacityText.trim());

    if (title.trim().isEmpty ||
        location.trim().isEmpty ||
        descriptionText.trim().isEmpty ||
        price == null || price <= 0 ||
        area == null || area <= 0 ||
        capacity == null || capacity <= 0) {
      errorMessage = 'Vui lòng nhập đầy đủ thông tin hợp lệ';
      notifyListeners();
      return false;
    }

    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _repository.updatePost(
        postId: postId,
        title: title,
        location: location,
        price: price,
        area: area,
        capacity: capacity,
        description: descriptionText,
        imageFile: imageFile,
      );

      return true;
    } catch (e) {
      errorMessage = 'Cập nhật thất bại: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _repository.deletePost(postId);
      return true;
    } catch (e) {
      errorMessage = 'Xóa thất bại: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}