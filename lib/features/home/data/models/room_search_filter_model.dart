import '../constants/room_filter_data.dart';
import '../../../post/data/models/post_model.dart';

class PriceRangeOption {
  final String id;
  final String label;
  final int? minPrice;
  final int? maxPrice;

  const PriceRangeOption({
    required this.id,
    required this.label,
    this.minPrice,
    this.maxPrice,
  });
}

class RoomSearchFilterModel {
  final String keyword;
  final String province;
  final String district;
  final String roomType;
  final String priceRangeId;
  final List<String> amenities;

  const RoomSearchFilterModel({
    this.keyword = '',
    this.province = '',
    this.district = '',
    this.roomType = '',
    this.priceRangeId = '',
    this.amenities = const [],
  });

  static const List<PriceRangeOption> priceRanges = [
    PriceRangeOption(id: 'lte_2', label: '<= 2 triệu', maxPrice: 2000000),
    PriceRangeOption(
      id: '2_3',
      label: '2 - 3 triệu',
      minPrice: 2000000,
      maxPrice: 3000000,
    ),
    PriceRangeOption(
      id: '3_4',
      label: '3 - 4 triệu',
      minPrice: 3000000,
      maxPrice: 4000000,
    ),
    PriceRangeOption(
      id: '4_5',
      label: '4 - 5 triệu',
      minPrice: 4000000,
      maxPrice: 5000000,
    ),
    PriceRangeOption(
      id: '5_6',
      label: '5 - 6 triệu',
      minPrice: 5000000,
      maxPrice: 6000000,
    ),
    PriceRangeOption(
      id: '6_8',
      label: '6 - 8 triệu',
      minPrice: 6000000,
      maxPrice: 8000000,
    ),
    PriceRangeOption(
      id: '8_10',
      label: '8 - 10 triệu',
      minPrice: 8000000,
      maxPrice: 10000000,
    ),
    PriceRangeOption(
      id: '10_12',
      label: '10 - 12 triệu',
      minPrice: 10000000,
      maxPrice: 12000000,
    ),
    PriceRangeOption(id: 'gt_12', label: '> 12 triệu', minPrice: 12000000),
  ];

  static const List<String> roomTypes = RoomFilterData.roomTypes;
  static const List<String> amenitiesCatalog = RoomFilterData.amenities;
  static const Map<String, List<String>> districtsByProvince =
      RoomFilterData.districtsByProvince;
  static const List<String> provinces = RoomFilterData.provinces;

  PriceRangeOption? get selectedPriceRange {
    if (priceRangeId.isEmpty) return null;
    final results = priceRanges.where((item) => item.id == priceRangeId);
    return results.isEmpty ? null : results.first;
  }

  bool get hasActiveFilters =>
      keyword.isNotEmpty ||
      province.isNotEmpty ||
      district.isNotEmpty ||
      roomType.isNotEmpty ||
      priceRangeId.isNotEmpty ||
      amenities.isNotEmpty;

  String get summaryText {
    if (!hasActiveFilters) {
      return 'Mở bộ lọc để tìm phòng phù hợp';
    }

    final parts = <String>[];
    if (keyword.isNotEmpty) parts.add(keyword);
    if (province.isNotEmpty) parts.add(province);
    if (district.isNotEmpty) parts.add(district);
    if (roomType.isNotEmpty) parts.add(roomType);
    if (selectedPriceRange != null) parts.add(selectedPriceRange!.label);
    if (amenities.isNotEmpty) parts.add('${amenities.length} tiện ích');

    return parts.join(' • ');
  }

  RoomSearchFilterModel copyWith({
    String? keyword,
    String? province,
    String? district,
    String? roomType,
    String? priceRangeId,
    List<String>? amenities,
  }) {
    return RoomSearchFilterModel(
      keyword: keyword ?? this.keyword,
      province: province ?? this.province,
      district: district ?? this.district,
      roomType: roomType ?? this.roomType,
      priceRangeId: priceRangeId ?? this.priceRangeId,
      amenities: amenities ?? this.amenities,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'keyword': keyword,
      'province': province,
      'district': district,
      'roomType': roomType,
      'priceRangeId': priceRangeId,
      'amenities': amenities,
    };
  }

  factory RoomSearchFilterModel.fromMap(Map<String, dynamic>? map) {
    final data = map ?? {};
    return RoomSearchFilterModel(
      keyword: data['keyword'] ?? '',
      province: data['province'] ?? '',
      district: data['district'] ?? '',
      roomType: data['roomType'] ?? '',
      priceRangeId: data['priceRangeId'] ?? '',
      amenities: List<String>.from(data['amenities'] ?? const []),
    );
  }

  bool matchesPost(PostModel post) {
    final normalizedKeyword = keyword.trim().toLowerCase();
    final postTitle = post.title.trim().toLowerCase();
    final postLocation = post.location.trim().toLowerCase();
    final normalizedProvince = post.province.trim().toLowerCase();
    final normalizedDistrict = post.district.trim().toLowerCase();
    final normalizedRoomType = post.roomType.trim().toLowerCase();
    final postAmenities =
        post.amenities.map((item) => item.trim().toLowerCase()).toSet();

    final matchesKeyword = normalizedKeyword.isEmpty
        ? true
        : postTitle.contains(normalizedKeyword) ||
            postLocation.contains(normalizedKeyword) ||
            normalizedDistrict.contains(normalizedKeyword) ||
            normalizedProvince.contains(normalizedKeyword);

    final matchesProvince = province.isEmpty
        ? true
        : normalizedProvince.isNotEmpty &&
            normalizedProvince == province.trim().toLowerCase();
    final matchesDistrict = district.isEmpty
        ? true
        : normalizedDistrict.isNotEmpty &&
            normalizedDistrict == district.trim().toLowerCase();
    final matchesRoomType = roomType.isEmpty
        ? true
        : normalizedRoomType.isNotEmpty &&
            normalizedRoomType == roomType.trim().toLowerCase();

    final range = selectedPriceRange;
    final matchesPrice = range == null
        ? true
        : (range.minPrice == null || post.price >= range.minPrice!) &&
            (range.maxPrice == null || post.price <= range.maxPrice!);

    final matchesAmenities = amenities.isEmpty ||
        (postAmenities.isNotEmpty &&
            amenities.every(
              (item) => postAmenities.contains(item.trim().toLowerCase()),
            ));

    return matchesKeyword &&
        matchesProvince &&
        matchesDistrict &&
        matchesRoomType &&
        matchesPrice &&
        matchesAmenities;
  }
}
