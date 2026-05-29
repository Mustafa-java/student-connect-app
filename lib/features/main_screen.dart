import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'messages/messages_screen.dart';
import 'profile/profile_screen.dart';

/// Главный экран с нижней навигацией — стиль Instagram 2025
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Подсчитываем общее количество непрочитанных
    int totalUnread = 0;
    final chatsAsync = ref.watch(chatsStreamProvider);
    chatsAsync.when(
      data: (chats) {
        totalUnread = chats.fold(0, (sum, chat) => sum + chat.unreadCount);
      },
      loading: () {},
      error: (_, __) {},
    );

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(
            top: BorderSide(
              color: AppColors.divider.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined),
                _buildNavItem(1, Icons.search_rounded, Icons.search_outlined),
                _buildNavItem(
                  2,
                  Icons.send_rounded,
                  Icons.send_outlined,
                  badge: totalUnread > 0 ? totalUnread : null,
                ),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outline),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon, {
    int? badge,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: isSelected ? 26 : 25,
              color:
                  isSelected ? AppColors.textDark : AppColors.textDarkSecondary,
            ),
            if (badge != null && badge > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
