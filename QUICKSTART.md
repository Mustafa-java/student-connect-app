# 🚀 Быстрый старт - СтудХаб

## ✅ Что уже работает:

### Экраны:
1. **Splash Screen** - анимированная заставка с логотипом
2. **Home (Домой)** - лента проектов с карточками в стиле Instagram
3. **Profile (Профиль)** - портфолио пользователя с сеткой проектов
4. **Messages (Сообщения)** - список чатов
5. **Search (Поиск)** - поиск проектов и студентов
6. **Project Detail** - детальная информация о проекте

### Функции:
- ✅ Темная тема по умолчанию
- ✅ Нижняя навигация (5 табов)
- ✅ Stories row на главном экране
- ✅ Лайки, комментарии, сохранения
- ✅ Карусель изображений
- ✅ Pull-to-refresh
- ✅ Skeleton загрузка
- ✅ Плавные анимации
- ✅ Мок-данные для тестирования

## 📱 Запуск приложения:

### Вариант 1: VS Code
1. Открой папку проекта в VS Code
2. Нажми **F5** или кнопку ▶️ в нижней панели

### Вариант 2: Командная строка
```bash
cd C:\Users\admin\vs_code_dock\flutter_apps\student-connect-app
flutter run
```

### Вариант 3: Конкретное устройство
```bash
flutter devices                    # Узнать список устройств
flutter run -d emulator-5554      # Запустить на эмуляторе
```

## 🔧 Если что-то не работает:

### Ошибка: "No devices found"
```bash
flutter devices                    # Проверить устройства
flutter emulators                  # Запустить эмулятор
flutter doctor                     # Проверить установку Flutter
```

### Ошибка: "Build failed"
```bash
flutter clean                      # Очистить проект
flutter pub get                    # Установить зависимости
flutter run                        # Запустить снова
```

### Ошибка: "Android Gradle Plugin"
Убедись, что в `android/settings.gradle.kts` версия не ниже 8.1.1:
```kotlin
id("com.android.application") version "8.11.1" apply false
```

## 📂 Структура проекта:

```
lib/
├── main.dart                      # Точка входа
├── core/
│   ├── theme/
│   │   ├── app_colors.dart        # Цветовая палитра
│   │   └── app_theme.dart         # Темы Material 3
│   ├── constants/
│   │   └── app_constants.dart     # Константы приложения
│   └── widgets/
│       ├── custom_avatar.dart     # Кастомный аватар
│       ├── custom_buttons.dart    # Градиентные кнопки
│       └── skeletons.dart         # Skeleton загрузка
├── models/
│   ├── user.dart                  # Модель пользователя
│   ├── project.dart               # Модель проекта
│   ├── post.dart                  # Модель поста
│   └── message.dart               # Модель сообщения
├── providers/
│   └── app_providers.dart         # Riverpod провайдеры
├── data/mock/
│   ├── mock_users.dart            # Мок-пользователи
│   ├── mock_projects.dart         # Мок-проекты
│   ├── mock_posts.dart            # Мок-посты
│   └── mock_chats.dart            # Мок-чаты
└── features/
    ├── splash/
    │   └── splash_screen.dart
    ├── home/
    │   ├── home_screen.dart
    │   └── widgets/
    │       ├── post_card.dart
    │       └── stories_row.dart
    ├── profile/
    │   └── profile_screen.dart
    ├── messages/
    │   ├── messages_screen.dart
    │   └── chat_screen.dart
    ├── search/
    │   └── search_screen.dart
    └── project/
        └── project_detail_screen.dart
```

## 🎨 Цветовая схема:

```dart
Primary:       #6366F1 (Indigo)
Accent:        #06B6D4 (Cyan)
Background:    #121212 (Dark)
Surface:       #1E1E1E
Success:       #22C55E (Green)
Error:         #EF4444 (Red)
```

## 🛠 Технологии:

- **Flutter** 3.x
- **Dart** 3.x
- **Riverpod** - state management
- **Material 3** - дизайн
- **google_fonts** - шрифты Inter/Poppins
- **cached_network_image** - кэширование изображений
- **carousel_slider** - карусель
- **flutter_animate** - анимации

## 📝 Следующие шаги:

### Можно доработать:
1. ⏳ Экраны Login/Register
2. ⏳ Форма создания проекта
3. ⏳ Комментарии к проектам
4. ⏳ Редактирование профиля
5. ⏳ Загрузка изображений
6. ⏳ Backend интеграция

### Готово к использованию:
- ✅ Навигация между экранами
- ✅ Отображение ленты проектов
- ✅ Просмотр профиля
- ✅ Просмотр чатов
- ✅ Поиск проектов
- ✅ Детали проекта

## 🎯 Как тестировать:

1. **Лента проектов**: Главный экран → скролль вниз
2. **Профиль**: Нажми на иконку профиля внизу
3. **Поиск**: Нажми на иконку поиска → введи запрос
4. **Сообщения**: Нажми на иконку сообщений → выбери чат
5. **Проект**: Нажми на карточку проекта → детали

## 📞 Если нужна помощь:

Проверь консоль VS Code на ошибки или запусти:
```bash
flutter analyze    # Проверка кода
flutter doctor     # Диагностика
```

---

**СтудХаб** - Твои проекты. Твои люди. Твоё будущее. 🚀
