import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String title;
  final String location;
  final int price;
  final int area;
  final int capacity;
  final String imageUrl;
  final String ownerId;
  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.area,
    required this.capacity,
    required this.imageUrl,
    required this.ownerId,
    this.createdAt,
  });

  /// 🔹 from Firestore Document
  factory PostModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return PostModel(
      id: doc.id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      price: data['price'] ?? 0,
      area: data['area'] ?? 0,
      capacity: data['capacity'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      ownerId: data['ownerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// 🔹 from Map (dùng khi cần)
  factory PostModel.fromMap(Map<String, dynamic> map, String id) {
    return PostModel(
      id: id,
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      price: map['price'] ?? 0,
      area: map['area'] ?? 0,
      capacity: map['capacity'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      ownerId: map['ownerId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// 🔹 to Map (ghi lên Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'price': price,
      'area': area,
      'capacity': capacity,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// 🔹 copyWith (update object)
  PostModel copyWith({
    String? id,
    String? title,
    String? location,
    int? price,
    int? area,
    int? capacity,
    String? imageUrl,
    String? ownerId,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      price: price ?? this.price,
      area: area ?? this.area,
      capacity: capacity ?? this.capacity,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}