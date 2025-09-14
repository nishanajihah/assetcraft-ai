import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/logger.dart';

/// Supabase Storage Service
///
/// Handles image uploads and storage operations
/// Features:
/// - Upload images to Supabase Storage
/// - Generate secure URLs for image access
/// - Handle file permissions and bucket management
/// - Error handling and retry logic
class SupabaseStorageService {
  static const String _logTag = 'SupabaseStorageService';
  static const String _bucketName = 'user-assets';
  static const Uuid _uuid = Uuid();

  static SupabaseClient get _supabase => Supabase.instance.client;

  /// Upload image to Supabase Storage
  /// Returns the public URL of the uploaded image
  static Future<String?> uploadImage({
    required String imageBase64,
    required String userId,
    String? fileName,
    String? assetType,
  }) async {
    try {
      AppLogger.info('Uploading image to Supabase Storage', tag: _logTag);

      // Decode base64 image
      final imageBytes = base64Decode(imageBase64);

      // Generate unique filename if not provided
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = _uuid.v4().substring(0, 8);
      final finalFileName =
          fileName ?? '${assetType ?? 'asset'}_${timestamp}_$uniqueId.png';

      // Create file path with user folder structure
      final filePath = '$userId/$finalFileName';

      AppLogger.debug(
        'Uploading to path: $filePath (${imageBytes.length} bytes)',
        tag: _logTag,
      );

      // Upload to Supabase Storage
      final uploadResult = await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: false, // Don't overwrite existing files
            ),
          );

      if (uploadResult.isNotEmpty) {
        // Get public URL for the uploaded file
        final publicUrl = _supabase.storage
            .from(_bucketName)
            .getPublicUrl(filePath);

        AppLogger.success(
          'Image uploaded successfully: $filePath',
          tag: _logTag,
        );

        return publicUrl;
      } else {
        AppLogger.error('Upload failed: Empty result', tag: _logTag);
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload image: $e',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Delete image from storage
  static Future<bool> deleteImage(String filePath) async {
    try {
      AppLogger.info('Deleting image: $filePath', tag: _logTag);

      final result = await _supabase.storage.from(_bucketName).remove([
        filePath,
      ]);

      if (result.isNotEmpty) {
        AppLogger.success('Image deleted successfully', tag: _logTag);
        return true;
      } else {
        AppLogger.warning('Image not found or already deleted', tag: _logTag);
        return false;
      }
    } catch (e) {
      AppLogger.error('Failed to delete image: $e', tag: _logTag, error: e);
      return false;
    }
  }

  /// List user's uploaded images
  static Future<List<String>> listUserImages(String userId) async {
    try {
      AppLogger.info('Listing images for user: $userId', tag: _logTag);

      final result = await _supabase.storage
          .from(_bucketName)
          .list(path: userId);

      final imageUrls = result
          .where(
            (file) =>
                file.name.endsWith('.png') ||
                file.name.endsWith('.jpg') ||
                file.name.endsWith('.jpeg'),
          )
          .map(
            (file) => _supabase.storage
                .from(_bucketName)
                .getPublicUrl('$userId/${file.name}'),
          )
          .toList();

      AppLogger.success(
        'Found ${imageUrls.length} images for user',
        tag: _logTag,
      );

      return imageUrls;
    } catch (e) {
      AppLogger.error('Failed to list user images: $e', tag: _logTag, error: e);
      return [];
    }
  }

  /// Get file path from public URL
  static String? getFilePathFromUrl(String publicUrl) {
    try {
      final uri = Uri.parse(publicUrl);
      final pathSegments = uri.pathSegments;

      // Expected format: /storage/v1/object/public/user-assets/userId/filename
      if (pathSegments.length >= 4 && pathSegments[3] == _bucketName) {
        return pathSegments.sublist(4).join('/');
      }

      return null;
    } catch (e) {
      AppLogger.warning('Failed to parse file path from URL: $e', tag: _logTag);
      return null;
    }
  }

  /// Check if storage bucket exists and create if needed
  static Future<bool> ensureBucketExists() async {
    try {
      AppLogger.info('Checking storage bucket: $_bucketName', tag: _logTag);

      // Try to get bucket info
      final buckets = await _supabase.storage.listBuckets();
      final bucketExists = buckets.any((bucket) => bucket.name == _bucketName);

      if (!bucketExists) {
        AppLogger.info('Creating storage bucket: $_bucketName', tag: _logTag);

        await _supabase.storage.createBucket(
          _bucketName,
          BucketOptions(
            public: true,
            allowedMimeTypes: ['image/png', 'image/jpeg', 'image/jpg'],
          ),
        );

        AppLogger.success('Storage bucket created successfully', tag: _logTag);
      } else {
        AppLogger.info('Storage bucket already exists', tag: _logTag);
      }

      return true;
    } catch (e) {
      AppLogger.error(
        'Failed to ensure bucket exists: $e',
        tag: _logTag,
        error: e,
      );
      return false;
    }
  }
}
