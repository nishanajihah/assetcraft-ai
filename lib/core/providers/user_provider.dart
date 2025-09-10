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
  String? _userPhotoURL;
  bool _isLoading = false;
  String? _error;
  bool _isPremium = false;
  DateTime? _subscriptionEndDate;
  int _totalGenerations = 25;
  int _monthlyGenerations = 15;
  int _weeklyGenerations = 8;
  int _favoriteCount = 5;

  // Getters
  String? get userId => _userId;
  int get gemstoneCount => _gemstoneCount;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // User data compatibility getters
  UserModel? get user => UserModel(
    id: _userId ?? '',
    displayName: _userName,
    email: _userEmail,
    photoURL: _userPhotoURL,
  );
  bool get isPremium => _isPremium;
  DateTime? get subscriptionEndDate => _subscriptionEndDate;
  int get totalGenerations => _totalGenerations;
  int get monthlyGenerations => _monthlyGenerations;
  int get weeklyGenerations => _weeklyGenerations;
  int get favoriteCount => _favoriteCount;

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

  /// Update user profile
  Future<void> updateProfile({String? displayName, String? email}) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (displayName != null) _userName = displayName;
      if (email != null) _userEmail = email;

      // TODO: Save to Supabase
      await Future.delayed(const Duration(seconds: 1));

      AppLogger.info('Profile updated successfully', tag: _logTag);
    } catch (e) {
      _error = 'Failed to update profile: $e';
      AppLogger.error('Failed to update profile: $e', tag: _logTag);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Export user data
  Future<void> exportUserData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Implement data export
      await Future.delayed(const Duration(seconds: 2));

      AppLogger.info('User data exported successfully', tag: _logTag);
    } catch (e) {
      _error = 'Failed to export data: $e';
      AppLogger.error('Failed to export data: $e', tag: _logTag);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Clear Supabase session
      _userId = null;
      _userName = null;
      _userEmail = null;
      _userPhotoURL = null;
      _gemstoneCount = 100;
      _isPremium = false;
      _subscriptionEndDate = null;

      AppLogger.info('User logged out successfully', tag: _logTag);
    } catch (e) {
      _error = 'Failed to logout: $e';
      AppLogger.error('Failed to logout: $e', tag: _logTag);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Delete from Supabase
      await Future.delayed(const Duration(seconds: 2));

      // Clear all data
      _userId = null;
      _userName = null;
      _userEmail = null;
      _userPhotoURL = null;
      _gemstoneCount = 0;
      _isPremium = false;
      _subscriptionEndDate = null;

      AppLogger.info('User account deleted successfully', tag: _logTag);
    } catch (e) {
      _error = 'Failed to delete account: $e';
      AppLogger.error('Failed to delete account: $e', tag: _logTag);
    } finally {
      _isLoading = false;
      notifyListeners();
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

/// User Model for compatibility
class UserModel {
  final String id;
  final String? displayName;
  final String? email;
  final String? photoURL;

  UserModel({required this.id, this.displayName, this.email, this.photoURL});
}
