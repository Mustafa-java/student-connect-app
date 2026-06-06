import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/page_transitions.dart';
import '../../features/messages/chat_screen.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class MyTeamsScreen extends StatefulWidget {
  const MyTeamsScreen({super.key});

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen> {
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

  void _openTeamChat(Map<String, dynamic> team) {
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

    final teamName = team['name']?.toString() ?? 'Командный чат';
    final members = team['members']?.toString() ?? '';
    final chat = Chat(
      id: chatId,
      currentUser: User(
        id: chatId,
        name: teamName,
        email: '',
        createdAt: DateTime.now(),
      ),
      createdAt: _parseDate(team['created_at']),
      participantIds: members,
      isGroup: true,
      title: teamName,
    );

    Navigator.push(context, slideTransition(ChatScreen(chat: chat)));
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
          style: TextStyle(color: AppColors.textDarkSecondary),
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
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final team = teams[index];
              final members = _membersCount(team['members']);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openTeamChat(team),
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
                          child:
                              Icon(Icons.groups_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team['name'] ?? 'Команда',
                                style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text('$members участников',
                                  style: TextStyle(
                                      color: AppColors.textDarkSecondary,
                                      fontSize: 12)),
                              const SizedBox(height: 6),
                              Text('Нажмите, чтобы открыть чат',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert,
                              color: AppColors.textDarkSecondary),
                          color: AppColors.surfaceDark,
                          onSelected: (value) {
                            if (value == 'leave') _leaveTeam(team);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'leave',
                              child: Row(
                                children: [
                                  Icon(Icons.logout,
                                      color: AppColors.error, size: 18),
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
            },
          );
        },
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
