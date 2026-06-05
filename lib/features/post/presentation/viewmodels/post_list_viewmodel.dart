import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/viewmodels/view_model_base.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';
import '../../../home/data/models/room_search_filter_model.dart';

class PostListViewModel extends ViewModelBase {
  final PostRepository _repository;

  StreamSubscription<PostsPageResult>? _firstPageSub;
  RoomSearchFilterModel _activeFilter = const RoomSearchFilterModel();

  List<PostModel> _posts = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastCursor;
  Set<String> _hiddenOwnerIds = {};

  bool _isLoadingMore = false;
  bool _hasMore = false;

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  // Lọc thêm in-memory: từ khóa và nhiều amenity (AND-logic) sau khi Firestore đã lọc
  // province/district/roomType/price. Ẩn bài của owner bị xóa/block.
  List<PostModel> get filteredPosts {
    final kw = _activeFilter.keyword.trim().toLowerCase();
    final amenities = _activeFilter.amenities;

    return _posts.where((post) {
      if (post.status == 'hidden') return false;
      if (_hiddenOwnerIds.contains(post.ownerId)) return false;
      if (kw.isNotEmpty) {
        final found = post.title.toLowerCase().contains(kw) ||
            post.location.toLowerCase().contains(kw) ||
            post.district.toLowerCase().contains(kw) ||
            post.province.toLowerCase().contains(kw);
        if (!found) return false;
      }
      if (amenities.length > 1) {
        final postAmenities =
            post.amenities.map((a) => a.trim().toLowerCase()).toSet();
        if (!amenities.every(
            (a) => postAmenities.contains(a.trim().toLowerCase()))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  PostListViewModel({required PostRepository repository})
      : _repository = repository,
        super(initialLoading: true) {
    _loadHiddenOwnerIds();
    _subscribeFirstPage();
  }

  Future<void> _loadHiddenOwnerIds() async {
    _hiddenOwnerIds = await _repository.fetchHiddenOwnerIds();
    notifyListeners();
  }

  // Áp dụng bộ lọc mới: hủy stream cũ, reset pagination, subscribe lại với query mới
  void applyFilter(RoomSearchFilterModel filter) {
    _activeFilter = filter;
    _firstPageSub?.cancel();
    _posts = [];
    _lastCursor = null;
    _hasMore = false;
    setLoading(true);
    _loadHiddenOwnerIds();
    _subscribeFirstPage();
  }

  void _subscribeFirstPage() {
    _firstPageSub = _repository.getPostsPageStream(_activeFilter).listen(
      (result) {
        // Merge trang đầu với các trang đã load thêm: thay thế docs trang đầu,
        // giữ nguyên các docs trang sau (dedup theo id để tránh trùng tại ranh giới)
        final firstIds = result.posts.map((p) => p.id).toSet();
        final extras = _posts.where((p) => !firstIds.contains(p.id)).toList();
        _posts = [...result.posts, ...extras];

        // Chỉ cập nhật cursor khi chưa có trang thêm — sau loadMore() cursor đã
        // trỏ tới trang mới nhất, không được ghi đè bởi stream trang đầu
        if (extras.isEmpty) {
          _lastCursor = result.nextCursor;
          _hasMore = result.hasMore;
        }

        setError(null);    // clears any previous error (no-op if already null)
        setLoading(false); // notifies: all data above is included in this rebuild
      },
      onError: (Object error) {
        setLoading(false);
        setError(error.toString());
      },
    );
  }

  Future<void> loadMore() async {
    final cursor = _lastCursor;
    if (_isLoadingMore || !_hasMore || cursor == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repository.loadMorePosts(cursor, _activeFilter);
      _posts = [..._posts, ...result.posts];
      _lastCursor = result.nextCursor;
      _hasMore = result.hasMore;
      setError(null); // clear any previous error
    } catch (e) {
      setError(e.toString());
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Stream bài đăng của riêng user — dùng cho màn hình "bài đăng của tôi"
  Stream<List<PostModel>> getPostsByUser(String uid) =>
      _repository.getPostsByUser(uid);

  @override
  void dispose() {
    _firstPageSub?.cancel();
    super.dispose();
  }
}
