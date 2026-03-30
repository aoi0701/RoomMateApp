import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/post_repository.dart';

class PostListViewModel extends ChangeNotifier {
  final PostRepository _repository;

  PostListViewModel({PostRepository? repository})
      : _repository = repository ?? PostRepository();

  Stream<QuerySnapshot<Map<String, dynamic>>> get postsStream {
    return _repository.getPostsStream();
  }
}