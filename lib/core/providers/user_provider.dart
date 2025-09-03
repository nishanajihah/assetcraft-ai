import 'package:flutter/foundation.dart';
import '../database/database_service.dart';
import '../database/models/user_model.dart';
import '../utils/app_logger.dart';

/// Global user state provider
class UserProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  /// Initialize user provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _currentUser = _databaseService.getCurrentUser();
      AppLogger.info(
        '👤 User provider initialized: ${_currentUser?.email ?? 'No user'}',
      );
    } catch (e, stackTrace) {
      _setError('Failed to initialize user: $e');
      AppLogger.error('❌ Failed to initialize user provider', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Set current user
  Future<void> setUser(UserModel user) async {
    try {
      await _databaseService.saveUser(user);
      _currentUser = user;
      _clearError();
      notifyListeners();
      AppLogger.info('👤 User set: ${user.email}');
    } catch (e, stackTrace) {
      _setError('Failed to save user: $e');
      AppLogger.error('❌ Failed to set user', e, stackTrace);
    }
  }

  /// Update user information
  Future<void> updateUser(UserModel updatedUser) async {
    try {
      await _databaseService.saveUser(updatedUser);
      _currentUser = updatedUser;
      _clearError();
      notifyListeners();
      AppLogger.info('👤 User updated: ${updatedUser.email}');
    } catch (e, stackTrace) {
      _setError('Failed to update user: $e');
      AppLogger.error('❌ Failed to update user', e, stackTrace);
    }
  }

  /// Update user gemstones count
  Future<void> updateGemstones(int newCount) async {
    if (_currentUser == null) return;

    try {
      final updatedUser = _currentUser!.copyWith(
        gemstonesCount: newCount,
        updatedAt: DateTime.now(),
      );
      await updateUser(updatedUser);
      AppLogger.info('💎 Gemstones updated: $newCount');
    } catch (e, stackTrace) {
      _setError('Failed to update gemstones: $e');
      AppLogger.error('❌ Failed to update gemstones', e, stackTrace);
    }
  }

  /// Spend gemstones
  Future<bool> spendGemstones(int amount) async {
    if (_currentUser == null || _currentUser!.gemstonesCount < amount) {
      _setError('Not enough gemstones');
      return false;
    }

    try {
      final newCount = _currentUser!.gemstonesCount - amount;
      await updateGemstones(newCount);
      AppLogger.info('💎 Spent $amount gemstones, remaining: $newCount');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to spend gemstones: $e');
      AppLogger.error('❌ Failed to spend gemstones', e, stackTrace);
      return false;
    }
  }

  /// Add gemstones
  Future<void> addGemstones(int amount) async {
    if (_currentUser == null) return;

    try {
      final newCount = _currentUser!.gemstonesCount + amount;
      await updateGemstones(newCount);
      AppLogger.info('💎 Added $amount gemstones, total: $newCount');
    } catch (e, stackTrace) {
      _setError('Failed to add gemstones: $e');
      AppLogger.error('❌ Failed to add gemstones', e, stackTrace);
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      if (_currentUser != null) {
        await _databaseService.deleteUser(_currentUser!.id);
      }
      _currentUser = null;
      _clearError();
      notifyListeners();
      AppLogger.info('👤 User signed out');
    } catch (e, stackTrace) {
      _setError('Failed to sign out: $e');
      AppLogger.error('❌ Failed to sign out', e, stackTrace);
    }
  }

  /// Clear all user data
  Future<void> clearUserData() async {
    try {
      await _databaseService.clearAllData();
      _currentUser = null;
      _clearError();
      notifyListeners();
      AppLogger.info('🗑️ All user data cleared');
    } catch (e, stackTrace) {
      _setError('Failed to clear user data: $e');
      AppLogger.error('❌ Failed to clear user data', e, stackTrace);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
