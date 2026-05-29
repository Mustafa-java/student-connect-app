import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/page_transitions.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'chat_screen.dart';

/// Экран выбора пользователя для начала чата
class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final users = await ApiService.instance.getAllUsers();
      setState(() { _users = users.map((u) => _userToMap(u)).toList(); _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Ошибка загрузки: $e'; _isLoading = false; });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) { _loadUsers(); return; }
    setState(() => _isLoading = true);
    try {
      final users = await ApiService.instance.searchUsers(query);
      setState(() => _users = users.map((u) => _userToMap(u)).toList());
    } catch (e) { setState(() => _isLoading = false); }
  }

  Map<String, dynamic> _userToMap(User u) {
    return {
      'id': u.id, 'name': u.name, 'email': u.email,
      'avatarUrl': u.avatarUrl, 'bio': u.bio, 'university': u.university,
      'faculty': u.faculty, 'course': u.course, 'skills': u.skills,
      'projectsCount': u.projectsCount, 'followersCount': u.followersCount,
      'followingCount': u.followingCount, 'isOnline': u.isOnline,
      'lastSeen': u.lastSeen, 'createdAt': u.createdAt,
    };
  }

  Future<void> _startChat(Map<String, dynamic> user) async {
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      final chatId = await ApiService.instance.createChat(user['id']);
      if (!mounted) return;
      Navigator.pop(context);

      final otherUser = User(
        id: user['id'], name: user['name'] ?? 'Пользователь',
        email: user['email'] ?? '', avatarUrl: user['avatarUrl'],
        bio: user['bio'], university: user['university'],
        faculty: user['faculty'], course: user['course'],
        skills: user['skills'] is List ? List<String>.from(user['skills']) : [],
        projectsCount: user['projectsCount'] ?? 0,
        followersCount: user['followersCount'] ?? 0,
        followingCount: user['followingCount'] ?? 0,
        isOnline: user['isOnline'] ?? false,
        lastSeen: user['lastSeen'],
        createdAt: user['createdAt'] is DateTime ? user['createdAt'] : DateTime.now(),
      );

      final chat = Chat(
        id: chatId, currentUser: otherUser, lastMessage: null,
        unreadCount: 0, isOnline: otherUser.isOnline,
        lastMessageAt: null, createdAt: DateTime.now(),
      );

      Navigator.pushReplacement(context, slideTransition(ChatScreen(chat: chat)));
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Новый чат',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Поле поиска
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по имени...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),

          // Список пользователей
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.textDarkSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _error,
                              style: TextStyle(
                                color: AppColors.textDarkSecondary,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadUsers,
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : _users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_off_outlined,
                                  size: 60,
                                  color: AppColors.textDarkSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Пользователи не найдены',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDarkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return _buildUserTile(user);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final userObj = User(
      id: user['id'],
      name: user['name'] ?? 'Пользователь',
      email: user['email'] ?? '',
      avatarUrl: user['avatarUrl'],
      bio: user['bio'],
      university: user['university'],
      isOnline: user['isOnline'] ?? false,
      lastSeen: user['lastSeen'] != null
          ? (user['lastSeen'] as dynamic).toDate()
          : null,
      createdAt: DateTime.now(),
      skills: user['skills'] != null ? List<String>.from(user['skills']) : [],
      projectsCount: 0,
      followersCount: 0,
      followingCount: 0,
      faculty: null,
      course: null,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _startChat(user),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              AvatarWithOnlineIndicator(
                imageUrl: user['avatarUrl'],
                radius: 24,
                isOnline: user['isOnline'] ?? false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'Пользователь',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user['university'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user['university'],
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDarkSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chat_bubble_outline,
                size: 20,
                color: AppColors.textDarkSecondary,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 200));
  }
}
