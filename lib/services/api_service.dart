import 'dart:convert' as convert;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// HTTP API клиент для Node.js бэкенда
class ApiService {
  ApiService._privateConstructor();
  static final ApiService instance = ApiService._privateConstructor();

  // Для физического устройства: IP компьютера в локальной сети
  static const String _baseUrl = 'http://192.168.100.2:3000';
  static const String _tokenKey = 'api_token';
  static const String _userIdKey = 'api_user_id';

  late Dio _dio;
  String? _token;
  String? _currentUserId;
  final Map<String, String> _userIdToName = {};
  final Map<String, String> _userIdToAvatar = {};
  final Map<String, String> _userIdToEmail = {};
  final Map<String, bool> _userIdToOnline = {};

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get currentUserId => _currentUserId;
  String get baseUrl => _baseUrl;

  /// Инициализация — загрузка токена из storage
  Future<void> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ));

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _currentUserId = prefs.getString(_userIdKey);

    debugPrint('ApiService.init: token=${_token != null}, userId=$_currentUserId');

    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      debugPrint('ApiService.init: Authorization header set');
    }
  }

  /// Сохранить токен
  Future<void> _saveToken(String token, String userId) async {
    _token = token;
    _currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Удалить токен
  Future<void> _clearToken() async {
    _token = null;
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    _dio.options.headers.remove('Authorization');
    _userIdToName.clear();
    _userIdToAvatar.clear();
    _userIdToEmail.clear();
    _userIdToOnline.clear();
  }

  /// Кэш пользователей
  void cacheUser(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    if (id == null) return;
    _userIdToName[id] = data['name'] as String? ?? 'Пользователь';
    _userIdToAvatar[id] = data['avatar_url'] as String? ?? '';
    _userIdToEmail[id] = data['email'] as String? ?? '';
    _userIdToOnline[id] = (data['is_online'] as int?) == 1;
  }

  String _getUserName(String? userId) {
    if (userId == null) return 'Пользователь';
    return _userIdToName[userId] ?? 'Пользователь';
  }

  String? _getUserAvatar(String? userId) {
    if (userId == null) return null;
    final avatar = _userIdToAvatar[userId];
    return (avatar == null || avatar.isEmpty) ? null : avatar;
  }

  bool _getUserOnline(String? userId) {
    if (userId == null) return false;
    return _userIdToOnline[userId] ?? false;
  }

  /// Конвертировать ответ API в модель User
  User _parseUser(Map<String, dynamic> data) {
    cacheUser(data);
    final skillsRaw = data['skills'];
    List<String> skills = [];
    if (skillsRaw is String) {
      try { skills = List<String>.from(convert.jsonDecode(skillsRaw)); } catch(_) {}
    } else if (skillsRaw is List) {
      skills = skillsRaw.map((e) => e.toString()).toList();
    }

    return User(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Пользователь',
      email: data['email'] ?? '',
      avatarUrl: data['avatar_url'],
      bio: data['bio'],
      university: data['university'],
      faculty: data['faculty'],
      course: data['course'],
      skills: skills,
      projectsCount: _toInt(data['projects_count']),
      followersCount: _toInt(data['followers_count']),
      followingCount: _toInt(data['following_count']),
      isOnline: _toBool(data['is_online']),
      lastSeen: data['last_seen'] != null ? DateTime.fromMillisecondsSinceEpoch(data['last_seen']) : null,
      createdAt: data['created_at'] != null ? DateTime.fromMillisecondsSinceEpoch(data['created_at']) : DateTime.now(),
    );
  }

  /// Преобразуем int или bool в bool
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    return false;
  }

  /// Преобразуем в int
  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try { return int.parse(value); } catch(_) {}
    }
    return 0;
  }

  /// ==================== AUTH ====================

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? university,
    String? faculty,
    String? course,
    String? bio,
    List<String> skills = const [],
    String? avatarUrl,
  }) async {
    final response = await _dio.post('/api/auth/register', data: {
      'name': name, 'email': email, 'password': password,
      if (university != null) 'university': university,
      if (faculty != null) 'faculty': faculty,
      if (course != null) 'course': course,
      if (bio != null) 'bio': bio,
      if (skills.isNotEmpty) 'skills': skills,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });

    final data = response.data as Map<String, dynamic>;
    final user = _parseUser(data['user'] as Map<String, dynamic>);
    await _saveToken(data['token'] as String, user.id);
    return {'user': user};
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('=== LOGIN ATTEMPT (ApiService) ===');
      debugPrint('Email: $email');
      debugPrint('URL: $_baseUrl/api/auth/login');
      
      final response = await _dio.post('/api/auth/login', data: {
        'email': email, 
        'password': password,
      });

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');
      debugPrint('Response data type: ${response.data.runtimeType}');

      if (response.data == null) {
        throw Exception('Сервер вернул пустой ответ. Проверьте что backend работает.');
      }

      final data = response.data as Map<String, dynamic>;
      
      // Проверяем есть ли ошибка в ответе
      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }
      
      final user = _parseUser(data['user'] as Map<String, dynamic>);
      await _saveToken(data['token'] as String, user.id);
      debugPrint('Login successful for user: ${user.name}');
      debugPrint('===========================');
      return {'user': user};
    } on DioException catch (e) {
      debugPrint('DioException during login: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Status code: ${e.response?.statusCode}');
      debugPrint('===========================');
      throw Exception('Ошибка сети: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error during login: $e');
      debugPrint('===========================');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/api/auth/me');
    final data = response.data as Map<String, dynamic>;
    final user = _parseUser(data['user'] as Map<String, dynamic>);
    return {'user': user};
  }

  Future<void> logout() async {
    try {
      // Обновляем offline статус
      if (_currentUserId != null) {
        await _dio.put('/api/users/$_currentUserId', data: {'is_online': 0});
      }
    } catch (_) {}
    await _clearToken();
  }

  /// ==================== USERS ====================

  Future<List<User>> getAllUsers() async {
    try {
      final response = await _dio.get('/api/users');
      final data = response.data as Map<String, dynamic>;
      final users = (data['users'] as List)
          .map((u) => _parseUser(u as Map<String, dynamic>))
          .toList();
      return users;
    } catch (e) {
      debugPrint('getAllUsers error: $e');
      return [];
    }
  }

  Future<List<User>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      final response = await _dio.get('/api/users/search',
          queryParameters: {'q': query});
      final data = response.data as Map<String, dynamic>;
      return (data['users'] as List)
          .map((u) => _parseUser(u as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<User?> getUserById(String userId) async {
    try {
      final response = await _dio.get('/api/users/$userId');
      final data = response.data as Map<String, dynamic>;
      return _parseUser(data['user'] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/api/users/$_currentUserId', data: data);
    final responseData = response.data as Map<String, dynamic>;
    return _parseUser(responseData['user'] as Map<String, dynamic>);
  }

  /// ==================== POSTS ====================

  Future<List<Post>> getPosts() async {
    try {
      final response = await _dio.get('/api/posts');
      final data = response.data as Map<String, dynamic>;
      return (data['posts'] as List)
          .map((p) => _parsePost(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getPosts error: $e');
      return [];
    }
  }

  Future<Post> createPost({
    String? content,
    String? projectId,
    List<String> images = const [],
    List<String> tags = const [],
  }) async {
    final response = await _dio.post('/api/posts', data: {
      if (content != null) 'content': content,
      if (projectId != null) 'project_id': projectId,
      'images': images, 'tags': tags,
    });
    final data = response.data as Map<String, dynamic>;
    return _parsePost(data['post'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> toggleLike(String postId) async {
    final response = await _dio.post('/api/posts/$postId/like');
    return response.data as Map<String, dynamic>;
  }

  Future<bool> deletePost(String postId) async {
    try {
      final response = await _dio.delete('/api/posts/$postId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('deletePost error: $e');
      return false;
    }
  }

  /// ==================== COMMENTS ====================

  Future<List<Comment>> getComments(String postId) async {
    try {
      final response = await _dio.get('/api/posts/$postId/comments');
      final data = response.data as Map<String, dynamic>;
      return (data['comments'] as List)
          .map((c) => _parseComment(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Comment> addComment({
    required String postId,
    required String content,
    String? replyToCommentId,
  }) async {
    final response = await _dio.post('/api/posts/$postId/comments', data: {
      'content': content,
      if (replyToCommentId != null) 'reply_to_id': replyToCommentId,
    });
    final data = response.data as Map<String, dynamic>;
    return _parseComment(data['comment'] as Map<String, dynamic>);
  }

  /// ==================== PROJECTS ====================

  Future<List<Project>> getProjects() async {
    try {
      final response = await _dio.get('/api/projects');
      final data = response.data as Map<String, dynamic>;
      return (data['projects'] as List)
          .map((p) => _parseProject(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getProjects error: $e');
      return [];
    }
  }

  Future<Project> createProject({
    required String title,
    required String description,
    List<String> images = const [],
    List<String> skills = const [],
    String status = 'idea',
    List<String> universityTags = const [],
  }) async {
    final response = await _dio.post('/api/projects', data: {
      'title': title, 'description': description,
      'images': images, 'skills': skills, 'status': status,
      'university_tags': universityTags,
    });
    final data = response.data as Map<String, dynamic>;
    return _parseProject(data['project'] as Map<String, dynamic>);
  }

  Future<void> incrementProjectViews(String projectId) async {
    try {
      await _dio.post('/api/projects/$projectId/views');
    } catch (_) {}
  }

  Future<Map<String, dynamic>> toggleProjectLike(String projectId) async {
    final response = await _dio.post('/api/projects/$projectId/like');
    return response.data as Map<String, dynamic>;
  }

  Future<bool> deleteProject(String projectId) async {
    try {
      final response = await _dio.delete('/api/projects/$projectId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('deleteProject error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> uploadProjectZip(String projectId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(
      '/api/projects/$projectId/upload-zip',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<String?> getProjectZipUrl(String projectId) async {
    try {
      return '$_baseUrl/api/projects/$projectId/zip-file';
    } catch (e) {
      return null;
    }
  }

  /// Скачать ZIP файл проекта с прогрессом
  /// Возвращает путь к сохранённому файлу
  Future<String?> downloadProjectZipFile({
    required String projectId,
    required String fileName,
    required void Function(int received, int total) onProgress,
  }) async {
    try {
      final url = '$_baseUrl/api/projects/$projectId/zip-file';
      debugPrint('Downloading ZIP file from: $url');

      // Сохраняем в публичную папку Downloads
      final downloadsDir = Directory('/storage/emulated/0/Download/StudentConnect');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final safeFileName = fileName.replaceAll(RegExp(r'[^\w\s\.\-]'), '_');
      final filePath = '${downloadsDir.path}/$safeFileName';

      debugPrint('Saving to: $filePath');

      // Используем Dio с правильными опциями для бинарных файлов
      final response = await _dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint('Download progress: $received / $total (${((received / total) * 100).toStringAsFixed(1)}%)');
            onProgress(received, total);
          }
        },
      );

      // Проверяем что это не JSON ошибка
      final contentType = response.headers.value('content-type') ?? '';
      debugPrint('Content-Type: $contentType');
      
      if (contentType.contains('application/json')) {
        // Сервер вернул JSON (скорее всего ошибку)
        final bytes = <int>[];
        await for (final chunk in response.data!.stream) {
          bytes.addAll(chunk);
        }
        final responseData = String.fromCharCodes(bytes);
        debugPrint('Server returned JSON instead of file: $responseData');
        throw Exception('Сервер вернул ошибку: $responseData');
      }

      // Записываем файл
      final file = File(filePath);
      final sink = file.openWrite();
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
      }
      await sink.close();
      
      final fileSize = await file.length();
      debugPrint('File downloaded successfully: $fileSize bytes');
      
      if (fileSize == 0) {
        throw Exception('Файл пустой (0 байт)');
      }
      
      return filePath;
    } catch (e) {
      debugPrint('Download ZIP error: $e');
      rethrow;
    }
  }

  /// ==================== CHATS ====================

  Future<List<Map<String, dynamic>>> getChats() async {
    try {
      final response = await _dio.get('/api/chats');
      final data = response.data as Map<String, dynamic>;
      return (data['chats'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('getChats error: $e');
      return [];
    }
  }

  Future<String> createChat(String otherUserId) async {
    final response = await _dio.post('/api/chats', data: {
      'other_user_id': otherUserId,
    });
    final data = response.data as Map<String, dynamic>;
    return data['chat_id'] as String;
  }

  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    try {
      final response = await _dio.get('/api/chats/$chatId/messages');
      final data = response.data as Map<String, dynamic>;
      return (data['messages'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    List<String> attachments = const [],
    String? projectId,
  }) async {
    final response = await _dio.post('/api/chats/$chatId/messages', data: {
      'content': content, 'type': type,
      'attachments': attachments,
      if (projectId != null) 'project_id': projectId,
    });
    
    debugPrint('sendMessage response status: ${response.statusCode}');
    debugPrint('sendMessage response data: ${response.data}');
    
    final data = response.data;
    if (data == null) {
      throw Exception('Сервер вернул пустой ответ');
    }
    
    if (data is! Map<String, dynamic>) {
      throw Exception('Неверный формат ответа сервера: ожидался Map, получен ${data.runtimeType}');
    }
    
    // Проверяем, что message существует и это Map
    final messageData = data['message'];
    if (messageData == null) {
      debugPrint('Warning: message field is null in response: $data');
      throw Exception('Сервер вернул null в поле message');
    }
    
    if (messageData is! Map<String, dynamic>) {
      throw Exception('Неверный формат ответа сервера: message не является Map, это ${messageData.runtimeType}');
    }

    return messageData;
  }

  Future<void> markChatAsRead(String chatId) async {
    try {
      await _dio.post('/api/chats/$chatId/read');
    } catch (_) {}
  }

  /// ==================== FOLLOWS ====================

  Future<bool> toggleFollow(String targetUserId) async {
    final response = await _dio.post('/api/follow/$targetUserId');
    final data = response.data as Map<String, dynamic>;
    return data['is_following'] as bool;
  }

  Future<bool> getFollowStatus(String targetUserId) async {
    try {
      final response = await _dio.get('/api/follow/status/$targetUserId');
      final data = response.data as Map<String, dynamic>;
      return data['is_following'] as bool;
    } catch (e) {
      return false;
    }
  }

  Future<List<User>> getFollowers(String userId) async {
    try {
      final response = await _dio.get('/api/followers/$userId');
      final data = response.data as Map<String, dynamic>;
      return (data['followers'] as List)
          .map((u) => _parseUser(u as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<User>> getFollowing(String userId) async {
    try {
      final response = await _dio.get('/api/following/$userId');
      final data = response.data as Map<String, dynamic>;
      return (data['following'] as List)
          .map((u) => _parseUser(u as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== PARSERS ====================

  User _parseUserFromMessage(Map<String, dynamic> data) {
    final sender = data['sender'] as Map<String, dynamic>?;
    if (sender == null) {
      final name = data['sender_name'] as String?;
      final id = data['sender_id'] as String?;
      if (id != null) {
        cacheUser({'id': id, 'name': name, 'email': data['sender_email'],
          'avatar_url': data['sender_avatar'], 'is_online': data['sender_is_online']});
        return User(
          id: id, name: name ?? 'Пользователь',
          email: data['sender_email'] ?? '',
          avatarUrl: data['sender_avatar'],
          isOnline: (data['sender_is_online'] as int?) == 1,
          createdAt: DateTime.now(), skills: [],
          projectsCount: 0, followersCount: 0, followingCount: 0,
        );
      }
      return User(id: 'unknown', name: 'Пользователь', email: '',
        createdAt: DateTime.now(), skills: [],
        projectsCount: 0, followersCount: 0, followingCount: 0);
    }
    return _parseUser(sender);
  }

  Post _parsePost(Map<String, dynamic> data) {
    // Parse author from joined fields
    final author = User(
      id: data['author_id'] ?? '',
      name: data['author_name'] ?? 'Пользователь',
      email: data['author_email'] ?? '',
      avatarUrl: data['author_avatar'],
      university: data['author_university'],
      isOnline: _toBool(data['author_is_online']),
      createdAt: DateTime.now(),
      skills: _parseStringList(data['author_skills']),
      projectsCount: _toInt(data['author_projects_count']),
      followersCount: _toInt(data['author_followers_count']),
      followingCount: _toInt(data['author_following_count']),
    );
    cacheUser({
      'id': author.id, 'name': author.name, 'email': author.email,
      'avatar_url': author.avatarUrl, 'university': author.university,
      'is_online': author.isOnline ? 1 : 0,
      'skills': data['author_skills'],
    });

    List<String> images = [];
    try { images = List<String>.from(data['images'] is String ? convert.jsonDecode(data['images']) : (data['images'] ?? [])); } catch(_) {}
    List<String> tags = [];
    try { tags = List<String>.from(data['tags'] is String ? convert.jsonDecode(data['tags']) : (data['tags'] ?? [])); } catch(_) {}

    return Post(
      id: data['id'] ?? '',
      author: author,
      content: data['content'],
      images: images,
      tags: tags,
      likesCount: _toInt(data['likes_count']),
      commentsCount: _toInt(data['comments_count']),
      sharesCount: _toInt(data['shares_count']),
      isLiked: _toBool(data['is_liked']),
      createdAt: data['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['created_at'])
          : DateTime.now(),
    );
  }

  Comment _parseComment(Map<String, dynamic> data) {
    final author = User(
      id: data['author_id'] ?? '',
      name: data['author_name'] ?? 'Пользователь',
      email: data['author_email'] ?? '',
      avatarUrl: data['avatar_url'] ?? data['author_avatar'],
      isOnline: _toBool(data['is_online'] ?? data['author_is_online']),
      createdAt: DateTime.now(), skills: [],
      projectsCount: 0, followersCount: 0, followingCount: 0,
    );
    return Comment(
      id: data['id'] ?? '',
      author: author,
      content: data['content'] ?? '',
      likesCount: _toInt(data['likes_count']),
      isLiked: false,
      createdAt: data['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['created_at'])
          : DateTime.now(),
    );
  }

  Project _parseProject(Map<String, dynamic> data) {
    final author = User(
      id: data['author_id'] ?? '',
      name: data['author_name'] ?? 'Пользователь',
      email: data['author_email'] ?? '',
      avatarUrl: data['author_avatar'],
      university: data['author_university'],
      isOnline: _toBool(data['author_is_online']),
      createdAt: DateTime.now(),
      skills: _parseStringList(data['author_skills']),
      projectsCount: _toInt(data['author_projects_count']),
      followersCount: _toInt(data['author_followers_count']),
      followingCount: _toInt(data['author_following_count']),
    );

    List<String> images = [];
    try { images = List<String>.from(data['images'] is String ? convert.jsonDecode(data['images']) : (data['images'] ?? [])); } catch(_) {}
    List<String> skills = [];
    try { skills = List<String>.from(data['skills'] is String ? convert.jsonDecode(data['skills']) : (data['skills'] ?? [])); } catch(_) {}

    return Project(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      author: author,
      images: images,
      skills: skills,
      status: data['status'] ?? 'idea',
      likesCount: _toInt(data['likes_count']),
      commentsCount: _toInt(data['comments_count']),
      viewsCount: _toInt(data['views_count']),
      isLiked: _toBool(data['is_liked']),
      zipFileUrl: data['zip_file_url'],
      zipFileName: data['zip_file_name'],
      zipFileSize: _toInt(data['zip_file_size']),
      createdAt: data['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updated_at'])
          : DateTime.now(),
    );
  }

  List<String> _parseStringList(dynamic data) {
    if (data is String) {
      try { return List<String>.from(convert.jsonDecode(data)); } catch(_) { return []; }
    }
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }
}
