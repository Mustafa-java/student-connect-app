import 'package:equatable/equatable.dart';
import 'user.dart';
import 'project.dart';

/// Модель поста в ленте (может содержать проект или быть обычным постом)
class Post extends Equatable {
  final String id;
  final User author;
  final String? content; // Текст поста
  final Project? project; // Связанный проект (если есть)
  final List<String> images;
  final String? videoUrl;
  final List<String> tags;
  final int likesCount;
  final int commentsCount;
  final List<Comment> comments;
  final int sharesCount;
  final bool isLiked;
  final bool isSaved;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.author,
    this.content,
    this.project,
    this.images = const [],
    this.videoUrl,
    this.tags = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.comments = const [],
    this.sharesCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        author,
        content,
        project,
        images,
        videoUrl,
        tags,
        likesCount,
        commentsCount,
        comments,
        sharesCount,
        isLiked,
        isSaved,
        createdAt,
      ];

  Post copyWith({
    String? id,
    User? author,
    String? content,
    Project? project,
    List<String>? images,
    String? videoUrl,
    List<String>? tags,
    int? likesCount,
    int? commentsCount,
    List<Comment>? comments,
    int? sharesCount,
    bool? isLiked,
    bool? isSaved,
    DateTime? createdAt,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      project: project ?? this.project,
      images: images ?? this.images,
      videoUrl: videoUrl ?? this.videoUrl,
      tags: tags ?? this.tags,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      comments: comments ?? this.comments,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'content': content,
      'project': project?.toJson(),
      'images': images,
      'videoUrl': videoUrl,
      'tags': tags,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'comments': comments.map((c) => c.toJson()).toList(),
      'sharesCount': sharesCount,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      author: User.fromJson(json['author']),
      content: json['content'],
      project:
          json['project'] != null ? Project.fromJson(json['project']) : null,
      images:
          json['images'] != null ? List<String>.from(json['images']) : const [],
      videoUrl: json['videoUrl'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : const [],
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      comments: json['comments'] != null
          ? (json['comments'] as List).map((c) => Comment.fromJson(c)).toList()
          : const [],
      sharesCount: json['sharesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Является ли пост проектом
  bool get isProjectPost => project != null;

  /// Заголовок поста
  String get title {
    if (project != null) {
      return project!.title;
    }
    // Обрезаем контент до 50 символов для заголовка
    if (content != null && content!.isNotEmpty) {
      return content!.length > 50
          ? '${content!.substring(0, 50)}...'
          : content!;
    }
    return 'Пост';
  }
}

/// Модель комментария
class Comment extends Equatable {
  final String id;
  final User author;
  final String content;
  final int likesCount;
  final bool isLiked;
  final DateTime createdAt;
  final List<Comment> replies;

  const Comment({
    required this.id,
    required this.author,
    required this.content,
    this.likesCount = 0,
    this.isLiked = false,
    required this.createdAt,
    this.replies = const [],
  });

  @override
  List<Object?> get props => [
        id,
        author,
        content,
        likesCount,
        isLiked,
        createdAt,
        replies,
      ];

  Comment copyWith({
    String? id,
    User? author,
    String? content,
    int? likesCount,
    bool? isLiked,
    DateTime? createdAt,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'content': content,
      'likesCount': likesCount,
      'isLiked': isLiked,
      'createdAt': createdAt.toIso8601String(),
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      author: User.fromJson(json['author']),
      content: json['content'] ?? '',
      likesCount: json['likesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      replies: json['replies'] != null
          ? (json['replies'] as List).map((r) => Comment.fromJson(r)).toList()
          : const [],
    );
  }
}
