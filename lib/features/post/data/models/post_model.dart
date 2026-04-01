import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String title;
  final String location;
  final int price;
  final int area;
  final int capacity;
  final String description;
  final String imageUrl;
  final String ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PostModel({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.area,
    required this.capacity,
    required this.description,
    required this.imageUrl,
    required this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

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
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      ownerId: data['ownerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'price': price,
      'area': area,
      'capacity': capacity,
      'description': description,
      'imageUrl': imageUrl,
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
    int? price,
    int? area,
    int? capacity,
    String? description,
    String? imageUrl,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      price: price ?? this.price,
      area: area ?? this.area,
      capacity: capacity ?? this.capacity,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}