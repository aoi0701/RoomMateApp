import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../home/data/constants/room_filter_data.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/viewmodels/user_profile_viewmodel.dart';
import '../../data/models/post_model.dart';
import '../widgets/amenity_grid.dart';
import '../widgets/lifestyle_habit_wrap.dart';
import '../viewmodels/post_viewmodel.dart';

class PostFormScreen extends StatefulWidget {
  /// null → create new post; non-null → edit existing post.
  final PostModel? post;

  const PostFormScreen({super.key, this.post});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
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

  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    if (post != null) {
      _titleController = TextEditingController(text: post.title);
      _locationController = TextEditingController(text: post.location);
      _priceController = TextEditingController(text: post.price.toString());
      _areaController = TextEditingController(text: post.area.toString());
      _capacityController = TextEditingController(text: post.capacity.toString());
      _descriptionController = TextEditingController(text: post.description);
      _selectedProvince = post.province;
      _selectedDistrict = post.district;
      _selectedRoomType = post.roomType;
      _selectedAmenities = [...post.amenities];
      _existingImageUrls = [...post.imageUrls];
    } else {
      _titleController = TextEditingController();
      _locationController = TextEditingController();
      _priceController = TextEditingController();
      _areaController = TextEditingController();
      _capacityController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedProvince = '';
      _selectedDistrict = '';
      _selectedRoomType = '';
      _selectedAmenities = [];
      _existingImageUrls = [];
    }
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

    if (_isEditing) {
      // Edit mode: replace all images with a new selection (up to 5).
      final pickedFiles = await picker.pickMultiImage(imageQuality: 80);
      if (pickedFiles.isEmpty) return;
      final limitedFiles = pickedFiles.take(5).toList();
      setState(() {
        _selectedImages
          ..clear()
          ..addAll(limitedFiles.map((f) => File(f.path)));
      });
      if (!mounted || pickedFiles.length <= 5) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ lưu tối đa 5 ảnh cho mỗi bài đăng.')),
      );
    } else {
      // Create mode: accumulate images up to the 5-slot limit.
      final remainingSlots = 5 - _selectedImages.length;
      if (remainingSlots <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn chỉ có thể thêm tối đa 5 ảnh.')),
        );
        return;
      }
      final pickedFiles = await picker.pickMultiImage(imageQuality: 80);
      if (pickedFiles.isEmpty) return;
      final limitedFiles = pickedFiles.take(remainingSlots).toList();
      setState(() {
        _selectedImages.addAll(limitedFiles.map((f) => File(f.path)));
      });
      if (!mounted || pickedFiles.length <= remainingSlots) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ lưu tối đa 5 ảnh cho mỗi bài đăng.')),
      );
    }
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    final vm = context.read<PostViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final lifestyleHabits = await _loadLifestyleHabitIds(
      context.read<AuthViewModel>().user?.uid,
    );

    final bool success;
    if (_isEditing) {
      success = await vm.updatePost(
        postId: widget.post!.id,
        title: _titleController.text,
        location: _locationController.text,
        province: _selectedProvince,
        district: _selectedDistrict,
        roomType: _selectedRoomType,
        amenities: _selectedAmenities,
        lifestyleHabits: lifestyleHabits,
        priceText: _priceController.text,
        areaText: _areaController.text,
        capacityText: _capacityController.text,
        descriptionText: _descriptionController.text,
        imageFiles: _selectedImages.isEmpty ? null : _selectedImages,
      );
    } else {
      success = await vm.createPost(
        title: _titleController.text,
        location: _locationController.text,
        province: _selectedProvince,
        district: _selectedDistrict,
        roomType: _selectedRoomType,
        amenities: _selectedAmenities,
        lifestyleHabits: lifestyleHabits,
        priceText: _priceController.text,
        areaText: _areaController.text,
        capacityText: _capacityController.text,
        descriptionText: _descriptionController.text,
        imageFiles: _selectedImages,
      );
    }

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (_isEditing ? 'Cập nhật bài đăng thành công' : 'Đăng bài thành công')
              : (vm.errorMessage ??
                  (_isEditing ? 'Cập nhật bài đăng thất bại' : 'Đăng bài thất bại')),
        ),
      ),
    );

    if (success) navigator.pop();
  }

  Future<List<String>> _loadLifestyleHabitIds(String? uid) async {
    final fallback = _isEditing ? widget.post!.lifestyleHabits : const <String>[];
    if (uid == null) return fallback;

    final profileVm = context.read<UserProfileViewModel>();
    final user = await profileVm.getUserProfile(uid);
    final habitIds = user?.habits
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    if (habitIds == null || habitIds.isEmpty) return fallback;
    return habitIds;
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
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
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
              color: AppColors.textPrimary,
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
    final normalizedOptions = options
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final selectedValue = normalizedOptions.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      isExpanded: true,
      decoration: _inputDecoration(label),
      hint: Text(hint ?? label, overflow: TextOverflow.ellipsis, maxLines: 1),
      selectedItemBuilder: (context) => normalizedOptions
          .map(
            (item) => Align(
              alignment: Alignment.centerLeft,
              child: Text(item, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          )
          .toList(),
      items: normalizedOptions
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildAmenitiesSection(bool isLoading) {
    return AmenityGrid(
      amenities: RoomFilterData.amenities,
      selectedAmenities: _selectedAmenities.toSet(),
      enabled: !isLoading,
      onToggle: (item) {
        setState(() {
          if (_selectedAmenities.contains(item)) {
            _selectedAmenities.remove(item);
          } else {
            _selectedAmenities.add(item);
          }
        });
      },
    );
  }

  Widget _buildHabitsSection(String? uid) {
    if (uid == null) {
      return const Text(
        'Chưa có thông tin hồ sơ để hiển thị thói quen sinh hoạt.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: context.read<UserProfileViewModel>().getUserProfileStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final doc = snapshot.data;
        if (doc == null || !doc.exists) {
          return const Text(
            'Chưa có dữ liệu hồ sơ.',
            style: TextStyle(color: AppColors.textSecondary),
          );
        }

        final user = UserModel.fromDocument(doc);
        final selectedHabits = user.habits
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);

        if (selectedHabits.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Bạn chưa cập nhật thói quen trong hồ sơ. Hãy vào trang hồ sơ để bổ sung, mục này sẽ tự động đồng bộ sang màn đăng bài.',
              style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
            ),
          );
        }

        return LifestyleHabitWrap(habitIds: selectedHabits);
      },
    );
  }

  Widget _buildImagePicker(PostViewModel vm) {
    if (_isEditing) {
      final displayLocalImages = _selectedImages.isNotEmpty;
      final totalImages =
          displayLocalImages ? _selectedImages.length : _existingImageUrls.length;
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
                  return _AddImagePlaceholder(onTap: vm.isLoading ? null : _pickImages);
                }
                if (displayLocalImages) {
                  return _LocalImageTile(
                    file: _selectedImages[index],
                    onRemove: vm.isLoading
                        ? null
                        : () => setState(() => _selectedImages.removeAt(index)),
                  );
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    _existingImageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFF7F8FB),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textSecondary,
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
                      ? 'Đang dùng ${_selectedImages.length}/5 ảnh mới'
                      : 'Đang hiện ${_existingImageUrls.length}/5 ảnh',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: vm.isLoading ? null : _pickImages,
                child: Text(displayLocalImages ? 'Chọn lại ảnh' : 'Thay ảnh'),
              ),
            ],
          ),
        ],
      );
    }

    // Create mode: accumulate images with an "add" slot.
    const maxImages = 5;
    final itemCount =
        _selectedImages.length < maxImages ? _selectedImages.length + 1 : maxImages;
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
              if (index == _selectedImages.length &&
                  _selectedImages.length < maxImages) {
                return _AddImagePlaceholder(onTap: vm.isLoading ? null : _pickImages);
              }
              return _LocalImageTile(
                file: _selectedImages[index],
                onRemove: vm.isLoading
                    ? null
                    : () => setState(() => _selectedImages.removeAt(index)),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tối đa 5 ảnh (${_selectedImages.length}/5)',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PostViewModel>();
    final uid = context.watch<AuthViewModel>().user?.uid;
    final districts =
        RoomFilterData.districtsByProvince[_selectedProvince] ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa bài đăng' : 'Đăng tin Tìm bạn ở ghép'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              _buildSection(
                title: '1. Thông tin cơ bản',
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      enabled: !vm.isLoading,
                      decoration: _inputDecoration('Tiêu đề bài đăng'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _locationController,
                      enabled: !vm.isLoading,
                      decoration: _inputDecoration('Địa chỉ chi tiết'),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 380;
                        final provinceField = _buildDropdownField(
                          label: 'Tỉnh/Thành phố',
                          value: _selectedProvince,
                          hint: 'Chọn khu vực',
                          options: RoomFilterData.provinces,
                          onChanged: vm.isLoading
                              ? (_) {}
                              : (value) {
                                  setState(() {
                                    _selectedProvince = value ?? '';
                                    _selectedDistrict = '';
                                  });
                                },
                        );
                        final districtField = _buildDropdownField(
                          label: 'Quận/Huyện',
                          value: _selectedDistrict,
                          hint: 'Chọn quận/huyện',
                          options: districts,
                          onChanged: vm.isLoading
                              ? (_) {}
                              : (value) {
                                  setState(() => _selectedDistrict = value ?? '');
                                },
                        );
                        if (compact) {
                          return Column(
                            children: [
                              provinceField,
                              const SizedBox(height: 14),
                              districtField,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: provinceField),
                            const SizedBox(width: 12),
                            Expanded(child: districtField),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildDropdownField(
                      label: 'Loại phòng',
                      value: _selectedRoomType,
                      hint: 'Chọn loại phòng',
                      options: RoomFilterData.roomTypes,
                      onChanged: vm.isLoading
                          ? (_) {}
                          : (value) {
                              setState(() => _selectedRoomType = value ?? '');
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildSection(
                title: '2. Thông tin phòng ở ghép',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _capacityController,
                            enabled: !vm.isLoading,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Số người'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _areaController,
                            enabled: !vm.isLoading,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Diện tích (m²)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _priceController,
                      enabled: !vm.isLoading,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Tiền thuê / tháng'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildSection(
                title: '3. Thói quen sinh hoạt',
                child: _buildHabitsSection(uid),
              ),
              const SizedBox(height: 18),
              _buildSection(
                title: '4. Tiện ích khác',
                child: _buildAmenitiesSection(vm.isLoading),
              ),
              const SizedBox(height: 18),
              _buildSection(
                title: '5. Mô tả chi tiết',
                child: TextField(
                  controller: _descriptionController,
                  enabled: !vm.isLoading,
                  minLines: 5,
                  maxLines: 7,
                  decoration: _inputDecoration(
                    'Mô tả',
                    hintText:
                        'Viết chi tiết về căn phòng, tiện ích và mong muốn của bạn...',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildSection(
                title: '6. Hình ảnh',
                child: _buildImagePicker(vm),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: _isEditing ? 'Hủy' : 'Quay lại',
                      onTap: vm.isLoading ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppPrimaryButton(
                      label: _isEditing ? 'Lưu thay đổi' : 'Đăng bài',
                      isLoading: vm.isLoading,
                      onTap: vm.isLoading ? null : _handleSubmit,
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

class _AddImagePlaceholder extends StatelessWidget {
  final VoidCallback? onTap;
  const _AddImagePlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD8DEE9)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 38, color: AppColors.textSecondary),
            SizedBox(height: 8),
            Text(
              'Thêm ảnh',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalImageTile extends StatelessWidget {
  final File file;
  final VoidCallback? onRemove;
  const _LocalImageTile({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
