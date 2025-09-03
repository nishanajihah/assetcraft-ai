/// Application constants for AssetCraft AI
class AppConstants {
  static const String appName = 'AssetCraft AI';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'AI-powered asset creation tool for developers';

  // Database
  static const String hiveBoxName = 'assetcraft_ai_box';
  static const String userBoxName = 'user_box';
  static const String assetsBoxName = 'assets_box';
  static const String gemstonesBoxName = 'gemstones_box';

  // API
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;

  // Asset generation
  static const int maxGenerationAttempts = 3;
  static const int maxAssetsPerGeneration = 10;

  // File paths
  static const String assetsPath = 'assets';
  static const String imagesPath = 'assets/images';
  static const String iconsPath = 'assets/icons';
  static const String animationsPath = 'assets/animations';
}

/// API endpoint constants
class ApiConstants {
  static const String geminiApiVersion = 'v1';
  static const String supabaseApiVersion = 'v1';

  // Gemini endpoints
  static const String generateContent = '/generateContent';
  static const String generateImage = '/generateImage';

  // Supabase endpoints
  static const String users = '/users';
  static const String assets = '/assets';
  static const String generations = '/generations';
}

/// Error message constants
class ErrorConstants {
  static const String networkError =
      'Network connection failed. Please check your internet connection.';
  static const String serverError =
      'Server error occurred. Please try again later.';
  static const String unknownError =
      'An unknown error occurred. Please try again.';
  static const String authError = 'Authentication failed. Please log in again.';
  static const String validationError =
      'Please check your input and try again.';
  static const String storageError =
      'Storage operation failed. Please try again.';
  static const String permissionError =
      'Permission denied. Please grant necessary permissions.';
}

/// Success message constants
class SuccessConstants {
  static const String assetGenerated = 'Asset generated successfully!';
  static const String assetSaved = 'Asset saved to gallery!';
  static const String profileUpdated = 'Profile updated successfully!';
  static const String settingsSaved = 'Settings saved successfully!';
  static const String authSuccess = 'Authentication successful!';
}
