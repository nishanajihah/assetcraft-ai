import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'user_service.g.dart';

/// Service for managing user-related operations like credits
class UserService {
  final SupabaseClient _supabase;

  UserService(this._supabase);

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

      // Deduct one credit
      await _supabase
          .from('users')
          .update({'credits': currentCredits - 1})
          .eq('id', user.id);
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

      // Add credits
      await _supabase
          .from('users')
          .update({'credits': currentCredits + amount})
          .eq('id', user.id);
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
    } catch (e) {
      throw Exception('Failed to update credits: $e');
    }
  }
}

/// Riverpod Provider that exposes the UserService
@riverpod
UserService userService(UserServiceRef ref) {
  return UserService(Supabase.instance.client);
}

/// Provider for getting current user credits
@riverpod
Future<int> userCredits(UserCreditsRef ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getCredits();
}
