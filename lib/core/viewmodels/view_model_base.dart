import 'package:flutter/foundation.dart';

/// Base class for all ViewModels providing a unified loading/error state pattern.
///
/// Subclasses call [beginLoad] at the start of an async operation,
/// [setError] in catch blocks, and [setLoading(false)] in finally blocks.
/// Guards on each setter prevent unnecessary [notifyListeners] calls when
/// the value has not actually changed.
abstract class ViewModelBase extends ChangeNotifier {
  bool _isLoading;
  String? _errorMessage;

  ViewModelBase({bool initialLoading = false}) : _isLoading = initialLoading;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Sets [isLoading] and notifies listeners only when the value changes.
  @protected
  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  /// Sets [errorMessage] and notifies listeners only when the value changes.
  @protected
  void setError(String? message) {
    if (_errorMessage == message) return;
    _errorMessage = message;
    notifyListeners();
  }

  /// Convenience: sets loading=true, clears any previous error, notifies once.
  /// Use at the start of every async operation instead of calling [setLoading]
  /// and [setError] separately.
  @protected
  void beginLoad() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clears the current error message. Public so Views can dismiss errors.
  void clearError() => setError(null);
}
