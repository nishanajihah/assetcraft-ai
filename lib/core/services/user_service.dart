import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../utils/app_logger.dart';
import 'notification_service.dart';

part 'user_service.g.dart';

/// Service for managing user-related operations like credits
class UserService {
  final SupabaseClient _supabase;
  final NotificationService _notificationService;

  // Stream controller for credit changes
  StreamController<int>? _creditsController;
  Timer? _dailyCheckTimer;

  // Track daily credits for in-app notifications
  int? _lastDailyCreditsAwarded;
  int? _lastDailyCreditsTotal;
  UserService(this._supabase, this._notificationService) {
    _setupDailyCreditsCheck();
  }

  /// Setup automatic daily credits check
  void _setupDailyCreditsCheck() {
    // Check for daily credits every hour
    _dailyCheckTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkAndAwardDailyCredits(),
    );

    // Also check immediately on service creation
    _checkAndAwardDailyCredits();
  }

  /// Check if user should receive daily credits and award them
  Future<void> _checkAndAwardDailyCredits() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get user's last daily credit claim from Supabase
      final response = await _supabase
          .from('users')
          .select('credits, last_daily_credit_claim')
          .eq('id', user.id)
          .single();

      final currentCredits = response['credits'] as int? ?? 0;
      final lastClaimStr = response['last_daily_credit_claim'] as String?;

      DateTime? lastClaim;
      if (lastClaimStr != null) {
        lastClaim = DateTime.tryParse(lastClaimStr);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if user hasn't claimed today
      bool shouldAwardCredits = false;
      if (lastClaim == null) {
        shouldAwardCredits = true; // First time user
      } else {
        final lastClaimDate = DateTime(
          lastClaim.year,
          lastClaim.month,
          lastClaim.day,
        );
        shouldAwardCredits = today.isAfter(lastClaimDate);
      }

      if (shouldAwardCredits) {
        const dailyCredits = 5; // Award 5 daily gemstones
        final newTotal = currentCredits + dailyCredits;

        // Update user's credits and last claim date
        await _supabase
            .from('users')
            .update({
              'credits': newTotal,
              'last_daily_credit_claim': now.toIso8601String(),
            })
            .eq('id', user.id);

        AppLogger.info(
          '🎁 Awarded $dailyCredits daily credits. Total: $newTotal',
        );

        // Send notification about daily credits
        await _notificationService.sendDailyCreditNotification(
          creditsReceived: dailyCredits,
          totalCredits: newTotal,
        );

        // Store for in-app notification
        _lastDailyCreditsAwarded = dailyCredits;
        _lastDailyCreditsTotal = newTotal;

        // Notify listeners about credit change
        _creditsController?.add(newTotal);
      }
    } catch (e) {
      AppLogger.error('❌ Error checking daily credits: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _creditsController?.close();
    _dailyCheckTimer?.cancel();
  }

  /// Fetches the current credit count from the 'public.users' Supabase table for the signed-in user
  Future<int> getCredits() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('users')
          .select('credits')
          .eq('id', user.id)
          .single();

      return response['credits'] as int? ?? 0;
    } catch (e) {
      throw Exception('Failed to fetch credits: $e');
    }
  }

  /// Decrements the credit count by one in the 'public.users' table for the signed-in user
  Future<void> deductCredit() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // First get current credits
      final currentCredits = await getCredits();

      if (currentCredits <= 0) {
        throw Exception('Insufficient credits');
      }

      final newTotal = currentCredits - 1;

      // Deduct one credit
      await _supabase
          .from('users')
          .update({'credits': newTotal})
          .eq('id', user.id);

      // Notify listeners about credit change
      _creditsController?.add(newTotal);

      // Check if user is running low on credits and send notification
      if (newTotal <= 3) {
        await _notificationService.sendLowCreditsNotification(
          remainingCredits: newTotal,
        );
      }

      AppLogger.info('💎 Deducted 1 credit. Remaining: $newTotal');
    } catch (e) {
      throw Exception('Failed to deduct credit: $e');
    }
  }

  /// Adds credits to the user's account
  Future<void> addCredits(int amount) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current credits
      final currentCredits = await getCredits();
      final newTotal = currentCredits + amount;

      // Add credits
      await _supabase
          .from('users')
          .update({'credits': newTotal})
          .eq('id', user.id);

      // Notify listeners about credit change
      _creditsController?.add(newTotal);

      AppLogger.info('💎 Added $amount credits. New total: $newTotal');
    } catch (e) {
      throw Exception('Failed to add credits: $e');
    }
  }

  /// Updates the credit count to a specific value
  Future<void> updateCredits(int newAmount) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('users')
          .update({'credits': newAmount})
          .eq('id', user.id);

      // Notify listeners about credit change
      _creditsController?.add(newAmount);

      AppLogger.info('💎 Updated credits to: $newAmount');
    } catch (e) {
      throw Exception('Failed to update credits: $e');
    }
  }

  /// Stream of credit changes
  Stream<int> get creditsStream {
    _creditsController ??= StreamController<int>.broadcast();

    // Emit current credits when someone subscribes
    getCredits()
        .then((credits) {
          if (!_creditsController!.isClosed) {
            _creditsController!.add(credits);
          }
        })
        .catchError((e) {
          AppLogger.error('Error getting initial credits for stream: $e');
        });

    return _creditsController!.stream;
  }

  /// Manually trigger daily credits check (for testing)
  Future<void> checkDailyCredits() async {
    await _checkAndAwardDailyCredits();
  }

  /// Get the last daily credits awarded (for in-app notifications)
  int? get lastDailyCreditsAwarded => _lastDailyCreditsAwarded;

  /// Get the total credits after last daily award (for in-app notifications)
  int? get lastDailyCreditsTotal => _lastDailyCreditsTotal;

  /// Clear the daily credits notification data
  void clearDailyCreditsNotification() {
    _lastDailyCreditsAwarded = null;
    _lastDailyCreditsTotal = null;
  }
}

/// Riverpod Provider that exposes the UserService
@riverpod
UserService userService(UserServiceRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return UserService(Supabase.instance.client, notificationService);
}

/// Provider for getting current user credits (Future-based)
@riverpod
Future<int> userCredits(UserCreditsRef ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getCredits();
}

/// Provider for streaming user credits (Stream-based)
@riverpod
Stream<int> userCreditsStream(UserCreditsStreamRef ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.creditsStream;
}
