import 'package:equatable/equatable.dart';
import 'user.dart';
import 'post.dart';

/// Модель проекта
class Project extends Equatable {
  final String id;
  final String title;
  final String description;
  final User author;
  final List<String> images;
  final List<String> skills;
  final List<User> teamMembers;
  final String status; // 'idea', 'in_progress', 'completed', 'looking_for_team'
  final int likesCount;
  final int commentsCount;
  final List<Comment> comments;
  final int viewsCount;
  final bool isLiked;
  final bool isSaved;
  final List<String> universityTags;
  final String? zipFileUrl;      // URL к ZIP файлу
  final String? zipFileName;    // Имя ZIP файла
  final int zipFileSize;        // Размер в байтах
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    this.images = const [],
    this.skills = const [],
    this.teamMembers = const [],
    this.status = 'idea',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.comments = const [],
    this.viewsCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.universityTags = const [],
    this.zipFileUrl,
    this.zipFileName,
    this.zipFileSize = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        author,
        images,
        skills,
        teamMembers,
        status,
        likesCount,
        commentsCount,
        comments,
        viewsCount,
        isLiked,
        isSaved,
        universityTags,
        zipFileUrl,
        zipFileName,
        zipFileSize,
        createdAt,
        updatedAt,
      ];

  Project copyWith({
    String? id,
    String? title,
    String? description,
    User? author,
    List<String>? images,
    List<String>? skills,
    List<User>? teamMembers,
    String? status,
    int? likesCount,
    int? commentsCount,
    List<Comment>? comments,
    int? viewsCount,
    bool? isLiked,
    bool? isSaved,
    List<String>? universityTags,
    String? zipFileUrl,
    String? zipFileName,
    int? zipFileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      images: images ?? this.images,
      skills: skills ?? this.skills,
      teamMembers: teamMembers ?? this.teamMembers,
      status: status ?? this.status,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      comments: comments ?? this.comments,
      viewsCount: viewsCount ?? this.viewsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      universityTags: universityTags ?? this.universityTags,
      zipFileUrl: zipFileUrl ?? this.zipFileUrl,
      zipFileName: zipFileName ?? this.zipFileName,
      zipFileSize: zipFileSize ?? this.zipFileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'author': author.toJson(),
      'images': images,
      'skills': skills,
      'teamMembers': teamMembers.map((m) => m.toJson()).toList(),
      'status': status,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'comments': comments.map((c) => c.toJson()).toList(),
      'viewsCount': viewsCount,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'universityTags': universityTags,
      'zipFileUrl': zipFileUrl,
      'zipFileName': zipFileName,
      'zipFileSize': zipFileSize,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      author: User.fromJson(json['author']),
      images:
          json['images'] != null ? List<String>.from(json['images']) : const [],
      skills:
          json['skills'] != null ? List<String>.from(json['skills']) : const [],
      teamMembers: json['teamMembers'] != null
          ? (json['teamMembers'] as List).map((m) => User.fromJson(m)).toList()
          : const [],
      status: json['status'] ?? 'idea',
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      comments: json['comments'] != null
          ? (json['comments'] as List).map((c) => Comment.fromJson(c)).toList()
          : const [],
      viewsCount: json['viewsCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      universityTags: json['universityTags'] != null
          ? List<String>.from(json['universityTags'])
          : const [],
      zipFileUrl: json['zipFileUrl'] ?? json['zip_file_url'],
      zipFileName: json['zipFileName'] ?? json['zip_file_name'],
      zipFileSize: json['zipFileSize'] ?? json['zip_file_size'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Статус проекта в виде русского текста
  String get statusRu {
    switch (status) {
      case 'idea':
        return 'Идея';
      case 'in_progress':
        return 'В разработке';
      case 'completed':
        return 'Завершён';
      case 'looking_for_team':
        return 'Ищу команду';
      default:
        return status;
    }
  }

  /// Цвет для статуса
  String get statusColor {
    switch (status) {
      case 'idea':
        return '#F59E0B'; // warning
      case 'in_progress':
        return '#3B82F6'; // info
      case 'completed':
        return '#22C55E'; // success
      case 'looking_for_team':
        return '#8B5CF6'; // purple
      default:
        return '#6B7280';
    }
  }

  /// Есть ли прикрепленный ZIP файл
  bool get hasZipFile => zipFileUrl != null && zipFileName != null;

  /// Форматированный размер файла
  String get zipFileSizeFormatted {
    if (zipFileSize <= 0) return '';
    if (zipFileSize < 1024) return '$zipFileSize B';
    if (zipFileSize < 1024 * 1024) return '${(zipFileSize / 1024).toStringAsFixed(1)} KB';
    return '${(zipFileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
