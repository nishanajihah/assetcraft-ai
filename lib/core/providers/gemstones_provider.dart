import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gemstones_provider.g.dart';

/// User gemstones state management
///
/// This provider manages the user's "Gemstone" currency for AI generation.
/// Currently uses a simple state provider, but can be extended to integrate
/// with local storage, cloud sync, and payment systems.
class UserGemstones {
  final int current;
  final int daily;
  final DateTime lastDailyReset;

  const UserGemstones({
    required this.current,
    required this.daily,
    required this.lastDailyReset,
  });

  UserGemstones copyWith({int? current, int? daily, DateTime? lastDailyReset}) {
    return UserGemstones(
      current: current ?? this.current,
      daily: daily ?? this.daily,
      lastDailyReset: lastDailyReset ?? this.lastDailyReset,
    );
  }

  /// Check if daily gemstones need to be reset
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

  /// Total available gemstones (current + daily if available)
  int get totalAvailable {
    if (needsDailyReset) {
      return current + 5; // 5 daily gemstones from constants
    }
    return current + daily;
  }
}

/// Gemstones state provider
@riverpod
class UserGemstonesNotifier extends _$UserGemstonesNotifier {
  @override
  UserGemstones build() {
    // Initialize with some demo gemstones
    // In a real app, this would load from local storage or API
    return UserGemstones(
      current: 25, // Starting gemstones
      daily: 5, // Daily free gemstones
      lastDailyReset: DateTime.now().subtract(
        const Duration(days: 1),
      ), // Needs reset
    );
  }

  /// Deduct gemstones for AI generation
  bool deductGemstones(int amount) {
    final gemstones = state;

    // Check if daily reset is needed
    if (gemstones.needsDailyReset) {
      state = gemstones.copyWith(
        daily: 5, // Reset daily gemstones
        lastDailyReset: DateTime.now(),
      );
    }

    final updated = state;
    if (updated.totalAvailable >= amount) {
      // First use daily gemstones, then current gemstones
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

  /// Add gemstones (from purchases, rewards, etc.)
  void addGemstones(int amount) {
    state = state.copyWith(current: state.current + amount);
  }

  /// Reset daily gemstones manually
  void resetDailyGemstones() {
    state = state.copyWith(daily: 5, lastDailyReset: DateTime.now());
  }
}

/// Provider for total available gemstones (read-only)
@riverpod
int totalAvailableGemstones(TotalAvailableGemstonesRef ref) {
  final gemstones = ref.watch(userGemstonesNotifierProvider);
  return gemstones.totalAvailable;
}
