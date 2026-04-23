import 'package:flutter/material.dart';

import '../../data/models/room_search_filter_model.dart';
import '../../data/repositories/home_search_filter_repository.dart';

class HomeSearchFilterViewModel extends ChangeNotifier {
  final HomeSearchFilterRepository _repository;

  HomeSearchFilterViewModel({HomeSearchFilterRepository? repository})
      : _repository = repository ?? HomeSearchFilterRepository();

  RoomSearchFilterModel _currentFilter = const RoomSearchFilterModel();
  bool isLoading = false;
  bool isSaving = false;
  bool _hasLoaded = false;
  String? errorMessage;

  RoomSearchFilterModel get currentFilter => _currentFilter;
  bool get hasLoaded => _hasLoaded;

  Future<void> loadSavedFilter() async {
    if (_hasLoaded) return;
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      _currentFilter = await _repository.getSavedFilter();
      _hasLoaded = true;
    } catch (e) {
      errorMessage = 'Không tải được bộ lọc: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveFilter(RoomSearchFilterModel filter) async {
    try {
      isSaving = true;
      errorMessage = null;
      notifyListeners();

      await _repository.saveFilter(filter);
      _currentFilter = filter;
      return true;
    } catch (e) {
      errorMessage = 'Không lưu được bộ lọc: $e';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void updateFilterLocally(RoomSearchFilterModel filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  Future<void> resetFilter({bool clearSaved = false}) async {
    _currentFilter = const RoomSearchFilterModel();
    _hasLoaded = true;
    errorMessage = null;
    notifyListeners();

    if (!clearSaved) return;

    try {
      await _repository.clearSavedFilter();
    } catch (e) {
      errorMessage = 'Không thể xóa bộ lọc đã lưu: $e';
      notifyListeners();
    }
  }
}
