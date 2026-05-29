import 'package:equatable/equatable.dart';

/// Модель пользователя
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final String? university;
  final String? faculty;
  final String? course;
  final List<String> skills;
  final int projectsCount;
  final int followersCount;
  final int followingCount;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.university,
    this.faculty,
    this.course,
    this.skills = const [],
    this.projectsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isOnline = false,
    this.lastSeen,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        avatarUrl,
        bio,
        university,
        skills,
        projectsCount,
        followersCount,
        followingCount,
        isOnline,
        lastSeen,
        createdAt,
      ];

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? bio,
    String? university,
    String? faculty,
    String? course,
    List<String>? skills,
    int? projectsCount,
    int? followersCount,
    int? followingCount,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      university: university ?? this.university,
      faculty: faculty ?? this.faculty,
      course: course ?? this.course,
      skills: skills ?? this.skills,
      projectsCount: projectsCount ?? this.projectsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'university': university,
      'faculty': faculty,
      'course': course,
      'skills': skills,
      'projectsCount': projectsCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      bio: json['bio'],
      university: json['university'],
      faculty: json['faculty'],
      course: json['course'],
      skills:
          json['skills'] != null ? List<String>.from(json['skills']) : const [],
      projectsCount: json['projectsCount'] ?? 0,
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      lastSeen:
          json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
