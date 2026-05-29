import '../../models/models.dart';

/// Мок-данные пользователей
class MockUsers {
  MockUsers._();

  /// Текущий пользователь
  static User get currentUser => User(
        id: 'user_1',
        name: 'Александр Петров',
        email: 'alex@example.com',
        avatarUrl: 'https://i.pravatar.cc/300?img=11',
        bio: 'Разработчик Flutter | Люблю создавать красивые приложения',
        university: 'МГТУ им. Баумана',
        faculty: 'ИУ7',
        course: '4',
        skills: ['Flutter', 'Dart', 'Firebase', 'Figma'],
        projectsCount: 5,
        followersCount: 128,
        followingCount: 89,
        isOnline: true,
        createdAt: DateTime(2024, 1, 15),
      );

  /// Список других пользователей для примера
  static List<User> get otherUsers => [
    User(
      id: 'user_2',
      name: 'Мария Иванова',
      email: 'maria@example.com',
      avatarUrl: 'https://i.pravatar.cc/300?img=5',
      bio: 'Дизайнер UI/UX | Студентка ИТМО',
      university: 'ИТМО',
      faculty: 'Дизайн',
      course: '3',
      skills: ['Figma', 'Adobe XD', 'Sketch', 'Prototyping'],
      projectsCount: 8,
      followersCount: 245,
      followingCount: 156,
      isOnline: true,
      createdAt: DateTime(2024, 2, 20),
    ),
    User(
      id: 'user_3',
      name: 'Дмитрий Козлов',
      email: 'dmitry@example.com',
      avatarUrl: 'https://i.pravatar.cc/300?img=13',
      bio: 'Backend разработчик | Python энтузиаст',
      university: 'СПбГУ',
      faculty: 'Прикладная математика',
      course: '4',
      skills: ['Python', 'Django', 'PostgreSQL', 'Docker'],
      projectsCount: 12,
      followersCount: 189,
      followingCount: 78,
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
      createdAt: DateTime(2024, 1, 10),
    ),
    User(
      id: 'user_4',
      name: 'Анна Смирнова',
      email: 'anna@example.com',
      avatarUrl: 'https://i.pravatar.cc/300?img=9',
      bio: 'Fullstack разработчик | React & Node.js',
      university: 'ВШЭ',
      faculty: 'Программная инженерия',
      course: '3',
      skills: ['React', 'Node.js', 'MongoDB', 'TypeScript'],
      projectsCount: 6,
      followersCount: 167,
      followingCount: 92,
      isOnline: true,
      createdAt: DateTime(2024, 3, 5),
    ),
    User(
      id: 'user_5',
      name: 'Игорь Волков',
      email: 'igor@example.com',
      avatarUrl: 'https://i.pravatar.cc/300?img=15',
      bio: 'Мобильная разработка | Flutter & Swift',
      university: 'МФТИ',
      faculty: 'Физтех',
      course: '5',
      skills: ['Flutter', 'Swift', 'Kotlin', 'React Native'],
      projectsCount: 9,
      followersCount: 201,
      followingCount: 134,
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
      createdAt: DateTime(2023, 11, 1),
    ),
  ];

  /// Все пользователи (включая текущего)
  static List<User> get users => [currentUser, ...otherUsers];

  /// Пользователь по умолчанию
  static User get defaultUser => currentUser;

  /// Получить пользователя по ID
  static User getUserById(String id) {
    if (id == currentUser.id) return currentUser;
    return otherUsers.firstWhere(
      (user) => user.id == id,
      orElse: () => currentUser,
    );
  }
}
