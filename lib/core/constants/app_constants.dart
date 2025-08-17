/// App-wide constants for AssetCraft AI
class AppConstants {
  // App Info
  static const String appName = 'AssetCraft AI';
  static const String appTagline = 'Create. Design. Build.';
  static const String appVersion = '1.0.0';

  // Credit System
  static const int freeDailyCredits = 5;
  static const int starterPackCredits = 25;
  static const int creatorPackCredits = 75;
  static const int proPackCredits = 200;

  // Pricing (in USD cents)
  static const int starterPackPrice = 299; // $2.99
  static const int creatorPackPrice = 799; // $7.99
  static const int proPackPrice = 1999; // $19.99
  static const int premiumMonthlyPrice = 999; // $9.99

  // Product IDs for RevenueCat
  static const String starterPackId = 'starter_pack_25';
  static const String creatorPackId = 'creator_pack_75';
  static const String proPackId = 'pro_pack_200';
  static const String premiumMonthlyId = 'premium_monthly';

  // Asset Generation
  static const int maxPromptLength = 500;
  static const List<String> supportedFormats = ['PNG', 'JPG', 'SVG'];
  static const List<String> assetTypes = [
    'Character',
    'Environment',
    'UI Element',
    'Icon',
    'Texture',
    'Logo',
    'Background',
    'Object',
  ];

  // File Storage
  static const int maxFileSizeMB = 10;
  static const int maxAssetsPerUser = 1000;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Error Messages
  static const String noInternetError = 'No internet connection';
  static const String insufficientCreditsError = 'Insufficient credits';
  static const String generationFailedError = 'Asset generation failed';
  static const String loginRequiredError = 'Please log in to continue';

  // Success Messages
  static const String assetGeneratedSuccess = 'Asset generated successfully!';
  static const String assetSavedSuccess = 'Asset saved to library';
  static const String creditsAddedSuccess = 'Credits added to account';
}
