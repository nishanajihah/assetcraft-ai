/// Asset Model
///
/// Represents a generated asset in the gallery
/// Maps to the 'assets' table in Supabase
class AssetModel {
  final String id;
  final String userId;
  final String prompt;
  final String imagePath;
  final bool isPublic;
  final bool isFavorite;
  final DateTime createdAt;

  AssetModel({
    required this.id,
    required this.userId,
    required this.prompt,
    required this.imagePath,
    required this.isPublic,
    required this.isFavorite,
    required this.createdAt,
  });

  AssetModel copyWith({
    String? id,
    String? userId,
    String? prompt,
    String? imagePath,
    bool? isPublic,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return AssetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      prompt: prompt ?? this.prompt,
      imagePath: imagePath ?? this.imagePath,
      isPublic: isPublic ?? this.isPublic,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'prompt': prompt,
      'image_path': imagePath,
      'is_public': isPublic,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      prompt: json['prompt'] as String,
      imagePath: json['image_path'] as String,
      isPublic: json['is_public'] as bool,
      isFavorite: json['is_favorite'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'AssetModel(id: $id, userId: $userId, prompt: ${prompt.length > 50 ? '${prompt.substring(0, 50)}...' : prompt}, imagePath: $imagePath, isPublic: $isPublic, isFavorite: $isFavorite, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AssetModel &&
        other.id == id &&
        other.userId == userId &&
        other.prompt == prompt &&
        other.imagePath == imagePath &&
        other.isPublic == isPublic &&
        other.isFavorite == isFavorite &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        prompt.hashCode ^
        imagePath.hashCode ^
        isPublic.hashCode ^
        isFavorite.hashCode ^
        createdAt.hashCode;
  }
}

/// User Model
///
/// Represents a user profile in the database
/// Maps to the 'users' table in Supabase
class UserModel {
  final String id;
  final DateTime createdAt;
  final int gemstones;
  final DateTime? lastFreeGemstonesGrant;
  final bool proStatus;

  UserModel({
    required this.id,
    required this.createdAt,
    required this.gemstones,
    this.lastFreeGemstonesGrant,
    required this.proStatus,
  });

  UserModel copyWith({
    String? id,
    DateTime? createdAt,
    int? gemstones,
    DateTime? lastFreeGemstonesGrant,
    bool? proStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      gemstones: gemstones ?? this.gemstones,
      lastFreeGemstonesGrant:
          lastFreeGemstonesGrant ?? this.lastFreeGemstonesGrant,
      proStatus: proStatus ?? this.proStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'gemstones': gemstones,
      'last_free_gemstones_grant': lastFreeGemstonesGrant?.toIso8601String(),
      'pro_status': proStatus,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      gemstones: json['gemstones'] as int,
      lastFreeGemstonesGrant: json['last_free_gemstones_grant'] != null
          ? DateTime.parse(json['last_free_gemstones_grant'] as String)
          : null,
      proStatus: json['pro_status'] as bool,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, createdAt: $createdAt, gemstones: $gemstones, lastFreeGemstonesGrant: $lastFreeGemstonesGrant, proStatus: $proStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.gemstones == gemstones &&
        other.lastFreeGemstonesGrant == lastFreeGemstonesGrant &&
        other.proStatus == proStatus;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        createdAt.hashCode ^
        gemstones.hashCode ^
        lastFreeGemstonesGrant.hashCode ^
        proStatus.hashCode;
  }
}
