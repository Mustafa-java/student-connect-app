# 🤖 AI Assistant Guide - Student Connect Project

**Для:** Claude, ChatGPT и других AI ассистентов  
**Цель:** Быстрая адаптация к проекту для помощи разработчику

---

## 📋 Краткая информация о проекте

### Что это?

**Student Connect (СтудХаб)** - мобильное приложение для студентов, объединяющее:
- Социальную сеть
- Портфолио проектов
- Мессенджер
- Поиск единомышленников

### Статус проекта

✅ **Готов к защите диплома**
- Полностью рабочий функционал
- Backend развернут на облаке
- Код на GitHub
- ~8000+ строк Flutter кода
- ~1500+ строк backend кода

### Автор

- **Имя:** Улугбек уулу Мустафа
- **Email:** mustafa@student.com (для git)
- **GitHub:** https://github.com/Mustafa-java
- **Проект:** Дипломная работа

---

## 🏗️ Архитектура проекта

### Общая схема

```
┌──────────────────────────────────────┐
│  Flutter Mobile App (Android)        │
│  - Dart 3.0+                         │
│  - Flutter 3.41.6                    │
│  - Riverpod (state management)       │
│  - Material Design 3                 │
└──────────────┬───────────────────────┘
               │ HTTPS (Dio)
               │
┌──────────────▼───────────────────────┐
│  Backend API (Node.js + Express)     │
│  URL: https://student-connect-       │
│       backend.onrender.com           │
│  - JWT Authentication                │
│  - RESTful API                       │
│  - File uploads (Multer)             │
└──────────────┬───────────────────────┘
               │
┌──────────────▼───────────────────────┐
│  SQLite Database (sql.js)            │
│  - Users, Posts, Projects            │
│  - Messages, Chats                   │
│  - Likes, Comments, Follows          │
└──────────────────────────────────────┘
```

### Технологический стек

**Frontend (Flutter):**
- `flutter_riverpod` - State management
- `dio` - HTTP client
- `shared_preferences` - Local storage
- `cached_network_image` - Image caching
- `google_fonts` - Typography
- `carousel_slider` - Image carousels
- `shimmer` - Loading skeletons
- `lottie` - Animations

**Backend (Node.js):**
- `express` - Web framework
- `sql.js` - SQLite database
- `bcrypt` - Password hashing
- `jsonwebtoken` - JWT auth
- `multer` - File uploads
- `cors` - CORS handling
- `uuid` - ID generation

---

## 📁 Структура файлов

### Корневая директория

```
student-connect-app/
├── lib/                    # Flutter приложение
├── backend/                # Node.js backend
├── android/                # Android конфигурация
├── assets/                 # Изображения, иконки
├── pubspec.yaml            # Flutter зависимости
├── QUICKSTART.md           # Быстрый старт
├── SETUP_GUIDE.md          # Полная инструкция
├── GUIDEFORAI.md           # Этот файл
└── README.md               # Описание проекта
```

### Flutter приложение (lib/)

```
lib/
├── main.dart                           # Точка входа
├── core/
│   ├── theme/
│   │   ├── app_colors.dart             # Цветовая палитра
│   │   └── app_theme.dart              # Material 3 темы
│   ├── constants/
│   │   └── app_constants.dart          # Константы
│   ├── utils/
│   │   └── page_transitions.dart       # Анимации переходов
│   └── widgets/
│       ├── custom_avatar.dart          # Аватар с градиентом
│       ├── custom_buttons.dart         # Кнопки
│       ├── hero_avatar.dart            # Hero анимация
│       ├── network_error.dart          # Ошибки сети
│       ├── project_card.dart           # Карточка проекта
│       ├── skeletons.dart              # Skeleton loaders
│       └── smart_image.dart            # Оптимизированные изображения
├── models/
│   ├── user.dart                       # Модель пользователя
│   ├── project.dart                    # Модель проекта
│   ├── post.dart                       # Модель поста
│   ├── message.dart                    # Модель сообщения
│   └── models.dart                     # Экспорт всех моделей
├── services/
│   └── api_service.dart                # HTTP клиент (Dio)
├── providers/
│   ├── app_providers.dart              # Riverpod провайдеры
│   └── theme_provider.dart             # Тема приложения
├── data/mock/
│   ├── mock_users.dart                 # Тестовые пользователи
│   ├── mock_projects.dart              # Тестовые проекты
│   ├── mock_posts.dart                 # Тестовые посты
│   └── mock_chats.dart                 # Тестовые чаты
└── features/                           # Экраны по функциям
    ├── splash/
    │   └── splash_screen.dart          # Заставка
    ├── auth/
    │   ├── login_screen.dart           # Вход
    │   ├── register_screen.dart        # Регистрация
    │   └── onboarding_screen.dart      # Онбординг
    ├── main_screen.dart                # Главный экран с навигацией
    ├── home/
    │   ├── home_screen.dart            # Лента постов
    │   └── widgets/
    │       ├── post_card.dart          # Карточка поста
    │       └── stories_row.dart        # Истории (stories)
    ├── profile/
    │   ├── profile_screen.dart         # Мой профиль
    │   ├── user_profile_screen.dart    # Базовый профиль
    │   ├── other_user_profile_screen.dart  # Профиль другого
    │   └── edit_profile_screen.dart    # Редактирование
    ├── messages/
    │   ├── messages_screen.dart        # Список чатов
    │   ├── chat_screen.dart            # Экран чата
    │   └── new_chat_screen.dart        # Новый чат
    ├── search/
    │   └── search_screen.dart          # Поиск
    ├── notifications/
    │   └── notifications_screen.dart   # Уведомления
    ├── settings/
    │   └── settings_screen.dart        # Настройки
    ├── post/
    │   ├── create_post_screen.dart     # Создание поста
    │   └── post_detail_screen.dart     # Детали поста
    ├── project/
    │   ├── create_project_screen.dart  # Создание проекта
    │   └── project_detail_screen.dart  # Детали проекта
    └── common/
        ├── comments_bottom_sheet.dart  # Комментарии
        ├── image_viewer_screen.dart    # Просмотр изображений
        └── project_download_dialog.dart # Скачивание проекта
```

### Backend (backend/)

```
backend/
├── server.js               # Express сервер + все API эндпоинты
├── database.js             # SQLite инициализация и схема
├── package.json            # Node.js зависимости
├── package-lock.json       # Lockfile
├── student_connect.db      # SQLite база (не в git)
├── uploads/                # Загруженные файлы (не в git)
├── .gitignore              # Git ignore
└── README.md               # Backend документация
```

---

## 🌐 Backend API

### URL и доступ

**Production (облако):**
- **URL:** https://student-connect-backend.onrender.com
- **Платформа:** Render.com (бесплатный план)
- **Регион:** Frankfurt, EU
- **Статус:** Работает 24/7 (засыпает после 15 мин неактивности)

**Доступ к Render Dashboard:**
- **URL:** https://dashboard.render.com/web/srv-d8csddt7vvec73ckovt0
- **Аккаунт:** Зарегистрирован через GitHub (Mustafa-java)
- **Логин:** Через GitHub OAuth

**Локальный (для разработки):**
- **URL:** http://localhost:3000
- **Запуск:** `cd backend && npm start`

### Важные переменные окружения

На Render.com настроены:
- `PORT` - автоматически назначается Render
- `JWT_SECRET` - `student-connect-secret-key-2026`

### API Эндпоинты

**Корневой:**
- `GET /` - Информация об API

**Аутентификация:**
- `POST /api/auth/register` - Регистрация
- `POST /api/auth/login` - Вход
- `GET /api/auth/me` - Текущий пользователь (требует auth)

**Пользователи:**
- `GET /api/users` - Список пользователей (требует auth)
- `GET /api/users/:id` - Пользователь по ID (требует auth)
- `PUT /api/users/:id` - Обновить профиль (требует auth)
- `GET /api/users/search?q=query` - Поиск (требует auth)

**Посты:**
- `GET /api/posts` - Все посты (требует auth)
- `POST /api/posts` - Создать пост (требует auth)
- `DELETE /api/posts/:id` - Удалить пост (требует auth)
- `POST /api/posts/:id/like` - Лайк/анлайк (требует auth)
- `GET /api/posts/:id/comments` - Комментарии (требует auth)
- `POST /api/posts/:id/comments` - Добавить комментарий (требует auth)

**Проекты:**
- `GET /api/projects` - Все проекты (требует auth)
- `POST /api/projects` - Создать проект (требует auth)
- `DELETE /api/projects/:id` - Удалить проект (требует auth)
- `POST /api/projects/:id/like` - Лайк/анлайк (требует auth)
- `POST /api/projects/:id/views` - Увеличить просмотры (требует auth)
- `POST /api/projects/:id/upload-zip` - Загрузить ZIP (требует auth)
- `GET /api/projects/:id/zip-file` - Скачать ZIP (требует auth)

**Чаты:**
- `GET /api/chats` - Список чатов (требует auth)
- `POST /api/chats` - Создать чат (требует auth)
- `GET /api/chats/:id/messages` - Сообщения (требует auth)
- `POST /api/chats/:id/messages` - Отправить сообщение (требует auth)
- `POST /api/chats/:id/read` - Отметить прочитанным (требует auth)

**Подписки:**
- `POST /api/follow/:userId` - Подписаться/отписаться (требует auth)
- `GET /api/follow/status/:userId` - Статус подписки (требует auth)
- `GET /api/followers/:userId` - Подписчики (требует auth)
- `GET /api/following/:userId` - Подписки (требует auth)

### Аутентификация

**JWT токены:**
- Токен возвращается при регистрации/входе
- Передается в заголовке: `Authorization: Bearer <token>`
- Срок действия: 30 дней
- Хранится в `SharedPreferences` на клиенте

---

## 🎨 Дизайн и UI

### Цветовая схема (темная тема)

```dart
Primary:       #6366F1 (Indigo)
Accent:        #06B6D4 (Cyan)
Background:    #121212 (Dark)
Surface:       #1E1E1E
Success:       #22C55E (Green)
Error:         #EF4444 (Red)
Warning:       #F59E0B (Amber)
```

### Шрифты

- **Основной:** Inter (Google Fonts)
- **Заголовки:** Poppins Bold (Google Fonts)
- **Fallback:** System fonts

### Стиль

- **Вдохновение:** Instagram 2025
- **Дизайн:** Material Design 3
- **Анимации:** Плавные переходы (300ms)
- **Карточки:** Закругленные углы (12-16px)
- **Градиенты:** Фиолетовый → Синий → Голубой

---

## 🔧 Команды для работы

### Flutter

```bash
# Запуск
flutter run                             # Запустить на первом устройстве
flutter run -d <device-id>              # Запустить на конкретном
flutter devices                         # Список устройств

# Сборка
flutter build apk                       # Собрать APK
flutter build appbundle                 # Собрать AAB для Play Store

# Разработка
flutter pub get                         # Установить зависимости
flutter clean                           # Очистить кэш
flutter analyze                         # Проверить код
flutter doctor                          # Диагностика

# Во время работы (hot reload)
r                                       # Hot reload
R                                       # Hot restart
q                                       # Выход
```

### Backend

```bash
# Локальный запуск
cd backend
npm install                             # Установить зависимости
npm start                               # Запустить сервер
npm run dev                             # Запустить с watch mode

# Проверка
curl http://localhost:3000/             # Проверить локально
curl https://student-connect-backend.onrender.com/  # Проверить production
```

### Git

```bash
# Текущий репозиторий
git remote -v                           # Показать remote
# origin: https://github.com/Mustafa-java/student-connect-app.git

# Коммиты
git add .
git commit -m "Описание изменений"
git push origin main

# Автоматический деплой
# При push в main → Render автоматически деплоит backend
```

---

## 🚨 Важные моменты

### 1. Backend на Render.com

⚠️ **Бесплатный план имеет ограничения:**
- Засыпает после 15 минут неактивности
- Первый запрос после сна: 30-50 секунд
- 750 часов/месяц бесплатно (достаточно для постоянной работы)

**Решение:** Перед демонстрацией открыть приложение за 1-2 минуты.

### 2. API URL в коде

**Файл:** `lib/services/api_service.dart`

```dart
// Production (облако)
static const String _baseUrl = 'https://student-connect-backend.onrender.com';

// Локальный backend
// static const String _baseUrl = 'http://10.0.2.2:3000';  // Эмулятор
// static const String _baseUrl = 'http://192.168.X.X:3000';  // Физическое устройство
```

### 3. База данных

- **Тип:** SQLite (sql.js)
- **Файл:** `backend/student_connect.db`
- **Хранение:** На сервере Render (персистентное)
- **Бэкап:** Нет автоматического бэкапа на бесплатном плане

**Важно:** База данных НЕ в git (.gitignore)

### 4. Загруженные файлы

- **Папка:** `backend/uploads/`
- **Типы:** ZIP архивы проектов, изображения
- **Хранение:** На сервере Render
- **Ограничение:** 50MB на файл

**Важно:** Папка uploads НЕ в git (.gitignore)

### 5. Google Fonts

Иногда не загружаются из-за проблем с сетью. Это не критично - приложение использует системные шрифты как fallback.

---

## 🐛 Частые проблемы и решения

### "Connection refused" / "Network error"

**Причина:** Backend сервер спит или недоступен

**Решение:**
1. Проверить статус: `curl https://student-connect-backend.onrender.com/`
2. Подождать 30-50 секунд (сервер просыпается)
3. Проверить интернет на устройстве

### "Build failed" / Gradle ошибки

**Решение:**
```bash
flutter clean
flutter pub get
flutter run
```

### "No devices found"

**Решение:**
```bash
flutter devices                         # Проверить устройства
flutter emulators                       # Список эмуляторов
flutter emulators --launch <id>         # Запустить эмулятор
```

### Backend не запускается локально

**Решение:**
```bash
cd backend
rm -rf node_modules package-lock.json   # Удалить зависимости
npm install                             # Переустановить
npm start                               # Запустить
```

---

## 📝 Что можно улучшить (TODO)

### Функционал

- [ ] Push-уведомления (Firebase Cloud Messaging)
- [ ] Видео-контент в постах
- [ ] Истории (Stories) как в Instagram
- [ ] Рекомендательная система
- [ ] Система достижений и бейджей
- [ ] Календарь мероприятий (хакатоны)
- [ ] Командная работа над проектами

### Технические улучшения

- [ ] Миграция с SQLite на PostgreSQL
- [ ] WebSocket для real-time чата
- [ ] Redis для кэширования
- [ ] Unit и integration тесты
- [ ] CI/CD pipeline
- [ ] iOS версия
- [ ] Web версия (PWA)

### Backend

- [ ] Rate limiting
- [ ] Пагинация для больших списков
- [ ] Оптимизация SQL запросов
- [ ] Логирование (Winston)
- [ ] Мониторинг (Sentry)

---

## 🎓 Для защиты диплома

### Что работает (демонстрировать):

1. ✅ Регистрация и авторизация
2. ✅ Лента постов с изображениями
3. ✅ Создание постов и проектов
4. ✅ Чаты между пользователями
5. ✅ Профили с портфолио
6. ✅ Поиск пользователей и проектов
7. ✅ Лайки и комментарии
8. ✅ Скачивание ZIP-файлов проектов
9. ✅ Подписки на пользователей
10. ✅ Уведомления

### Ключевые технологии (упоминать):

- Flutter + Dart для мобильной разработки
- Riverpod для state management
- Node.js + Express для backend
- SQLite для базы данных
- JWT для аутентификации
- Render.com для облачного хостинга
- Material Design 3 для UI/UX
- Clean Architecture для структуры кода

### Статистика проекта:

- **Экранов:** 24+
- **Виджетов:** 15+ переиспользуемых
- **API эндпоинтов:** 30+
- **Строк кода (Flutter):** ~8000+
- **Строк кода (Backend):** ~1500+
- **Библиотек:** 25+
- **Таблиц в БД:** 8

---

## 🔗 Полезные ссылки

### Проект

- **GitHub:** https://github.com/Mustafa-java/student-connect-app
- **Backend Dashboard:** https://dashboard.render.com/web/srv-d8csddt7vvec73ckovt0
- **Backend URL:** https://student-connect-backend.onrender.com

### Документация

- **Flutter:** https://docs.flutter.dev/
- **Dart:** https://dart.dev/
- **Riverpod:** https://riverpod.dev/
- **Material Design 3:** https://m3.material.io/
- **Express.js:** https://expressjs.com/
- **Render.com:** https://render.com/docs

---

## 💡 Советы для AI ассистента

### При помощи с кодом:

1. **Проверяй текущий код** перед предложениями
2. **Следуй существующему стилю** (Material 3, темная тема)
3. **Используй Riverpod** для state management
4. **Не ломай существующий функционал**
5. **Тестируй предложения** перед отправкой

### При работе с backend:

1. **Проверяй, что сервер работает** перед изменениями
2. **Не меняй схему БД** без миграции
3. **Сохраняй обратную совместимость** API
4. **Добавляй логирование** для отладки

### При деплое:

1. **Коммить только нужные файлы** (не .db, не uploads/)
2. **Проверять .gitignore** перед push
3. **Тестировать локально** перед push
4. **Ждать завершения деплоя** на Render (~3-5 мин)

---

**Готово! Теперь ты знаешь все о проекте Student Connect! 🚀**

*Последнее обновление: 2026-05-30*
