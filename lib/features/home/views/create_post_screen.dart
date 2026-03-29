import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';


class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {

  File? _selectedImage;

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _capacityController.dispose();
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




  Future<String> _uploadImageToCloudinary(File imageFile) async {
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
      return data['secure_url'];
    } else {
      throw Exception('Upload Cloudinary thất bại: $responseBody');
    }
  }


  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final location = _locationController.text.trim();

    final price = int.tryParse(_priceController.text.trim());
    final area = int.tryParse(_areaController.text.trim());
    final capacity = int.tryParse(_capacityController.text.trim());

    if (title.isEmpty ||
        location.isEmpty ||
        _selectedImage == null ||
        price == null ||
        area == null ||
        capacity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin và chọn ảnh'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrl = await _uploadImageToCloudinary(_selectedImage!);

      await FirebaseFirestore.instance.collection('posts').add({
        'title': title,
        'location': location,
        'price': price,
        'area': area,
        'capacity': capacity,
        'imageUrl': imageUrl,
        'ownerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng bài thành công')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  // Future<void> _createPost() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return;

  //   final title = _titleController.text.trim();
  //   final location = _locationController.text.trim();
  //   // final imageUrl = _imageUrlController.text.trim();

  //   final price = int.tryParse(_priceController.text.trim());
  //   final area = int.tryParse(_areaController.text.trim());
  //   final capacity = int.tryParse(_capacityController.text.trim());

  //   if (title.isEmpty ||
  //       location.isEmpty ||
  //       _selectedImage == null ||
  //       price == null ||
  //       area == null ||
  //       capacity == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin hợp lệ')),
  //     );
  //     return;
  //   }
  //   setState(() {
  //     _isLoading = true;
  //   });
  //   try {
  //     final imageUrl = await _uploadImageToCloudinary(_selectedImage!);
  //     await FirebaseFirestore.instance.collection('posts').add({
  //       'title': title,
  //       'location': location,
  //       'price': price,
  //       'area': area,
  //       'capacity': capacity,
  //       'imageUrl': imageUrl,
  //       'ownerId': user.uid,
  //       'createdAt': FieldValue.serverTimestamp(),
  //     });
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Đăng bài thành công')),
  //     );

  //     Navigator.pop(context);
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Lỗi: $e')),
  //     );
  //   } 
  //     finally {
  //       if (mounted) {
  //         setState(() {
  //           _isLoading = false;
  //         });
  //       }
  //     }
  // }



  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng bài'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: _inputDecoration('Tiêu đề'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _locationController,
              decoration: _inputDecoration('Địa chỉ'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Giá thuê'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _areaController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Diện tích (m²)'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Số người'),
            ),
            const SizedBox(height: 14),
            // TextField(
            //   // controller: _imageUrlController,
            //   decoration: _inputDecoration('Link ảnh'),
            // ),

             GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
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
            ),


            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B6EF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Đăng bài',
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