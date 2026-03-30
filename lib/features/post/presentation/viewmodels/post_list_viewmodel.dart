// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/post_repository.dart';
import '../../data/models/post_model.dart';

class PostListViewModel extends ChangeNotifier {
  final PostRepository _repository;

  PostListViewModel({PostRepository? repository})
      : _repository = repository ?? PostRepository();

  Stream<List<PostModel>> get postsStream {
    return _repository.getPostsStream();
  }
}