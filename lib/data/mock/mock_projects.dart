import 'mock_users.dart';
import '../../models/models.dart';

class MockProjects {
  MockProjects._();

  static List<Project> get projects => [
    Project(
      id: 'proj_001',
      title: 'AI-помощник для студентов',
      description:
          'Умный помощник на базе искусственного интеллекта, который помогает студентам готовиться к экзаменам, составлять расписание и находить полезные материалы. Использует современные алгоритмы машинного обучения для персонализации обучения.\n\nПриложение умеет:\n• Генерировать вопросы для самопроверки\n• Создавать конспекты из лекций\n• Находить похожие темы и материалы\n• Отслеживать прогресс обучения',
      author: MockUsers.users.isNotEmpty ? MockUsers.users.first : MockUsers.defaultUser,
      images: [
        'https://picsum.photos/seed/ai-helper/800/600',
        'https://picsum.photos/seed/ai-helper2/800/600',
        'https://picsum.photos/seed/ai-helper3/800/600',
      ],
      skills: ['Python', 'TensorFlow', 'Flutter', 'Machine Learning', 'NLP'],
      teamMembers: [
        if (MockUsers.users.length > 1) MockUsers.users[1],
        if (MockUsers.users.length > 2) MockUsers.users[2],
      ],
      status: 'in_progress',
      likesCount: 45,
      commentsCount: 12,
      viewsCount: 234,
      isLiked: false,
      isSaved: false,
      universityTags: ['МГУ', 'МГТУ им. Баумана'],
      zipFileUrl: '/api/projects/proj_001/zip-file',
      zipFileName: 'ai-student-helper-v1.2.zip',
      zipFileSize: 15 * 1024 * 1024, // 15 MB
      createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    Project(
      id: 'proj_002',
      title: 'Платформа для совместного обучения',
      description:
          'Веб-приложение для создания учебных групп, совместного изучения материалов и взаимопомощи. Студенты могут объединяться в группы по интересам, делиться заметками и вместе готовиться к экзаменам.\n\nОсновные функции:\n• Создание учебных групп\n• Общие заметки и материалы\n• Видеоконференции\n• Система достижений и рейтингов',
      author: MockUsers.users.length > 3 ? MockUsers.users[3] : MockUsers.defaultUser,
      images: [
        'https://picsum.photos/seed/study-platform/800/600',
        'https://picsum.photos/seed/study-platform2/800/600',
      ],
      skills: ['React', 'Node.js', 'PostgreSQL', 'WebSocket', 'WebRTC'],
      teamMembers: [
        if (MockUsers.users.length > 4) MockUsers.users[4],
      ],
      status: 'looking_for_team',
      likesCount: 28,
      commentsCount: 8,
      viewsCount: 156,
      isLiked: true,
      isSaved: true,
      universityTags: ['СПбГУ', 'ИТМО'],
      zipFileUrl: '/api/projects/proj_002/zip-file',
      zipFileName: 'study-together-platform.zip',
      zipFileSize: 8 * 1024 * 1024, // 8 MB
      createdAt: DateTime.now().subtract(const Duration(days: 7, hours: 12)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Project(
      id: 'proj_003',
      title: 'Мобильное приложение для кампуса',
      description:
          'Приложение для навигации по кампусу университета с интерактивными картами, расписанием занятий, меню столовой и уведомлениями о мероприятиях.\n\nФункции:\n• 3D карты кампуса\n• Расписание с напоминаниями\n• Меню столовой с фильтрами\n• Уведомления о событиях\n• Интеграция с электронной зачёткой',
      author: MockUsers.users.length > 2 ? MockUsers.users[2] : MockUsers.defaultUser,
      images: [
        'https://picsum.photos/seed/campus-app/800/600',
        'https://picsum.photos/seed/campus-app2/800/600',
        'https://picsum.photos/seed/campus-app3/800/600',
        'https://picsum.photos/seed/campus-app4/800/600',
      ],
      skills: ['Flutter', 'Firebase', 'Google Maps API', 'Dart', 'Figma'],
      teamMembers: [],
      status: 'completed',
      likesCount: 89,
      commentsCount: 24,
      viewsCount: 512,
      isLiked: false,
      isSaved: true,
      universityTags: ['ВШЭ', 'РАНХиГС'],
      zipFileUrl: '/api/projects/proj_003/zip-file',
      zipFileName: 'campus-guide-final.zip',
      zipFileSize: 22 * 1024 * 1024, // 22 MB
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Project(
      id: 'proj_004',
      title: 'Генератор презентаций с ИИ',
      description:
          'Инструмент для автоматического создания презентаций на основе текстового описания. Просто введите тему и ключевые моменты — ИИ создаст красивую презентацию с графиками, изображениями и анимациями.\n\nПоддерживает экспорт в PowerPoint, PDF и Google Slides.',
      author: MockUsers.users.isNotEmpty ? MockUsers.users.first : MockUsers.defaultUser,
      images: [
        'https://picsum.photos/seed/pres-gen/800/600',
      ],
      skills: ['Vue.js', 'Python', 'OpenAI API', 'Canvas API', 'Tailwind CSS'],
      teamMembers: [
        if (MockUsers.users.length > 1) MockUsers.users[1],
      ],
      status: 'idea',
      likesCount: 67,
      commentsCount: 15,
      viewsCount: 289,
      isLiked: true,
      isSaved: false,
      universityTags: ['МФТИ', 'НИЯУ МИФИ'],
      zipFileUrl: null,
      zipFileName: null,
      zipFileSize: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    Project(
      id: 'proj_005',
      title: 'Система управления студенческими проектами',
      description:
          'Полнофункциональная система для управления студенческими проектами с таск-трекером, канбан-досками, диаграммами Ганта и интеграцией с GitHub.\n\nИдеально подходит для курсовых и дипломных работ.',
      author: MockUsers.users.length > 4 ? MockUsers.users[4] : MockUsers.defaultUser,
      images: [
        'https://picsum.photos/seed/project-mgr/800/600',
        'https://picsum.photos/seed/project-mgr2/800/600',
      ],
      skills: ['Angular', 'Spring Boot', 'MySQL', 'Docker', 'GitHub API'],
      teamMembers: [
        if (MockUsers.users.length > 1) MockUsers.users[1],
        if (MockUsers.users.length > 2) MockUsers.users[2],
        if (MockUsers.users.length > 3) MockUsers.users[3],
      ],
      status: 'in_progress',
      likesCount: 34,
      commentsCount: 9,
      viewsCount: 178,
      isLiked: false,
      isSaved: false,
      universityTags: ['МГТУ им. Баумана', 'МАИ'],
      zipFileUrl: '/api/projects/proj_005/zip-file',
      zipFileName: 'student-pm-system-beta.zip',
      zipFileSize: 18 * 1024 * 1024, // 18 MB
      createdAt: DateTime.now().subtract(const Duration(days: 10, hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  /// Получить проект по ID
  static Project? getById(String id) {
    try {
      return projects.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Поиск проектов по запросу
  static List<Project> search(String query) {
    if (query.isEmpty) return projects;
    final lowerQuery = query.toLowerCase();
    return projects.where((p) {
      return p.title.toLowerCase().contains(lowerQuery) ||
          p.description.toLowerCase().contains(lowerQuery) ||
          p.skills.any((s) => s.toLowerCase().contains(lowerQuery)) ||
          p.author.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Проекты со статусом "looking_for_team"
  static List<Project> get lookingForTeam =>
      projects.where((p) => p.status == 'looking_for_team').toList();

  /// Популярные проекты (по лайкам)
  static List<Project> get popular =>
      [...projects]..sort((a, b) => b.likesCount.compareTo(a.likesCount));
}
