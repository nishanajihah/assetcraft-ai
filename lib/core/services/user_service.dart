import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';
import '../utils/app_logger.dart';
import 'notification_service.dart';

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
      if (user == null) return;

      // Get user's last daily gemstone claim from Supabase
      final response = await _supabase
          .from('users')
          .select('gemstones, last_daily_gemstone_claim')
          .eq('id', user.id)
          .single();

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
        // lastClaimDate is start of that day, today is start of today
        // Award if today is after the last claim date
        shouldAwardGemstones = today.isAfter(lastClaimDate);
      }

      if (shouldAwardGemstones) {
        const dailyGemstones = 5; // Award 5 daily gemstones
        final newTotal = currentGemstones + dailyGemstones;

        // Update user's gemstones and last claim date
        await _supabase
            .from('users')
            .update({
              'gemstones': newTotal,
              'last_daily_gemstone_claim': now.toIso8601String(),
            })
            .eq('id', user.id);

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
    } catch (e) {
      AppLogger.error('❌ Error checking daily gemstones: $e');
    }
  }

  void dispose() {
    _dailyCheckTimer?.cancel();
    _gemstonesController?.close();
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
