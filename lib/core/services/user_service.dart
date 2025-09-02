import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';
import '../utils/app_logger.dart';
import '../config/environment.dart';
import 'notification_service.dart';
import '../../mock/mock_config.dart';

part 'user_service.g.dart';

/// Service for managing user-related operations like gemstones
class UserService {
  final SupabaseClient _supabase;
  final NotificationService _notificationService;
  Timer? _dailyCheckTimer;

  // Stream controller for gemstone changes
  StreamController<int>? _gemstonesController;

  // Track daily gemstones for in-app notifications
  int? _lastDailyGemstonesAwarded;
  int? _lastDailyGemstonesTotal;

  UserService(this._supabase, this._notificationService) {
    _setupDailyGemstonesCheck();
  }

  /// Setup automatic daily gemstones check
  void _setupDailyGemstonesCheck() {
    // Check for daily gemstones every hour
    _dailyCheckTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkAndAwardDailyGemstones(),
    );

    // Initial check
    _checkAndAwardDailyGemstones();
  }

  /// Check if user should receive daily gemstones and award them
  Future<void> _checkAndAwardDailyGemstones() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        AppLogger.debug(
          '⚠️ No authenticated user, skipping daily gemstones check',
        );
        return;
      }

      // Check if we're using mock auth or mock gemstones to avoid unnecessary Supabase calls
      if (Environment.enableMockAuth || MockConfig.isMockGemstonesEnabled) {
        AppLogger.debug('🧪 Mock mode enabled, using mock daily gemstones');
        await _handleMockDailyGemstones();
        return;
      }

      try {
        // Get user's last daily gemstone claim from Supabase
        final response = await _supabase
            .from('users')
            .select('gemstones, last_daily_gemstone_claim')
            .eq('id', user.id)
            .maybeSingle();

        // Handle case where user profile doesn't exist yet
        if (response == null) {
          await _createNewUserProfile(user);
          return;
        }

        await _processDailyGemstonesFromResponse(response, user);
      } catch (e) {
        AppLogger.error('❌ Database error in daily gemstones: $e');
        // If database has schema issues, fall back to mock mode
        AppLogger.info(
          '🧪 Falling back to mock daily gemstones due to database error',
        );
        await _handleMockDailyGemstones();
      }
    } catch (e) {
      AppLogger.error('❌ Error checking daily gemstones: $e');
    }
  }

  /// Create new user profile
  Future<void> _createNewUserProfile(User user) async {
    AppLogger.info('👤 Creating new user profile for: ${user.email}');

    // Create user profile with initial gemstones (without problematic columns)
    await _supabase.from('users').insert({
      'id': user.id,
      'email': user.email,
      'gemstones': 8, // Starting gemstones
      'created_at': DateTime.now().toIso8601String(),
    });

    // Award first-time gemstones (25 starting + 5 daily)
    const initialGemstones = 25;
    const dailyGemstones = 5;
    const newTotal = initialGemstones + dailyGemstones;

    // Update the user profile with daily gemstones awarded
    await _supabase
        .from('users')
        .update({'gemstones': newTotal})
        .eq('id', user.id);

    AppLogger.info(
      '🎁 New user! Awarded $dailyGemstones daily gemstones. Total: $newTotal',
    );

    // Send notification about daily gemstones
    await _notificationService.sendDailyGemstoneNotification(
      gemstonesReceived: dailyGemstones,
      totalGemstones: newTotal,
    );

    // Store for in-app notifications
    _lastDailyGemstonesAwarded = dailyGemstones;
    _lastDailyGemstonesTotal = newTotal;

    // Notify listeners about gemstone change
    _gemstonesController?.add(newTotal);
  }

  /// Process daily gemstones from database response
  Future<void> _processDailyGemstonesFromResponse(
    Map<String, dynamic> response,
    User user,
  ) async {
    final currentGemstones = response['gemstones'] as int? ?? 0;
    final lastClaimStr = response['last_daily_gemstone_claim'] as String?;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? lastClaimDate;
    if (lastClaimStr != null) {
      lastClaimDate = DateTime.parse(lastClaimStr);
      lastClaimDate = DateTime(
        lastClaimDate.year,
        lastClaimDate.month,
        lastClaimDate.day,
      );
    }

    bool shouldAwardGemstones = false;
    if (lastClaimDate == null) {
      shouldAwardGemstones = true; // First time user
    } else {
      // Award if it's a new day since last claim
      shouldAwardGemstones = today.isAfter(lastClaimDate);
    }

    if (shouldAwardGemstones) {
      const dailyGemstones = 5; // Award 5 daily gemstones
      final newTotal = currentGemstones + dailyGemstones;

      // Update user's gemstones (without the problematic column if it fails)
      try {
        await _supabase
            .from('users')
            .update({
              'gemstones': newTotal,
              'last_daily_gemstone_claim': now.toIso8601String(),
            })
            .eq('id', user.id);
      } catch (e) {
        // If the column doesn't exist, update without it
        AppLogger.warning(
          'Column last_daily_gemstone_claim missing, updating without it',
        );
        await _supabase
            .from('users')
            .update({'gemstones': newTotal})
            .eq('id', user.id);
      }

      AppLogger.info(
        '🎁 Awarded $dailyGemstones daily gemstones. Total: $newTotal',
      );

      // Send notification about daily gemstones
      await _notificationService.sendDailyGemstoneNotification(
        gemstonesReceived: dailyGemstones,
        totalGemstones: newTotal,
      );

      // Store for in-app notifications
      _lastDailyGemstonesAwarded = dailyGemstones;
      _lastDailyGemstonesTotal = newTotal;

      // Notify listeners about gemstone change
      _gemstonesController?.add(newTotal);
    }
  }

  /// Handle mock daily gemstones
  Future<void> _handleMockDailyGemstones() async {
    // Simulate daily gemstones in mock mode
    const dailyGemstones = 5;
    const mockCurrentGemstones = 50; // Mock current gemstones

    // Set mock data for daily gemstones notification
    _lastDailyGemstonesAwarded = dailyGemstones;
    _lastDailyGemstonesTotal = mockCurrentGemstones + dailyGemstones;

    AppLogger.info(
      '🧪 Mock daily gemstones awarded: +$dailyGemstones (Total: $_lastDailyGemstonesTotal)',
    );

    // Notify listeners
    _gemstonesController?.add(_lastDailyGemstonesTotal!);

    // Send mock notification
    await _notificationService.sendDailyGemstoneNotification(
      gemstonesReceived: dailyGemstones,
      totalGemstones: _lastDailyGemstonesTotal!,
    );
  }

  void dispose() {
    _dailyCheckTimer?.cancel();
    _gemstonesController?.close();
  }

  /// Log out the current user
  Future<void> logout() async {
    try {
      AppLogger.info('🚪 Logging out user');

      // Sign out from Supabase
      await _supabase.auth.signOut();

      // Cancel timers and clean up
      _dailyCheckTimer?.cancel();
      _gemstonesController?.close();

      AppLogger.info('✅ User logged out successfully');
    } catch (e) {
      AppLogger.error('❌ Error during logout: $e');
      throw Exception('Failed to logout: $e');
    }
  }

  /// Delete the current user account
  /// This method calls a Supabase Edge Function to securely delete the user account
  /// and all associated data (assets, profile info, etc.)
  Future<void> deleteAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info('🗑️ Deleting user account: ${user.email}');

      // Call Supabase Edge Function to delete user account and all associated data
      // This is the secure way to delete user accounts from the server side
      final response = await _supabase.functions.invoke(
        'delete-user-account',
        body: {'user_id': user.id},
      );

      if (response.status != 200) {
        throw Exception('Server error: ${response.status}');
      }

      // Clean up local resources
      _dailyCheckTimer?.cancel();
      _gemstonesController?.close();

      AppLogger.info('✅ User account deleted successfully');
    } catch (e) {
      AppLogger.error('❌ Error deleting account: $e');

      // Provide more specific error messages
      if (e.toString().contains('not found') || e.toString().contains('404')) {
        throw Exception(
          'Account deletion service is not available. Please contact support.',
        );
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        throw Exception(
          'Network error. Please check your connection and try again.',
        );
      } else {
        throw Exception(
          'Failed to delete account: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  /// Fetches the current gemstone count from the 'public.users' Supabase table for the signed-in user
  Future<int> getGemstones() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('users')
          .select('gemstones')
          .eq('id', user.id)
          .single();

      return response['gemstones'] as int? ?? 0;
    } catch (e) {
      throw Exception('Failed to fetch gemstones: $e');
    }
  }

  /// Decrements the gemstone count by one in the 'public.users' table for the signed-in user
  Future<void> deductGemstone() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // First get current gemstones
      final currentGemstones = await getGemstones();

      if (currentGemstones <= 0) {
        throw Exception('Insufficient gemstones');
      }

      final newTotal = currentGemstones - 1;

      // Deduct one gemstone
      await _supabase
          .from('users')
          .update({'gemstones': newTotal})
          .eq('id', user.id);

      // Notify listeners about gemstone change
      _gemstonesController?.add(newTotal);

      // Check if user is running low on gemstones and send notification
      if (newTotal <= 2) {
        await _notificationService.sendLowGemstonesNotification(
          remainingGemstones: newTotal,
        );
      }

      AppLogger.info('💎 Deducted 1 gemstone. Remaining: $newTotal');
    } catch (e) {
      throw Exception('Failed to deduct gemstone: $e');
    }
  }

  /// Adds gemstones to the user's account
  Future<void> addGemstones(int amount) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current gemstones
      final currentGemstones = await getGemstones();
      final newTotal = currentGemstones + amount;

      // Add gemstones
      await _supabase
          .from('users')
          .update({'gemstones': newTotal})
          .eq('id', user.id);

      // Notify listeners about gemstone change
      _gemstonesController?.add(newTotal);

      AppLogger.info('💎 Added $amount gemstones. New total: $newTotal');
    } catch (e) {
      throw Exception('Failed to add gemstones: $e');
    }
  }

  /// Updates the gemstone count to a specific value
  Future<void> updateGemstones(int newAmount) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('users')
          .update({'gemstones': newAmount})
          .eq('id', user.id);

      // Notify listeners about gemstone change
      _gemstonesController?.add(newAmount);

      AppLogger.info('💎 Updated gemstones to: $newAmount');
    } catch (e) {
      throw Exception('Failed to update gemstones: $e');
    }
  }

  /// Stream of gemstone changes
  Stream<int> get gemstonesStream {
    _gemstonesController ??= StreamController<int>.broadcast();

    // Emit current gemstones when someone subscribes
    getGemstones()
        .then((gemstones) {
          if (!_gemstonesController!.isClosed) {
            _gemstonesController!.add(gemstones);
          }
        })
        .catchError((e) {
          AppLogger.error('Error getting initial gemstones for stream: $e');
        });

    return _gemstonesController!.stream;
  }

  /// Get current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  /// Manually trigger daily gemstones check (for testing)
  Future<void> checkDailyGemstones() async {
    await _checkAndAwardDailyGemstones();
  }

  /// Get the last daily gemstones awarded (for in-app notifications)
  int? get lastDailyGemstonesAwarded => _lastDailyGemstonesAwarded;

  /// Get the last daily gemstones total (for in-app notifications)
  int? get lastDailyGemstonesTotal => _lastDailyGemstonesTotal;

  /// Clear the daily gemstones notification flag
  void clearDailyGemstonesNotification() {
    _lastDailyGemstonesAwarded = null;
    _lastDailyGemstonesTotal = null;
  }

  // Legacy methods for backward compatibility (will be removed)
  @Deprecated('Use getGemstones() instead')
  Future<int> getCredits() => getGemstones();

  @Deprecated('Use deductGemstone() instead')
  Future<void> deductCredit() => deductGemstone();

  @Deprecated('Use addGemstones() instead')
  Future<void> addCredits(int amount) => addGemstones(amount);

  @Deprecated('Use updateGemstones() instead')
  Future<void> updateCredits(int newAmount) => updateGemstones(newAmount);

  @Deprecated('Use gemstonesStream instead')
  Stream<int> get creditsStream => gemstonesStream;

  @Deprecated('Use checkDailyGemstones() instead')
  Future<void> checkDailyCredits() => checkDailyGemstones();

  @Deprecated('Use lastDailyGemstonesAwarded instead')
  int? get lastDailyCreditsAwarded => lastDailyGemstonesAwarded;

  @Deprecated('Use lastDailyGemstonesTotal instead')
  int? get lastDailyCreditsTotal => lastDailyGemstonesTotal;

  @Deprecated('Use clearDailyGemstonesNotification() instead')
  void clearDailyCreditsNotification() => clearDailyGemstonesNotification();
}

/// Provider for UserService
@riverpod
UserService userService(UserServiceRef ref) {
  final supabase = Supabase.instance.client;
  final notificationService = ref.read(notificationServiceProvider);
  return UserService(supabase, notificationService);
}

/// Provider for user's current gemstone count
@riverpod
Future<int> userGemstones(UserGemstonesRef ref) async {
  final userService = ref.read(userServiceProvider);
  return await userService.getGemstones();
}

/// Provider for user's gemstone stream
@riverpod
Stream<int> userGemstonesStream(UserGemstonesStreamRef ref) {
  final userService = ref.read(userServiceProvider);
  return userService.gemstonesStream;
}
