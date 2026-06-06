import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/page_transitions.dart';
import '../../features/messages/chat_screen.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';

class MyTeamsScreen extends ConsumerStatefulWidget {
  const MyTeamsScreen({super.key});

  @override
  ConsumerState<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends ConsumerState<MyTeamsScreen> {
  late Future<List<Map<String, dynamic>>> _teamsFuture;

  @override
  void initState() {
    super.initState();
    _teamsFuture = ApiService.instance.getMyTeams();
  }

  void _refreshTeams() {
    setState(() {
      _teamsFuture = ApiService.instance.getMyTeams();
    });
  }

  void _openTeamChat(Map<String, dynamic> team, User? currentUser) {
    final chatId = team['chat_id']?.toString();
    if (chatId == null || chatId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('У этой команды пока нет чата'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Пытаемся найти уже загруженный чат из chatsStreamProvider
    final allChats = ref.read(chatsStreamProvider).valueOrNull ?? [];
    final existingChat = allChats.where((c) => c.id == chatId).firstOrNull;

    if (existingChat != null) {
      Navigator.push(context, slideTransition(ChatScreen(chat: existingChat)));
      return;
    }

    // Если чат ещё не загружен — создаём вручную
    final teamName = team['name']?.toString() ?? 'Командный чат';
    final members = team['members']?.toString() ?? '';
    final chat = Chat(
      id: chatId,
      currentUser: User(
        id: currentUser?.id ?? chatId,
        name: currentUser?.name ?? teamName,
        email: currentUser?.email ?? '',
        avatarUrl: currentUser?.avatarUrl,
        createdAt: currentUser?.createdAt ?? DateTime.now(),
      ),
      createdAt: _parseDate(team['created_at']),
      participantIds: members,
      isGroup: true,
      title: teamName,
    );

    Navigator.push(context, slideTransition(ChatScreen(chat: chat)));
  }

  void _showTeamInfo(Map<String, dynamic> team) {
    final teamName = team['name']?.toString() ?? 'Команда';
    final memberCount = _membersCount(team['members']);
    final createdAt = _parseDate(team['created_at']);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary,
                child:
                    Icon(Icons.groups_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                teamName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$memberCount участников',
                style: const TextStyle(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Создана ${createdAt.day}.${createdAt.month}.${createdAt.year}',
                style: TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _leaveTeam(Map<String, dynamic> team) async {
    final teamName = team['name']?.toString() ?? 'команду';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Покинуть команду?',
            style: TextStyle(color: AppColors.textDark)),
        content: Text(
          'Вы покинете "$teamName" и больше не будете видеть командный чат.',
          style: const TextStyle(color: AppColors.textDarkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Покинуть'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final teamId = team['id']?.toString();
    if (teamId == null || teamId.isEmpty) return;

    final success = await ApiService.instance.leaveTeam(teamId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            success ? 'Вы покинули команду' : 'Не удалось покинуть команду'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );

    if (success) _refreshTeams();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final chatsAsync = ref.watch(chatsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Команды'),
        backgroundColor: AppColors.backgroundDark,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _teamsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final teams = snapshot.data ?? [];
          if (teams.isEmpty) return _empty();

          // Все загруженные чаты для сопоставления с командами
          final allChats = chatsAsync.valueOrNull ?? [];

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final team = teams[index];
              return _buildTeamCard(team, allChats, currentUser);
            },
          );
        },
      ),
    );
  }

  Widget _buildTeamCard(
    Map<String, dynamic> team,
    List<Chat> allChats,
    User? currentUser,
  ) {
    final teamName = team['name']?.toString() ?? 'Команда';
    final memberCount = _membersCount(team['members']);
    final chatId = team['chat_id']?.toString();

    // Ищем соответствующий чат для отображения последнего сообщения
    final matchedChat = chatId != null
        ? allChats.where((c) => c.id == chatId).firstOrNull
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openTeamChat(team, currentUser),
        onLongPress: () => _showTeamInfo(team),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.groups_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            teamName,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (matchedChat != null && matchedChat.unreadCount > 0)
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
                              '${matchedChat.unreadCount}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$memberCount участников',
                      style: const TextStyle(
                        color: AppColors.textDarkSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (matchedChat != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        matchedChat.lastMessagePreview,
                        style: const TextStyle(
                          color: AppColors.textDarkSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      Text(
                        'Нажмите, чтобы открыть чат',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textDarkSecondary),
                color: AppColors.surfaceDark,
                onSelected: (value) {
                  if (value == 'info') _showTeamInfo(team);
                  if (value == 'leave') _leaveTeam(team);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.textDarkSecondary, size: 18),
                        SizedBox(width: 8),
                        Text('О команде',
                            style: TextStyle(color: AppColors.textDark)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppColors.error, size: 18),
                        SizedBox(width: 8),
                        Text('Покинуть',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _membersCount(dynamic members) {
    if (members == null) return 0;
    final text = members
        .toString()
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '');
    return text.split(',').where((e) => e.trim().isNotEmpty).length;
  }

  DateTime _parseDate(dynamic value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      final intValue = int.tryParse(value);
      if (intValue != null)
        return DateTime.fromMillisecondsSinceEpoch(intValue);
    }
    return DateTime.now();
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.groups_outlined,
              size: 64, color: AppColors.textDarkSecondary),
          const SizedBox(height: 12),
          Text('Команд пока нет',
              style: TextStyle(color: AppColors.textDarkSecondary)),
        ],
      ),
    );
  }
}
