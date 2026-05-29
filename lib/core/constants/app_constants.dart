/// Константы приложения СтудХаб
class AppConstants {
  AppConstants._();

  // Названия приложения
  static const String appName = 'СтудХаб';
  static const String appTagline = 'Твои проекты. Твои люди. Твоё будущее.';

  // API (будет настроено позже)
  static const String apiBaseUrl = 'http://localhost:3000/api';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Пагинация
  static const int defaultPageSize = 20;
  static const int storiesLimit = 10;
  static const int projectsGridLimit = 30;

  // Ограничения
  static const int maxProjectImages = 5;
  static const int maxAvatarSize = 5 * 1024 * 1024; // 5 MB
  static const int maxDescriptionLength = 2000;
  static const int maxTitleLength = 100;

  // Навыки по умолчанию (для быстрого выбора)
  static const List<String> defaultSkills = [
    'Flutter',
    'Dart',
    'Python',
    'JavaScript',
    'TypeScript',
    'React',
    'Node.js',
    'Java',
    'Kotlin',
    'Swift',
    'Go',
    'C#',
    'PHP',
    'Ruby',
    'Rust',
    'UI/UX',
    'Figma',
    'Photoshop',
    'Machine Learning',
    'Data Science',
    'DevOps',
    'Docker',
    'Kubernetes',
    'AWS',
    'Firebase',
    'PostgreSQL',
    'MongoDB',
    'Redis',
    'Git',
    'Agile',
  ];

  // Университеты Кыргызстана (все Ошские + остальные)
  static const List<String> defaultUniversities = [
    // Бишкек
    'КРСУ им. Б. Ельцина',
    'КНУ им. Ж. Баласагына',
    'АУЦА (Американский университет)',
    'КТУ им. И. Раззакова',
    'КГТУ им. И. Ахунбаева',
    'КГМА им. И. Ахунбаева',
    'КЭУ им. М. Рыскулбекова',
    'ИУКР',
    'Кыргызско-Турецкий университет "Манас"',
    'Университет "Ала-Тоо"',
    'Кыргызский экономический университет',
    'Бишкекский гуманитарный университет',
    'Кыргызско-Российский Славянский университет',
    'Международный университет Кыргызстана',
    'Университет "Адабият"',
    'Бишкекский финансово-экономический колледж',
    // Ош
    'ОшГУ им. Б. Осмонова',
    'Ошский технологический университет',
    'Ошский государственный юридический институт',
    'Ошский медицинский институт',
    'Ошский гуманитарный педагогический институт',
    'Ошский университет экономики и предпринимательства',
    'Международный университет им. А. Мырзакматова (Ош)',
    'Ошский институт предпринимательства',
    'Ошский филиал КРСУ',
    'Ошский филиал КНУ',
    // Другие регионы
    'ЖАГУ (Жалал-Абадский госуниверситет)',
    'Таласский госуниверситет',
    'Нарынский госуниверситет',
    'Караколский государственный университет',
    'Токмокский государственный университет',
    'Балыкчинский филиал КНУ',
  ];

  // Навигация
  static const String homeRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String profileRoute = '/profile';
  static const String projectDetailRoute = '/project';
  static const String createProjectRoute = '/create';
  static const String messagesRoute = '/messages';
  static const String chatRoute = '/chat';
  static const String searchRoute = '/search';
  static const String settingsRoute = '/settings';
  static const String notificationsRoute = '/notifications';

  // Ключи для хранения данных
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String themeKey = 'theme_mode';

  // Анимации
  static const int splashDuration = 2500;
  static const int animationDuration = 300;
  static const int longAnimationDuration = 500;

  // Assets
  static const String imagesPath = 'assets/images/';
  static const String lottiePath = 'assets/lottie/';
  static const String iconsPath = 'assets/icons/';

  // Placeholder изображения
  static const String placeholderAvatar = '${imagesPath}avatar_placeholder.png';
  static const String placeholderProject =
      '${imagesPath}project_placeholder.png';
  static const String placeholderLogo = '${imagesPath}logo.png';

  // Lottie анимации
  static const String loadingAnimation = '${lottiePath}loading.json';
  static const String emptyAnimation = '${lottiePath}empty.json';
  static const String successAnimation = '${lottiePath}success.json';
  static const String errorAnimation = '${lottiePath}error.json';
}
