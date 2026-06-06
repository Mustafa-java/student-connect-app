import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'other_user_profile_screen.dart';

/// Экран просмотра подписчиков или подписок
class FollowersScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final bool showFollowers; // true = подписчики, false = подписки

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.showFollowers = true,
  });

  @override
  ConsumerState<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends ConsumerState<FollowersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User> _followers = [];
  List<User> _following = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.showFollowers ? 0 : 1,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final followers = await ApiService.instance.getFollowers(widget.userId);
      final following = await ApiService.instance.getFollowing(widget.userId);

      if (mounted) {
        setState(() {
          _followers = followers;
          _following = following;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow(User user) async {
    try {
      final isFollowing = await ApiService.instance.toggleFollow(user.id);

      // Обновляем список
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFollowing ? 'Вы подписались' : 'Вы отписались'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          widget.userName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.textDark,
          unselectedLabelColor: AppColors.textDarkSecondary,
          tabs: [
            Tab(text: '${_followers.length} подписчиков'),
            Tab(text: '${_following.length} подписок'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(color: AppColors.textDarkSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserList(_followers, isFollowersTab: true),
                    _buildUserList(_following, isFollowersTab: false),
                  ],
                ),
    );
  }

  Widget _buildUserList(List<User> users, {required bool isFollowersTab}) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFollowersTab ? Icons.people_outline : Icons.person_add_outlined,
              size: 64,
              color: AppColors.textDarkSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isFollowersTab ? 'Нет подписчиков' : 'Нет подписок',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDarkSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDark,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserTile(user);
        },
      ),
    );
  }

  Widget _buildUserTile(User user) {
    final currentUser = ref.watch(currentUserProvider);
    final isCurrentUser = currentUser?.id == user.id;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: GestureDetector(
        onTap: () => _openProfile(user),
        child: CustomAvatar(
          radius: 24,
          imageUrl: user.avatarUrl,
          hasStoryGradient: false,
        ),
      ),
      title: GestureDetector(
        onTap: () => _openProfile(user),
        child: Text(
          user.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ),
      subtitle: user.university != null
          ? Text(
              user.university!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDarkSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: isCurrentUser
          ? null
          : SizedBox(
              width: 100,
              height: 32,
              child: Consumer(
                builder: (context, ref, _) {
                  // Проверяем статус подписки
                  return FutureBuilder<bool>(
                    future: ApiService.instance.getFollowStatus(user.id),
                    builder: (context, snapshot) {
                      final isFollowing = snapshot.data ?? false;

                      return OutlinedButton(
                        onPressed: () => _toggleFollow(user),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isFollowing
                              ? AppColors.textDark
                              : AppColors.primary,
                          backgroundColor: isFollowing
                              ? Colors.transparent
                              : AppColors.primary.withOpacity(0.1),
                          side: BorderSide(
                            color: isFollowing
                                ? AppColors.divider
                                : AppColors.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(
                          isFollowing ? 'Отписаться' : 'Подписаться',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  void _openProfile(User user) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser?.id == user.id) {
      // Мой профиль - закрываем этот экран, возвращаемся к ProfileScreen
      Navigator.pop(context);
    } else {
      // Чужой профиль
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherUserProfileScreen(user: user),
        ),
      );
    }
  }
}
