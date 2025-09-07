import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Provider for managing user state and gemstone currency
class UserProvider extends ChangeNotifier {
  static const String _logTag = 'UserProvider';

  // User state
  String? _userId;
  int _gemstoneCount = 100; // Default starting gems
  String? _userName;
  String? _userEmail;
  bool _isLoading = false;
  String? _error;

  // Getters
  String? get userId => _userId;
  int get gemstoneCount => _gemstoneCount;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize user data
  Future<void> initializeUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Load user data from Supabase
      // For now, use mock data
      _userId = 'mock_user_id';
      _userName = 'AssetCraft User';
      _userEmail = 'user@assetcraft.ai';

      AppLogger.info(
        'User initialized successfully',
        tag: _logTag,
        data: {
          'userId': _userId,
          'userName': _userName,
          'gemstoneCount': _gemstoneCount,
        },
      );
    } catch (e, stackTrace) {
      _error = 'Failed to initialize user: $e';
      AppLogger.error(
        'Failed to initialize user',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Spend gemstones
  bool spendGemstones(int amount) {
    if (_gemstoneCount >= amount) {
      _gemstoneCount -= amount;
      notifyListeners();
      AppLogger.info(
        'Spent $amount gemstones',
        tag: _logTag,
        data: {'spent': amount, 'remaining': _gemstoneCount},
      );
      return true;
    } else {
      AppLogger.warning(
        'Insufficient gemstones',
        tag: _logTag,
        data: {'requested': amount, 'available': _gemstoneCount},
      );
      return false;
    }
  }

  /// Add gemstones
  void addGemstones(int amount) {
    _gemstoneCount += amount;
    notifyListeners();
    AppLogger.info(
      'Added $amount gemstones',
      tag: _logTag,
      data: {'added': amount, 'total': _gemstoneCount},
    );
  }

  /// Check if user can afford an action
  bool canAfford(int cost) => _gemstoneCount >= cost;

  /// Reset error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
