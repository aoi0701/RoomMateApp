import 'package:flutter/foundation.dart';

// Lớp nền cho tất cả ViewModel: cung cấp trạng thái isLoading và errorMessage dùng chung.
// Subclass gọi beginLoad() lúc bắt đầu, setError() trong catch, setLoading(false) trong finally.
abstract class ViewModelBase extends ChangeNotifier {
  bool _isLoading;
  String? _errorMessage;

  ViewModelBase({bool initialLoading = false}) : _isLoading = initialLoading;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cập nhật trạng thái loading, chỉ notify nếu giá trị thực sự thay đổi
  @protected
  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  // Cập nhật thông báo lỗi, chỉ notify nếu nội dung thực sự thay đổi
  @protected
  void setError(String? message) {
    if (_errorMessage == message) return;
    _errorMessage = message;
    notifyListeners();
  }

  // Bắt đầu thao tác async: đặt loading=true và xóa lỗi cũ, chỉ notify 1 lần
  @protected
  void beginLoad() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  // Xóa thông báo lỗi hiện tại — View gọi khi người dùng bấm dismiss
  void clearError() => setError(null);
}
