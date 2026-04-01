import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/post_model.dart';
import '../viewmodels/post_viewmodel.dart';

class EditPostScreen extends StatefulWidget {
  final PostModel post;

  const EditPostScreen({
    super.key,
    required this.post,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  File? _selectedImage;

  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _priceController;
  late final TextEditingController _areaController;
  late final TextEditingController _capacityController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.post.title);
    _locationController = TextEditingController(text: widget.post.location);
    _priceController =
        TextEditingController(text: widget.post.price.toString());
    _areaController = TextEditingController(text: widget.post.area.toString());
    _capacityController =
        TextEditingController(text: widget.post.capacity.toString());
    _descriptionController =
        TextEditingController(text: widget.post.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleUpdatePost() async {
    FocusScope.of(context).unfocus();

    final vm = context.read<PostViewModel>();

    final success = await vm.updatePost(
      postId: widget.post.id,
      title: _titleController.text,
      location: _locationController.text,
      priceText: _priceController.text,
      areaText: _areaController.text,
      capacityText: _capacityController.text,
      descriptionText: _descriptionController.text,
      imageFile: _selectedImage,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật bài đăng thành công')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Cập nhật bài đăng thất bại'),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }

  Widget _buildImagePicker(PostViewModel vm) {
    final hasNewImage = _selectedImage != null;
    final hasOldImage = widget.post.imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: vm.isLoading ? null : _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: hasNewImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : hasOldImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.post.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Chạm để chọn ảnh từ thiết bị',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PostViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa bài đăng'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              enabled: !vm.isLoading,
              decoration: _inputDecoration('Tiêu đề'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _locationController,
              enabled: !vm.isLoading,
              decoration: _inputDecoration('Địa chỉ'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _priceController,
              enabled: !vm.isLoading,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Giá thuê'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _areaController,
              enabled: !vm.isLoading,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Diện tích (m²)'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _capacityController,
              enabled: !vm.isLoading,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Số người'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              enabled: !vm.isLoading,
              maxLines: 5,
              decoration: _inputDecoration('Mô tả chi tiết'),
            ),
            const SizedBox(height: 14),
            _buildImagePicker(vm),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: vm.isLoading ? null : _handleUpdatePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B6EF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: vm.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Lưu thay đổi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}