import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';

/// Экран "О приложении"
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'О приложении',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Логотип/Иконка
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Название
            const Text(
              'Student Connect',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'СтудХаб',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDarkSecondary,
              ),
            ),

            const SizedBox(height: 4),

            // Версия
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Версия 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Описание
            const Text(
              'Мобильное приложение для студентов, объединяющее социальную сеть, портфолио проектов, мессенджер и поиск единомышленников.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Информационные карточки
            _buildInfoCard(
              icon: Icons.person_rounded,
              title: 'Автор',
              subtitle: 'Улугбек уулу Мустафа',
              onTap: () {},
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.email_rounded,
              title: 'Email',
              subtitle: 'mustafa@student.com',
              onTap: () => _launchEmail('mustafa@student.com'),
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.code_rounded,
              title: 'GitHub',
              subtitle: 'github.com/Mustafa-java/student-connect-app',
              onTap: () => _launchURL('https://github.com/Mustafa-java/student-connect-app'),
            ),

            const SizedBox(height: 32),

            // Технологии
            const Text(
              'Технологии',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildTechChip('Flutter 3.41.6'),
                _buildTechChip('Dart 3.0+'),
                _buildTechChip('Node.js'),
                _buildTechChip('Express'),
                _buildTechChip('PostgreSQL'),
                _buildTechChip('Render.com'),
                _buildTechChip('Riverpod'),
                _buildTechChip('Material Design 3'),
              ],
            ),

            const SizedBox(height: 32),

            // Дипломная работа
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.school_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Дипломная работа',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '2026',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Copyright
            Text(
              '© 2026 Student Connect',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDarkSecondary,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textDarkSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textDarkSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
