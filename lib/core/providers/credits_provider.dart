import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'credits_provider.g.dart';

/// User credits state management
///
/// This provider manages the user's "Gemstone" credits for AI generation.
/// Currently uses a simple state provider, but can be extended to integrate
/// with local storage, cloud sync, and payment systems.
class UserCredits {
  final int current;
  final int daily;
  final DateTime lastDailyReset;

  const UserCredits({
    required this.current,
    required this.daily,
    required this.lastDailyReset,
  });

  UserCredits copyWith({int? current, int? daily, DateTime? lastDailyReset}) {
    return UserCredits(
      current: current ?? this.current,
      daily: daily ?? this.daily,
      lastDailyReset: lastDailyReset ?? this.lastDailyReset,
    );
  }

  /// Check if daily credits need to be reset
  bool get needsDailyReset {
    final now = DateTime.now();
    final resetDate = DateTime(
      lastDailyReset.year,
      lastDailyReset.month,
      lastDailyReset.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(resetDate);
  }

  /// Total available credits (current + daily if available)
  int get totalAvailable {
    if (needsDailyReset) {
      return current + 5; // 5 daily credits from constants
    }
    return current + daily;
  }
}

/// Credits state provider
@riverpod
class UserCreditsNotifier extends _$UserCreditsNotifier {
  @override
  UserCredits build() {
    // Initialize with some demo credits
    // In a real app, this would load from local storage or API
    return UserCredits(
      current: 25, // Starting credits
      daily: 5, // Daily free credits
      lastDailyReset: DateTime.now().subtract(
        const Duration(days: 1),
      ), // Needs reset
    );
  }

  /// Deduct credits for AI generation
  bool deductCredits(int amount) {
    final credits = state;

    // Check if daily reset is needed
    if (credits.needsDailyReset) {
      state = credits.copyWith(
        daily: 5, // Reset daily credits
        lastDailyReset: DateTime.now(),
      );
    }

    final updated = state;
    if (updated.totalAvailable >= amount) {
      // First use daily credits, then current credits
      int newDaily = updated.daily;
      int newCurrent = updated.current;
      int remaining = amount;

      if (remaining > 0 && newDaily > 0) {
        final dailyUsed = remaining.clamp(0, newDaily);
        newDaily -= dailyUsed;
        remaining -= dailyUsed;
      }

      if (remaining > 0) {
        newCurrent -= remaining;
      }

      state = updated.copyWith(current: newCurrent, daily: newDaily);
      return true;
    }
    return false;
  }

  /// Add credits (from purchases, rewards, etc.)
  void addCredits(int amount) {
    state = state.copyWith(current: state.current + amount);
  }

  /// Reset daily credits manually
  void resetDailyCredits() {
    state = state.copyWith(daily: 5, lastDailyReset: DateTime.now());
  }
}

/// Provider for total available credits (read-only)
@riverpod
int totalAvailableCredits(TotalAvailableCreditsRef ref) {
  final credits = ref.watch(userCreditsNotifierProvider);
  return credits.totalAvailable;
}
