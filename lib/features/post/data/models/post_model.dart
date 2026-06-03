import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String title;
  final String location;
  final String province;
  final String district;
  final String roomType;
  final List<String> amenities;
  final List<String> lifestyleHabits;
  final int price;
  final int area;
  final int capacity;
  final String description;
  final String imageUrl;
  final List<String> imageUrls;
  final String ownerId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PostModel({
    required this.id,
    required this.title,
    required this.location,
    required this.province,
    required this.district,
    required this.roomType,
    required this.amenities,
    required this.lifestyleHabits,
    required this.price,
    required this.area,
    required this.capacity,
    required this.description,
    required this.imageUrl,
    required this.imageUrls,
    required this.ownerId,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory PostModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawAmenities = data['amenities'];
    final rawImageUrls = data['imageUrls'];

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    List<String> parseStringList(dynamic value) {
      if (value is Iterable) {
        return value
            .where((item) => item != null)
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList();
      }
      return const [];
    }

    List<String> parseImageUrls(dynamic value, String fallback) {
      if (value is Iterable) {
        final urls = value
            .where((item) => item != null)
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList();
        if (urls.isNotEmpty) return urls;
      }
      if (fallback.trim().isNotEmpty) return [fallback];
      return const [];
    }

    final fallbackImageUrl = data['imageUrl'] ?? '';

    return PostModel(
      id: doc.id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      province: data['province'] ?? '',
      district: data['district'] ?? '',
      roomType: data['roomType'] ?? '',
      amenities: parseStringList(rawAmenities),
      lifestyleHabits: parseStringList(data['lifestyleHabits']),
      price: parseInt(data['price']),
      area: parseInt(data['area']),
      capacity: parseInt(data['capacity']),
      description: data['description'] ?? '',
      imageUrl: fallbackImageUrl,
      imageUrls: parseImageUrls(rawImageUrls, fallbackImageUrl),
      ownerId: data['ownerId'] ?? '',
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'province': province,
      'district': district,
      'roomType': roomType,
      'amenities': amenities,
      'lifestyleHabits': lifestyleHabits,
      'price': price,
      'area': area,
      'capacity': capacity,
      'description': description,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'ownerId': ownerId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  PostModel copyWith({
    String? id,
    String? title,
    String? location,
    String? province,
    String? district,
    String? roomType,
    List<String>? amenities,
    List<String>? lifestyleHabits,
    int? price,
    int? area,
    int? capacity,
    String? description,
    String? imageUrl,
    List<String>? imageUrls,
    String? ownerId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      province: province ?? this.province,
      district: district ?? this.district,
      roomType: roomType ?? this.roomType,
      amenities: amenities ?? this.amenities,
      lifestyleHabits: lifestyleHabits ?? this.lifestyleHabits,
      price: price ?? this.price,
      area: area ?? this.area,
      capacity: capacity ?? this.capacity,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
