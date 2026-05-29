import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/page_transitions.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../providers/app_providers.dart';
import '../../models/models.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

/// Экран сообщений — стиль Instagram 2025
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Все';

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceDark,
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.backgroundDark,
              scrolledUnderElevation: 0,
              title: const Text(
                'Сообщения',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  iconSize: 24,
                  onPressed: () {
                    Navigator.push(
                      context,
                      slideTransition(const NewChatScreen()),
                    );
                  },
                ),
              ],
            ),

            // Поиск
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: TextField(
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
                  onChanged: _onSearchChanged,
                ),
              ),
            ),

            // Фильтры
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('Все', true),
                      const SizedBox(width: 6),
                      _buildFilterChip('Непрочитанные', false),
                      const SizedBox(width: 6),
                      _buildFilterChip('Онлайн', false),
                    ],
                  ),
                ),
              ),
            ),

            // Список чатов
            chatsAsync.when(
              data: (chats) {
                // Применяем фильтры
                var filteredChats = chats;

                if (_searchQuery.isNotEmpty) {
                  filteredChats = filteredChats.where((chat) {
                    return chat.currentUser.name.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (_selectedFilter == 'Непрочитанные') {
                  filteredChats = filteredChats.where((chat) => chat.unreadCount > 0).toList();
                } else if (_selectedFilter == 'Онлайн') {
                  filteredChats = filteredChats.where((chat) => chat.isOnline).toList();
                }

                if (filteredChats.isEmpty) {
                  return SliverToBoxAdapter(child: _buildEmptyState());
                }
                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 60),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final chat = filteredChats[index];
                        return _buildChatTile(chat, context);
                      },
                      childCount: filteredChats.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) {
                debugPrint('MessagesScreen error: $error');
                return SliverToBoxAdapter(child: _buildEmptyState());
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(Chat chat, BuildContext context) {
    final user = chat.currentUser;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            slideTransition(ChatScreen(chat: chat)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              AvatarWithOnlineIndicator(
                imageUrl: user.avatarUrl,
                radius: 26,
                isOnline: chat.isOnline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          chat.lastMessageTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textDarkSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessagePreview,
                            style: TextStyle(
                              fontSize: 13,
                              color: chat.unreadCount > 0
                                  ? AppColors.textDark
                                  : AppColors.textDarkSecondary,
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${chat.unreadCount}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 250));
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: AppColors.textDarkSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Нет сообщений',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Начните общение с другими студентами',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
