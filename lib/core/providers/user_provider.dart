import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../services/auth_service.dart';
import '../../services/supabase_data_service.dart';

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
  bool _isPro = false;
  DateTime? _subscriptionEndDate;
  final int _totalGenerations = 25;
  final int _monthlyGenerations = 15;
  final int _weeklyGenerations = 8;
  final int _favoriteCount = 5;

  // Getters
  String? get userId => _userId;
  int get gemstoneCount => _gemstoneCount;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // User data compatibility getters
  UserModel? get user => _userId != null
      ? UserModel(
          id: _userId!,
          displayName: _userName,
          email: _userEmail,
          photoURL: _userPhotoURL,
          gemstones: _gemstoneCount,
          isPro: _isPro,
          subscriptionEndDate: _subscriptionEndDate,
        )
      : null;
  bool get isPro => _isPro;
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
      // Get current authenticated user
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final authUserId = currentUser.id;
      _userEmail = currentUser.email;

      // Get complete user data using the two-table structure
      final completeUserData = await SupabaseDataService.getCompleteUserData(
        authUserId,
      );

      if (completeUserData != null) {
        // Set user data from both tables
        _userId = completeUserData['id'] as String; // Internal user ID
        _userName = completeUserData['display_name'] as String?;
        _userPhotoURL = completeUserData['avatar_url'] as String?;
        _gemstoneCount = completeUserData['gemstones'] as int? ?? 100;
        _isPro = completeUserData['is_pro'] as bool? ?? false;

        // Parse subscription end date if exists
        if (completeUserData['subscription_end_date'] != null) {
          _subscriptionEndDate = DateTime.parse(
            completeUserData['subscription_end_date'] as String,
          );
        }

        // Update last login timestamp
        await SupabaseDataService.updateLastLogin(authUserId);
      } else {
        // If no user data found, this might be a new user
        // The trigger should have created records, so this is an error
        throw Exception('User profile not found after authentication');
      }

      AppLogger.info(
        'User initialized successfully',
        tag: _logTag,
        data: {
          'userId': _userId,
          'userName': _userName,
          'email': _userEmail,
          'gemstoneCount': _gemstoneCount,
          'isPro': _isPro,
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

      // Persist to database
      _updateGemstonesInDatabase();

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
  Future<void> updateProfile({
    String? displayName,
    String? email,
    String? avatarUrl,
  }) async {
    if (_userId == null) {
      _error = 'No user logged in';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final supabase = Supabase.instance.client;
      final updates = <String, dynamic>{};

      // Prepare updates
      if (displayName != null) {
        updates['display_name'] = displayName;
        _userName = displayName;
      }
      if (avatarUrl != null) {
        updates['avatar_url'] = avatarUrl;
        _userPhotoURL = avatarUrl;
      }

      // Update in user_profiles table
      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();

        await supabase
            .from('user_profiles')
            .update(updates)
            .eq('user_id', _userId!);

        AppLogger.info(
          'User profile updated successfully',
          tag: _logTag,
          data: updates,
        );
      }

      // Update email in auth if provided
      if (email != null && email != _userEmail) {
        await supabase.auth.updateUser(UserAttributes(email: email));
        _userEmail = email;

        AppLogger.info(
          'User email updated in auth',
          tag: _logTag,
          data: {'newEmail': email},
        );
      }

      AppLogger.success('Profile updated successfully', tag: _logTag);
    } catch (e) {
      _error = 'Failed to update profile: $e';
      AppLogger.error('Failed to update profile: $e', tag: _logTag, error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Export user data
  Future<Map<String, dynamic>?> exportUserData() async {
    if (_userId == null) {
      _error = 'No user logged in';
      notifyListeners();
      return null;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final supabase = Supabase.instance.client;

      // Export user profile
      final userProfile = await supabase
          .from('user_profiles')
          .select('*')
          .eq('user_id', _userId!)
          .single();

      // Export user assets
      final userAssets = await SupabaseDataService.loadUserAssets(_userId!);

      // Export generation history (if you have this table)
      List<dynamic> generationHistory = [];
      try {
        final historyResponse = await supabase
            .from('generation_history')
            .select('*')
            .eq('user_id', _userId!)
            .order('created_at', ascending: false);
        generationHistory = historyResponse;
      } catch (e) {
        AppLogger.warning(
          'No generation history found or table missing',
          tag: _logTag,
        );
      }

      final exportData = {
        'user_profile': userProfile,
        'assets': userAssets.map((asset) => asset.toJson()).toList(),
        'generation_history': generationHistory,
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0', // You can get this from package info
      };

      AppLogger.success(
        'User data exported successfully',
        tag: _logTag,
        data: {
          'assetsCount': userAssets.length,
          'historyCount': generationHistory.length,
        },
      );

      return exportData;
    } catch (e) {
      _error = 'Failed to export data: $e';
      AppLogger.error('Failed to export data: $e', tag: _logTag, error: e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Clear Supabase session
      await AuthService.signOut();

      // Clear all local user data
      _userId = null;
      _userName = null;
      _userEmail = null;
      _userPhotoURL = null;
      _gemstoneCount = 100; // Reset to default
      _isPro = false;
      _subscriptionEndDate = null;

      AppLogger.info('User logged out successfully', tag: _logTag);
    } catch (e) {
      _error = 'Failed to logout: $e';
      AppLogger.error('Failed to logout: $e', tag: _logTag, error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    if (_userId == null) {
      _error = 'No user logged in';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final supabase = Supabase.instance.client;
      final currentUserId = _userId!;

      AppLogger.warning(
        'Starting account deletion process',
        tag: _logTag,
        data: {'userId': currentUserId},
      );

      // Delete user assets from database
      // Note: If you have CASCADE DELETE set up, this might happen automatically
      await supabase.from('assets').delete().eq('user_id', currentUserId);

      // Delete generation history
      try {
        await supabase
            .from('generation_history')
            .delete()
            .eq('user_id', currentUserId);
      } catch (e) {
        AppLogger.warning(
          'Generation history table not found or already empty',
          tag: _logTag,
        );
      }

      // Delete user profile
      await supabase
          .from('user_profiles')
          .delete()
          .eq('user_id', currentUserId);

      // Delete from auth.users (this should be done last)
      // Note: This requires admin privileges or RPC function
      try {
        await supabase.rpc(
          'delete_user_account',
          params: {'user_id': currentUserId},
        );
      } catch (e) {
        // If RPC doesn't exist, user will need to be deleted manually from admin panel
        AppLogger.warning(
          'Could not delete auth user automatically - requires admin action',
          tag: _logTag,
        );
      }

      // Clear all local data
      _userId = null;
      _userName = null;
      _userEmail = null;
      _userPhotoURL = null;
      _gemstoneCount = 0;
      _isPro = false;
      _subscriptionEndDate = null;

      AppLogger.success('User account deleted successfully', tag: _logTag);
    } catch (e) {
      _error = 'Failed to delete account: $e';
      AppLogger.error('Failed to delete account: $e', tag: _logTag, error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add gemstones
  void addGemstones(int amount) {
    _gemstoneCount += amount;
    notifyListeners();

    // Persist to database
    _updateGemstonesInDatabase();

    AppLogger.info(
      'Added $amount gemstones',
      tag: _logTag,
      data: {'added': amount, 'total': _gemstoneCount},
    );
  }

  /// Update gemstones in database (async but fire-and-forget)
  void _updateGemstonesInDatabase() {
    if (_userId == null) return;

    SupabaseDataService.updateUserGemstones(_userId!, _gemstoneCount)
        .then((success) {
          if (!success) {
            AppLogger.warning(
              'Failed to persist gemstones to database',
              tag: _logTag,
              data: {'gemstones': _gemstoneCount},
            );
          }
        })
        .catchError((e) {
          AppLogger.error(
            'Error persisting gemstones: $e',
            tag: _logTag,
            error: e,
          );
        });
  }

  /// Check if user can afford an action
  bool canAfford(int cost) => _gemstoneCount >= cost;

  /// Reset error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh user data from database
  Future<void> refreshUserData() async {
    if (_userId == null) return;

    AppLogger.info('Refreshing user data', tag: _logTag);

    // Get current auth user ID
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    // Reload complete user data
    final completeUserData = await SupabaseDataService.getCompleteUserData(
      currentUser.id,
    );

    if (completeUserData != null) {
      _userName = completeUserData['display_name'] as String?;
      _userPhotoURL = completeUserData['avatar_url'] as String?;
      _gemstoneCount = completeUserData['gemstones'] as int? ?? _gemstoneCount;
      _isPro = completeUserData['is_pro'] as bool? ?? false;

      if (completeUserData['subscription_end_date'] != null) {
        _subscriptionEndDate = DateTime.parse(
          completeUserData['subscription_end_date'] as String,
        );
      }
    }

    notifyListeners();
  }

  /// Check if user is logged in
  bool get isLoggedIn => _userId != null && AuthService.isLoggedIn;

  /// Update subscription status
  Future<void> updateSubscriptionStatus(bool isPro, DateTime? endDate) async {
    if (_userId == null) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('user_profiles')
          .update({
            'is_pro': isPro,
            'subscription_end_date': endDate?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', _userId!);

      _isPro = isPro;
      _subscriptionEndDate = endDate;
      notifyListeners();

      AppLogger.info(
        'Subscription status updated',
        tag: _logTag,
        data: {'isPro': isPro, 'endDate': endDate},
      );
    } catch (e) {
      AppLogger.error(
        'Failed to update subscription: $e',
        tag: _logTag,
        error: e,
      );
    }
  }
}

/// Enhanced User Model for compatibility and data management
class UserModel {
  final String id;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final int gemstones;
  final bool isPro;
  final DateTime? subscriptionEndDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    this.displayName,
    this.email,
    this.photoURL,
    this.gemstones = 100,
    this.isPro = false,
    this.subscriptionEndDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Create UserModel from JSON (database response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      photoURL: json['avatar_url'] as String?,
      gemstones: json['gemstones'] as int? ?? 100,
      isPro: json['is_pro'] as bool? ?? false,
      subscriptionEndDate: json['subscription_end_date'] != null
          ? DateTime.parse(json['subscription_end_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert UserModel to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'avatar_url': photoURL,
      'gemstones': gemstones,
      'is_pro': isPro,
      'subscription_end_date': subscriptionEndDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoURL,
    int? gemstones,
    bool? isPro,
    DateTime? subscriptionEndDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      gemstones: gemstones ?? this.gemstones,
      isPro: isPro ?? this.isPro,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, displayName: $displayName, email: $email, gemstones: $gemstones, isPro: $isPro)';
  }
}
