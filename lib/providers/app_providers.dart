import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

/// Статус авторизации
enum AuthStatus { initial, loading, authenticated, unauthenticated }

// ==================== AUTH ====================

final authStatusProvider =
    StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthStatus> {
  AuthNotifier() : super(AuthStatus.initial) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    state = AuthStatus.loading;
    try {
      final authenticated = ApiService.instance.isAuthenticated;
      if (authenticated) {
        // Проверяем что токен валидный
        await ApiService.instance.getCurrentUser();
        state = AuthStatus.authenticated;
        return;
      }
    } catch (_) {}
    state = AuthStatus.unauthenticated;
  }

  Future<bool> login(String email, String password) async {
    state = AuthStatus.loading;
    try {
      await ApiService.instance.login(email, password);
      state = AuthStatus.authenticated;
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      state = AuthStatus.unauthenticated;
      return false;
    }
  }

  Future<bool> register({
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
    state = AuthStatus.loading;
    try {
      await ApiService.instance.register(
        name: name, email: email, password: password,
        university: university, faculty: faculty, course: course,
        bio: bio, skills: skills, avatarUrl: avatarUrl,
      );
      state = AuthStatus.authenticated;
      return true;
    } catch (e) {
      debugPrint('Register error: $e');
      state = AuthStatus.unauthenticated;
      return false;
    }
  }

  Future<void> logout() async {
    state = AuthStatus.loading;
    await ApiService.instance.logout();
    state = AuthStatus.unauthenticated;
  }
}

// ==================== CURRENT USER ====================

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, User?>((ref) {
  return CurrentUserNotifier();
});

class CurrentUserNotifier extends StateNotifier<User?> {
  Timer? _pollTimer;

  CurrentUserNotifier() : super(null) {
    _loadUser();
    _startPolling();
  }

  Future<void> _loadUser() async {
    try {
      final data = await ApiService.instance.getCurrentUser();
      state = data['user'] as User?;
    } catch (e) {
      debugPrint('CurrentUserNotifier load error: $e');
      state = null;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (ApiService.instance.isAuthenticated) {
        _loadUser();
      }
    });
  }

  Future<void> refresh() async {
    debugPrint('CurrentUserNotifier: refresh()');
    state = null;
    await _loadUser();
  }

  void updateUser(User user) {
    state = user;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

// ==================== POSTS ====================

final postsStreamProvider = StreamProvider<List<Post>>((ref) {
  final controller = StreamController<List<Post>>();

  Future<void> fetch() async {
    try {
      final posts = await ApiService.instance.getPosts();
      debugPrint('postsStreamProvider: received ${posts.length} posts');
      if (!controller.isClosed) {
        if (posts.isEmpty) {
          debugPrint('postsStreamProvider: using mock posts');
          controller.add(_safeMockPosts());
        } else {
          controller.add(posts);
        }
      }
    } catch (e) {
      debugPrint('postsStreamProvider error: $e');
      if (!controller.isClosed) {
        debugPrint('postsStreamProvider: using mock posts as fallback');
        controller.add(_safeMockPosts());
      }
    }
  }

  fetch();
  final timer = Timer.periodic(const Duration(seconds: 10), (_) => fetch());
  controller.onCancel = () => timer.cancel();

  return controller.stream;
});

/// Провайдер постов от подписок (для главной страницы)
final followingPostsStreamProvider = StreamProvider<List<Post>>((ref) {
  final controller = StreamController<List<Post>>();

  Future<void> fetch() async {
    try {
      final currentUser = ref.watch(currentUserProvider);
      if (currentUser == null) {
        if (!controller.isClosed) controller.add([]);
        return;
      }

      // Получаем список подписок
      final following = await ApiService.instance.getFollowing(currentUser.id);
      final followingIds = following.map((u) => u.id).toSet();
      debugPrint('followingPostsStreamProvider: following ${followingIds.length} users');

      // Получаем все посты
      final posts = await ApiService.instance.getPosts();
      debugPrint('followingPostsStreamProvider: received ${posts.length} total posts');
      
      // Фильтруем только от подписок + свои посты
      final filteredPosts = posts.where((p) => 
        followingIds.contains(p.author.id) || p.author.id == currentUser.id).toList();
      
      debugPrint('followingPostsStreamProvider: filtered ${filteredPosts.length} posts');

      if (!controller.isClosed) {
        controller.add(filteredPosts.isEmpty ? _safeMockPosts() : filteredPosts);
      }
    } catch (e) {
      debugPrint('followingPostsStreamProvider error: $e');
      if (!controller.isClosed) controller.add(_safeMockPosts());
    }
  }

  fetch();
  final timer = Timer.periodic(const Duration(seconds: 10), (_) => fetch());
  controller.onCancel = () => timer.cancel();

  return controller.stream;
});

List<Post> _safeMockPosts() {
  try {
    return MockPosts.posts;
  } catch (e) {
    debugPrint('MockPosts fallback error: $e');
    return [];
  }
}

final postsProvider = StateProvider<List<Post>>((ref) {
  return MockPosts.posts;
});

// ==================== POST LIKES ====================

final postLikesProvider =
    StateNotifierProvider.family<PostLikesNotifier, PostLikesState, String>(
  (ref, postId) => PostLikesNotifier(postId),
);

class PostLikesState {
  final bool isLikedByCurrentUser;
  final int totalLikes;
  const PostLikesState({required this.isLikedByCurrentUser, required this.totalLikes});
  PostLikesState copyWith({bool? isLikedByCurrentUser, int? totalLikes}) {
    return PostLikesState(
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      totalLikes: totalLikes ?? this.totalLikes,
    );
  }
}

class PostLikesNotifier extends StateNotifier<PostLikesState> {
  final String postId;
  PostLikesNotifier(this.postId)
      : super(const PostLikesState(isLikedByCurrentUser: false, totalLikes: 0));

  Future<void> toggleLike(String currentUserId) async {
    final wasLiked = state.isLikedByCurrentUser;
    state = PostLikesState(
      isLikedByCurrentUser: !wasLiked,
      totalLikes: wasLiked ? state.totalLikes - 1 : state.totalLikes + 1,
    );
    try {
      final result = await ApiService.instance.toggleLike(postId);
      state = PostLikesState(
        isLikedByCurrentUser: result['is_liked'] as bool,
        totalLikes: result['likes_count'] as int,
      );
    } catch (e) {
      state = PostLikesState(isLikedByCurrentUser: wasLiked, totalLikes: state.totalLikes);
    }
  }
}

// ==================== PROJECTS ====================

final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final controller = StreamController<List<Project>>();

  Future<void> fetch() async {
    try {
      final projects = await ApiService.instance.getProjects();
      debugPrint('projectsStreamProvider: received ${projects.length} projects');
      for (var p in projects) {
        debugPrint('  - Project: ${p.title}, author: ${p.author.name}, university: ${p.author.university}');
      }
      if (!controller.isClosed) {
        controller.add(projects.isEmpty ? MockProjects.projects : projects);
      }
    } catch (e) {
      debugPrint('projectsStreamProvider error: $e');
      if (!controller.isClosed) controller.add(MockProjects.projects);
    }
  }

  fetch();
  final timer = Timer.periodic(const Duration(seconds: 5), (_) => fetch());
  controller.onCancel = () => timer.cancel();

  return controller.stream;
});

final projectsProvider = StateProvider<List<Project>>((ref) {
  return MockProjects.projects;
});

// ==================== CHATS ====================

final chatsStreamProvider = StreamProvider<List<Chat>>((ref) {
  final controller = StreamController<List<Chat>>();

  Future<void> fetch() async {
    try {
      if (!ApiService.instance.isAuthenticated) {
        if (!controller.isClosed) controller.add([]);
        return;
      }
      final chatDataList = await ApiService.instance.getChats();
      final chats = chatDataList.map((data) => _parseChat(data)).toList();
      if (!controller.isClosed) controller.add(chats);
    } catch (e) {
      debugPrint('chatsStreamProvider error: $e');
      if (!controller.isClosed) controller.add([]);
    }
  }

  fetch();
  final timer = Timer.periodic(const Duration(seconds: 3), (_) => fetch());
  controller.onCancel = () => timer.cancel();

  return controller.stream;
});

final chatsProvider = StateProvider<List<Chat>>((ref) {
  return [];
});

Chat _parseChat(Map<String, dynamic> data) {
  final otherUser = data['other_user'] as Map<String, dynamic>?;
  final user = otherUser != null ? _parseUserFromMap(otherUser)
      : User(id: '', name: 'Неизвестный', email: '', createdAt: DateTime.now(), skills: [], projectsCount: 0, followersCount: 0, followingCount: 0);

  final lastMsgData = data['last_message'] as Map<String, dynamic>?;
  Message? lastMessage;
  if (lastMsgData != null) {
    final sender = lastMsgData['sender'] as Map<String, dynamic>?;
    final senderUser = sender != null ? User(
      id: sender['id'] ?? '', name: sender['name'] ?? '',
      email: sender['email'] ?? '', avatarUrl: sender['avatar_url'],
      isOnline: _toBool(sender['is_online']),
      createdAt: DateTime.now(), skills: [],
      projectsCount: 0, followersCount: 0, followingCount: 0,
    ) : user;

    lastMessage = Message(
      id: lastMsgData['id'] ?? '',
      chatId: data['id'] ?? '',
      sender: senderUser,
      content: lastMsgData['content'] ?? '',
      type: _messageTypeFromString(lastMsgData['type'] ?? 'text'),
      isRead: false,
      createdAt: lastMsgData['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(lastMsgData['created_at'])
          : DateTime.now(),
    );
  }

  return Chat(
    id: data['id'] ?? '',
    currentUser: user,
    lastMessage: lastMessage,
    unreadCount: data['unread_count'] ?? 0,
    isOnline: _toBool(data['is_online']),
    lastMessageAt: data['last_message_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['last_message_at'])
        : null,
    createdAt: data['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['created_at'])
        : DateTime.now(),
  );
}

/// Преобразуем int или bool в bool
bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  return false;
}

// ==================== MESSAGES ====================

final messagesStreamProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  final controller = StreamController<List<Message>>();

  Future<void> fetch() async {
    try {
      final msgDataList = await ApiService.instance.getMessages(chatId);
      final messages = msgDataList.map((data) => _parseMessage(data, chatId)).toList();
      if (!controller.isClosed) controller.add(messages);
    } catch (e) {
      debugPrint('messagesStreamProvider error: $e');
      if (!controller.isClosed) controller.add([]);
    }
  }

  fetch();
  final timer = Timer.periodic(const Duration(seconds: 2), (_) => fetch());
  controller.onCancel = () => timer.cancel();

  return controller.stream;
});

final messagesProvider =
    StateProvider.family<List<Message>, String>((ref, chatId) {
  return [];
});

Message _parseMessage(Map<String, dynamic> data, String chatId) {
  final sender = data['sender'] as Map<String, dynamic>?;
  final senderUser = sender != null ? User(
    id: sender['id'] ?? '',
    name: sender['name'] ?? 'Пользователь',
    email: sender['email'] ?? '',
    avatarUrl: sender['avatar_url'],
    isOnline: _toBool(sender['is_online']),
    createdAt: DateTime.now(), skills: [],
    projectsCount: 0, followersCount: 0, followingCount: 0,
  ) : User(
    id: data['sender_id'] ?? '',
    name: data['sender_name'] ?? 'Пользователь',
    email: data['sender_email'] ?? '',
    avatarUrl: data['sender_avatar'],
    isOnline: _toBool(data['sender_is_online']),
    createdAt: DateTime.now(), skills: [],
    projectsCount: 0, followersCount: 0, followingCount: 0,
  );

  // is_read может быть bool или int (из SQLite)
  final isReadRaw = data['is_read'];
  final isRead = isReadRaw == true || isReadRaw == 1;

  // created_at может быть int (ms) или Timestamp
  DateTime createdAt;
  final createdAtRaw = data['created_at'];
  if (createdAtRaw is int) {
    createdAt = createdAtRaw > 1000000000000
        ? DateTime.fromMillisecondsSinceEpoch(createdAtRaw)
        : DateTime.fromMillisecondsSinceEpoch(createdAtRaw * 1000);
  } else {
    createdAt = DateTime.now();
  }

  return Message(
    id: data['id'] ?? '',
    chatId: chatId,
    sender: senderUser,
    content: data['content'] ?? '',
    type: _messageTypeFromString(data['type'] ?? 'text'),
    isRead: isRead,
    createdAt: createdAt,
    readAt: data['read_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['read_at'] as int)
        : null,
  );
}

// ==================== COMMENTS ====================

final commentsStreamProvider =
    StreamProvider.family<List<Comment>, String>((ref, postId) {
  final controller = StreamController<List<Comment>>();

  Future<void> fetch() async {
    try {
      final comments = await ApiService.instance.getComments(postId);
      if (!controller.isClosed) controller.add(comments);
    } catch (e) {
      debugPrint('commentsStreamProvider error: $e');
      if (!controller.isClosed) controller.add([]);
    }
  }

  fetch();
  final timer = Timer.periodic(const Duration(seconds: 5), (_) => fetch());
  controller.onCancel = () => timer.cancel();

  return controller.stream;
});

final postCommentsProvider =
    StateNotifierProvider.family<PostCommentsNotifier, List<Comment>, String>(
  (ref, postId) => PostCommentsNotifier(postId),
);

class PostCommentsNotifier extends StateNotifier<List<Comment>> {
  final String postId;
  PostCommentsNotifier(this.postId) : super([]) {
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await ApiService.instance.getComments(postId);
      state = comments;
    } catch (e) {
      debugPrint('PostCommentsNotifier load error: $e');
    }
  }

  Future<void> addComment(String content) async {
    try {
      final comment = await ApiService.instance.addComment(
        postId: postId, content: content,
      );
      state = [...state, comment];
    } catch (e) {
      debugPrint('addComment error: $e');
    }
  }

  void toggleLike(int index) {
    // TODO: Implement comment likes via API
    final comments = List<Comment>.from(state);
    final c = comments[index];
    comments[index] = Comment(
      id: c.id, author: c.author, content: c.content,
      likesCount: c.isLiked ? c.likesCount - 1 : c.likesCount + 1,
      isLiked: !c.isLiked, createdAt: c.createdAt,
    );
    state = comments;
  }

  void deleteComment(int index) {
    state = [...state]..removeAt(index);
  }
}

// ==================== FOLLOW ====================

final followStatusProvider =
    StateNotifierProvider.family<FollowStatusNotifier, bool, String>(
  (ref, userId) => FollowStatusNotifier(userId),
);

class FollowStatusNotifier extends StateNotifier<bool> {
  final String targetUserId;
  FollowStatusNotifier(this.targetUserId) : super(false) {
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      state = await ApiService.instance.getFollowStatus(targetUserId);
    } catch (_) {
      state = false;
    }
  }

  Future<void> toggleFollow(String currentUserId) async {
    final wasFollowing = state;
    state = !state;
    try {
      state = await ApiService.instance.toggleFollow(targetUserId);
    } catch (e) {
      state = wasFollowing;
    }
  }
}

// ==================== UI PROVIDERS ====================

final selectedProjectProvider = StateProvider<Project?>((ref) {
  return null;
});

final isCreatingProjectProvider = StateProvider<bool>((ref) {
  return false;
});

final searchQueryProvider = StateProvider<String>((ref) {
  return '';
});

final searchResultsProvider = Provider<List<dynamic>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  if (query.isEmpty) return [];

  final posts = ref.watch(postsProvider);
  final projects = ref.watch(projectsProvider);

  final results = <dynamic>[];
  results.addAll(projects.where((p) =>
      p.title.toLowerCase().contains(query) ||
      p.description.toLowerCase().contains(query) ||
      p.skills.any((s) => s.toLowerCase().contains(query))));
  results.addAll(posts.where((p) =>
      p.content?.toLowerCase().contains(query) ?? false ||
      p.tags.any((t) => t.toLowerCase().contains(query))));

  return results;
});

// ==================== HELPERS ====================

User _parseUserFromMap(Map<String, dynamic> data) {
  final skillsRaw = data['skills'];
  List<String> skills = [];
  if (skillsRaw is String) {
    try { skills = List<String>.from(jsonDecode(skillsRaw)); } catch(_) {}
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
    projectsCount: data['projects_count'] ?? 0,
    followersCount: data['followers_count'] ?? 0,
    followingCount: data['following_count'] ?? 0,
    isOnline: _toBool(data['is_online']),
    lastSeen: data['last_seen'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['last_seen'])
        : null,
    createdAt: data['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['created_at'])
        : DateTime.now(),
  );
}

MessageType _messageTypeFromString(String type) {
  switch (type) {
    case 'image': return MessageType.image;
    case 'file': return MessageType.file;
    case 'project': return MessageType.project;
    case 'system': return MessageType.system;
    default: return MessageType.text;
  }
}
