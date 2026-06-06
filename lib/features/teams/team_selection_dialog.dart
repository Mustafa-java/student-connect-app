import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

/// Диалог выбора команды или создания новой для приглашения пользователя
class TeamSelectionDialog extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const TeamSelectionDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<TeamSelectionDialog> createState() =>
      _TeamSelectionDialogState();
}

class _TeamSelectionDialogState extends ConsumerState<TeamSelectionDialog> {
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;
  final _teamNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await ApiService.instance.getMyTeams();
      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _inviteToTeam(String teamId) async {
    try {
      await ApiService.instance.inviteToTeam(
        teamId: teamId,
        userId: widget.userId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.userName} приглашен в команду'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось пригласить в команду'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _createAndInvite() async {
    final teamName = _teamNameController.text.trim();
    if (teamName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название команды')),
      );
      return;
    }

    try {
      final result = await ApiService.instance.createTeam(
        name: teamName,
        memberIds: [widget.userId],
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Команда "$teamName" создана'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось создать команду'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Пригласить в команду',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.userName,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDarkSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_teams.isEmpty)
              _buildCreateTeamForm()
            else
              _buildTeamsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Выберите команду:',
          style: TextStyle(fontSize: 14, color: AppColors.textDarkSecondary),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _teams.length,
            itemBuilder: (context, index) {
              final team = _teams[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.groups, color: AppColors.primary),
                title: Text(
                  team['name'] ?? 'Команда',
                  style: const TextStyle(color: AppColors.textDark),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _inviteToTeam(team['id']),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        _buildCreateTeamForm(),
      ],
    );
  }

  Widget _buildCreateTeamForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Или создайте новую команду:',
          style: TextStyle(fontSize: 14, color: AppColors.textDarkSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _teamNameController,
          style: const TextStyle(color: AppColors.textDark),
          decoration: const InputDecoration(
            hintText: 'Название команды',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _createAndInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Создать и пригласить'),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> showTeamSelectionDialog({
  required BuildContext context,
  required String userId,
  required String userName,
}) {
  return showDialog(
    context: context,
    builder: (context) => TeamSelectionDialog(
      userId: userId,
      userName: userName,
    ),
  );
}
