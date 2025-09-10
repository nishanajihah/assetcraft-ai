/// Asset Model
///
/// Represents a generated asset in the gallery
class AssetModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final int likes;
  final bool isPublic;
  bool isFavorite;
  final String authorId;
  final String authorName;
  final String? localPath;
  final String? cloudUrl;
  final String? prompt;
  final String? assetType;

  AssetModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.tags,
    required this.createdAt,
    required this.likes,
    required this.isPublic,
    required this.isFavorite,
    required this.authorId,
    required this.authorName,
    this.localPath,
    this.cloudUrl,
    this.prompt,
    this.assetType,
  });
  AssetModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? category,
    List<String>? tags,
    DateTime? createdAt,
    int? likes,
    bool? isPublic,
    bool? isFavorite,
    String? authorId,
    String? authorName,
    String? localPath,
    String? cloudUrl,
    String? prompt,
    String? assetType,
  }) {
    return AssetModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      isPublic: isPublic ?? this.isPublic,
      isFavorite: isFavorite ?? this.isFavorite,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      localPath: localPath ?? this.localPath,
      cloudUrl: cloudUrl ?? this.cloudUrl,
      prompt: prompt ?? this.prompt,
      assetType: assetType ?? this.assetType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'isPublic': isPublic,
      'isFavorite': isFavorite,
      'authorId': authorId,
      'authorName': authorName,
    };
  }

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      tags: List<String>.from(json['tags'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      likes: json['likes'] as int,
      isPublic: json['isPublic'] as bool,
      isFavorite: json['isFavorite'] as bool,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
    );
  }
}
