import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../providers/theme_provider.dart';
import 'about_screen.dart';

/// Экран настроек
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Настройки',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Аккаунт
          _buildSection(
            'Аккаунт',
            [
              _buildTile(
                Icons.person_outline,
                'Редактировать профиль',
                onTap: () {},
              ),
              _buildTile(
                Icons.lock_outline,
                'Изменить пароль',
                onTap: () {},
              ),
              _buildTile(
                Icons.notifications_outlined,
                'Уведомления',
                onTap: () {},
              ),
            ],
          ),

          const Divider(height: 1),

          // Приложение
          _buildSection(
            'Приложение',
            [
              // Переключатель темы
              ListTile(
                leading: const Icon(Icons.palette_outlined,
                    size: 22, color: AppColors.textDark),
                title: const Text(
                  'Тема оформления',
                  style: TextStyle(fontSize: 15, color: AppColors.textDark),
                ),
                subtitle: Text(
                  _themeLabels[currentTheme] ?? 'Темная',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textDarkSecondary),
                ),
                trailing: PopupMenuButton<AppThemeMode>(
                  icon: const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.textDarkSecondary),
                  initialValue: currentTheme,
                  color: AppColors.surfaceDark,
                  onSelected: (theme) {
                    ref.read(themeProvider.notifier).setTheme(theme);
                  },
                  itemBuilder: (context) => AppThemeMode.values.map((theme) {
                    return PopupMenuItem(
                      value: theme,
                      child: Row(
                        children: [
                          if (theme == currentTheme)
                            const Icon(Icons.check,
                                size: 18, color: AppColors.primary),
                          if (theme == currentTheme) const SizedBox(width: 8),
                          Text(_themeLabels[theme] ?? ''),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              _buildTile(
                Icons.language_outlined,
                'Язык',
                subtitle: 'Русский',
                onTap: () {},
              ),
              _buildTile(
                Icons.shield_outlined,
                'Конфиденциальность',
                onTap: () {},
              ),
              _buildTile(
                Icons.help_outline,
                'Помощь',
                onTap: () {},
              ),
              _buildTile(
                Icons.info_outline,
                'О приложении',
                subtitle: 'Версия 1.0.0',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const Divider(height: 1),

          // Выход
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _handleLogout(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Выйти из аккаунта',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDarkSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildTile(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22, color: AppColors.textDark),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textDark,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDarkSecondary,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
        color: AppColors.textDarkSecondary,
      ),
      onTap: onTap,
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Выйти',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Отмена',
              style: TextStyle(color: AppColors.textDarkSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Выйти',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authStatusProvider.notifier).logout();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }
}

const _themeLabels = {
  AppThemeMode.dark: 'Темная',
  AppThemeMode.light: 'Светлая',
  AppThemeMode.system: 'Системная',
};
