import 'dart:io';

import 'package:flutter/material.dart';

import '../repositories/post_repository.dart';

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
    required File? imageFile,
  }) async {
    final price = int.tryParse(priceText.trim());
    final area = int.tryParse(areaText.trim());
    final capacity = int.tryParse(capacityText.trim());

    if (title.trim().isEmpty ||
        location.trim().isEmpty ||
        imageFile == null ||
        price == null ||
        area == null ||
        capacity == null) {
      errorMessage = 'Vui lòng nhập đầy đủ thông tin hợp lệ và chọn ảnh';
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
}