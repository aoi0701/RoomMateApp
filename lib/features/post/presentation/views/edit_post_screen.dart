import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../home/data/constants/room_filter_data.dart';
import '../../../profile/data/models/profile_habit_model.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/viewmodels/user_profile_viewmodel.dart';
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
  static const Color primaryBlue = Color(0xFF3B6EF5);
  static const Color bgColor = Color(0xFFF6F8FC);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  final List<File> _selectedImages = [];
  late List<String> _existingImageUrls;

  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _priceController;
  late final TextEditingController _areaController;
  late final TextEditingController _capacityController;
  late final TextEditingController _descriptionController;

  late String _selectedProvince;
  late String _selectedDistrict;
  late String _selectedRoomType;
  late List<String> _selectedAmenities;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _locationController = TextEditingController(text: widget.post.location);
    _priceController = TextEditingController(text: widget.post.price.toString());
    _areaController = TextEditingController(text: widget.post.area.toString());
    _capacityController =
        TextEditingController(text: widget.post.capacity.toString());
    _descriptionController =
        TextEditingController(text: widget.post.description);

    _selectedProvince = widget.post.province;
    _selectedDistrict = widget.post.district;
    _selectedRoomType = widget.post.roomType;
    _selectedAmenities = [...widget.post.amenities];
    _existingImageUrls = [...widget.post.imageUrls];
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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isEmpty) return;

    final limitedFiles = pickedFiles.take(5).toList();

    setState(() {
      _selectedImages
        ..clear()
        ..addAll(limitedFiles.map((file) => File(file.path)));
    });

    if (!mounted || pickedFiles.length <= 5) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chi luu toi da 5 anh cho moi bai dang.'),
      ),
    );
  }

  Future<void> _handleUpdatePost() async {
    FocusScope.of(context).unfocus();

    final vm = context.read<PostViewModel>();
    final success = await vm.updatePost(
      postId: widget.post.id,
      title: _titleController.text,
      location: _locationController.text,
      province: _selectedProvince,
      district: _selectedDistrict,
      roomType: _selectedRoomType,
      amenities: _selectedAmenities,
      priceText: _priceController.text,
      areaText: _areaController.text,
      capacityText: _capacityController.text,
      descriptionText: _descriptionController.text,
      imageFiles: _selectedImages.isEmpty ? null : _selectedImages,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Cap nhat bai dang thanh cong'
              : (vm.errorMessage ?? 'Cap nhat bai dang that bai'),
        ),
      ),
    );

    if (success) {
      Navigator.pop(context);
    }
  }

  InputDecoration _inputDecoration(String label, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD5DBE7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD5DBE7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryBlue),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    String? hint,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      isExpanded: true,
      decoration: _inputDecoration(label),
      hint: Text(
        hint ?? label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      selectedItemBuilder: (context) {
        return options
            .map(
              (item) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            )
            .toList();
      },
      items: options
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildAmenitiesSection(bool isLoading) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: RoomFilterData.amenities.map((item) {
        final selected = _selectedAmenities.contains(item);
        return FilterChip(
          selected: selected,
          onSelected: isLoading
              ? null
              : (value) {
                  setState(() {
                    if (value) {
                      _selectedAmenities.add(item);
                    } else {
                      _selectedAmenities.remove(item);
                    }
                  });
                },
          selectedColor: const Color(0xFFDCE8FF),
          checkmarkColor: primaryBlue,
          label: Text(
            item,
            style: TextStyle(
              color: selected ? primaryBlue : textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFFF4F6FA),
          side: BorderSide(
            color: selected ? primaryBlue : const Color(0xFFD8DEE9),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHabitsSection(String? uid) {
    if (uid == null) {
      return const Text(
        'Chua co thong tin ho so de hien thi thoi quen sinh hoat.',
        style: TextStyle(color: textSecondary),
      );
    }

    final profileVm = context.read<UserProfileViewModel>();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profileVm.getUserProfileStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text(
            'Chua co du lieu ho so.',
            style: TextStyle(color: textSecondary),
          );
        }

        final user = UserModel.fromDocument(snapshot.data!);
        final selectedHabits = user.habits
            .map(ProfileHabitCatalog.findById)
            .whereType<ProfileHabitModel>()
            .toList();

        if (selectedHabits.isEmpty) {
          return const Text(
            'Ban chua cap nhat thoi quen trong ho so.',
            style: TextStyle(color: textSecondary),
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: selectedHabits
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: item.backgroundColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 18,
                        color: item.foregroundColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildImagePicker(PostViewModel vm) {
    final displayLocalImages = _selectedImages.isNotEmpty;
    final totalImages = displayLocalImages ? _selectedImages.length : _existingImageUrls.length;
    final itemCount = totalImages == 0 ? 1 : totalImages;
    final rows = itemCount <= 3 ? 1 : 2;
    final gridHeight = rows == 1 ? 122.0 : 252.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: gridHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              if (totalImages == 0) {
                return GestureDetector(
                  onTap: vm.isLoading ? null : _pickImages,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD8DEE9)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 38, color: textSecondary),
                        SizedBox(height: 8),
                        Text(
                          'Them anh',
                          style: TextStyle(
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (displayLocalImages) {
                final imageFile = _selectedImages[index];
                return Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(imageFile, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: vm.isLoading
                            ? null
                            : () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              final imageUrl = _existingImageUrls[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFF7F8FB),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                displayLocalImages
                    ? 'Dang dung ${_selectedImages.length}/5 anh moi'
                    : 'Dang hien ${_existingImageUrls.length}/5 anh',
                style: const TextStyle(fontSize: 13, color: textSecondary),
              ),
            ),
            TextButton(
              onPressed: vm.isLoading ? null : _pickImages,
              child: Text(displayLocalImages ? 'Chon lai anh' : 'Thay anh'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PostViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final uid = authVm.user?.uid;
    final districts =
        RoomFilterData.districtsByProvince[_selectedProvince] ?? const <String>[];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Chinh sua bai dang'),
        centerTitle: true,
        backgroundColor: bgColor,
        surfaceTintColor: bgColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              _buildSection(
                title: '1. Thong tin co ban',
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      enabled: !vm.isLoading,
                      decoration: _inputDecoration('Tieu de bai dang'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _locationController,
                      enabled: !vm.isLoading,
                      decoration: _inputDecoration('Dia chi chi tiet'),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 380;
                        if (compact) {
                          return Column(
                            children: [
                              _buildDropdownField(
                                label: 'Tinh/Thanh pho',
                                value: _selectedProvince,
                                hint: 'Chon khu vuc',
                                options: RoomFilterData.provinces,
                                onChanged: vm.isLoading
                                    ? (_) {}
                                    : (value) {
                                        setState(() {
                                          _selectedProvince = value ?? '';
                                          _selectedDistrict = '';
                                        });
                                      },
                              ),
                              const SizedBox(height: 14),
                              _buildDropdownField(
                                label: 'Quan/Huyen',
                                value: _selectedDistrict,
                                hint: 'Chon quan/huyen',
                                options: districts,
                                onChanged: vm.isLoading
                                    ? (_) {}
                                    : (value) {
                                        setState(() {
                                          _selectedDistrict = value ?? '';
                                        });
                                      },
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Tinh/Thanh pho',
                                value: _selectedProvince,
                                hint: 'Chon khu vuc',
                                options: RoomFilterData.provinces,
                                onChanged: vm.isLoading
                                    ? (_) {}
                                    : (value) {
                                        setState(() {
                                          _selectedProvince = value ?? '';
                                          _selectedDistrict = '';
                                        });
                                      },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Quan/Huyen',
                                value: _selectedDistrict,
                                hint: 'Chon quan/huyen',
                                options: districts,
                                onChanged: vm.isLoading
                                    ? (_) {}
                                    : (value) {
                                        setState(() {
                                          _selectedDistrict = value ?? '';
                                        });
                                      },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildDropdownField(
                      label: 'Loai phong',
                      value: _selectedRoomType,
                      hint: 'Chon loai phong',
                      options: RoomFilterData.roomTypes,
                      onChanged: vm.isLoading
                          ? (_) {}
                          : (value) {
                              setState(() {
                                _selectedRoomType = value ?? '';
                              });
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildSection(
                title: '2. Thong tin phong o ghep',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _capacityController,
                            enabled: !vm.isLoading,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('So nguoi'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _areaController,
                            enabled: !vm.isLoading,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Dien tich (m²)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _priceController,
                      enabled: !vm.isLoading,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Tien thue / thang'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildSection(
                title: '3. Thoi quen sinh hoat',
                child: _buildHabitsSection(uid),
              ),
              const SizedBox(height: 18),
              _buildSection(
                title: '4. Tien ich khac',
                child: _buildAmenitiesSection(vm.isLoading),
              ),
              const SizedBox(height: 18),
              _buildSection(
                title: '5. Mo ta chi tiet',
                child: TextField(
                  controller: _descriptionController,
                  enabled: !vm.isLoading,
                  minLines: 5,
                  maxLines: 7,
                  decoration: _inputDecoration('Mo ta'),
                ),
              ),
              const SizedBox(height: 18),
              _buildSection(
                title: '6. Hinh anh',
                child: _buildImagePicker(vm),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          vm.isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD5DBE7)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Huy',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: vm.isLoading ? null : _handleUpdatePost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: vm.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Luu thay doi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
