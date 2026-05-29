# 🚀 Быстрый старт - СтудХаб (Student Connect)

## 📱 О проекте

**СтудХаб** - мобильная платформа для студентов, объединяющая социальную сеть, портфолио проектов и мессенджер.

- 🌐 **Backend:** Облачный сервер на Render.com
- 📱 **Frontend:** Flutter приложение для Android
- 💾 **База данных:** SQLite на сервере
- 🔐 **Аутентификация:** JWT токены

---

## ⚡ Быстрый запуск (5 минут)

### Шаг 1: Проверьте Flutter

```bash
flutter doctor
```

Если Flutter не установлен, см. [SETUP_GUIDE.md](SETUP_GUIDE.md)

### Шаг 2: Установите зависимости

```bash
cd C:\Users\admin\vs_code_dock\flutter_apps\student-connect-app
flutter pub get
```

### Шаг 3: Подключите устройство

**Вариант A: Физическое Android устройство**
1. Включите "Режим разработчика" на телефоне
2. Включите "Отладка по USB"
3. Подключите телефон к компьютеру

**Вариант B: Эмулятор Android**
```bash
flutter emulators                    # Список эмуляторов
flutter emulators --launch <id>      # Запустить эмулятор
```

### Шаг 4: Запустите приложение

```bash
flutter run
```

Или для конкретного устройства:
```bash
flutter devices                      # Посмотреть список
flutter run -d <device-id>           # Запустить на устройстве
```

**Готово!** Приложение запустится и подключится к облачному серверу.

---

## 🌐 Backend сервер

### Облачный сервер (Production)

- **URL:** https://student-connect-backend.onrender.com
- **Статус:** Работает 24/7
- **Регион:** Frankfurt (EU)
- **Платформа:** Render.com (бесплатный план)

⚠️ **Важно:** Бесплатный сервер засыпает после 15 минут неактивности. Первый запрос после сна занимает ~30-50 секунд.

### Проверка работы сервера

```bash
curl https://student-connect-backend.onrender.com/
```

Должен вернуть JSON с информацией об API.

### Локальный backend (для разработки)

Если хотите запустить backend локально:

```bash
cd backend
npm install
npm start
```

Затем измените URL в `lib/services/api_service.dart`:
```dart
static const String _baseUrl = 'http://localhost:3000';
```

---

## ✅ Что уже работает

### Функционал:
- ✅ Регистрация и авторизация пользователей
- ✅ Лента постов с изображениями
- ✅ Создание и просмотр проектов
- ✅ Скачивание ZIP-файлов проектов
- ✅ Чаты и сообщения между пользователями
- ✅ Профили пользователей с портфолио
- ✅ Поиск пользователей и проектов
- ✅ Лайки и комментарии
- ✅ Подписки на пользователей
- ✅ Уведомления

### UI/UX:
- ✅ Темная тема (Instagram-style)
- ✅ Плавные анимации и переходы
- ✅ Skeleton загрузка
- ✅ Pull-to-refresh
- ✅ Карусель изображений
- ✅ Адаптивная верстка

---

## 📂 Структура проекта

```
student-connect-app/
├── lib/                           # Flutter приложение
│   ├── main.dart                  # Точка входа
│   ├── core/                      # Общие компоненты
│   │   ├── theme/                 # Темы и цвета
│   │   ├── widgets/               # Переиспользуемые виджеты
│   │   └── constants/             # Константы
│   ├── models/                    # Модели данных
│   ├── services/                  # API сервисы
│   │   └── api_service.dart       # HTTP клиент (Dio)
│   ├── providers/                 # State management (Riverpod)
│   ├── features/                  # Экраны по функциям
│   │   ├── auth/                  # Авторизация
│   │   ├── home/                  # Главная лента
│   │   ├── profile/               # Профиль
│   │   ├── messages/              # Чаты
│   │   ├── search/                # Поиск
│   │   ├── post/                  # Посты
│   │   └── project/               # Проекты
│   └── data/mock/                 # Мок-данные для тестов
│
├── backend/                       # Node.js backend
│   ├── server.js                  # Express сервер
│   ├── database.js                # SQLite база данных
│   ├── package.json               # Зависимости
│   └── uploads/                   # Загруженные файлы
│
├── android/                       # Android конфигурация
├── pubspec.yaml                   # Flutter зависимости
├── QUICKSTART.md                  # Этот файл
├── SETUP_GUIDE.md                 # Полная инструкция
└── GUIDEFORAI.md                  # Гайд для AI ассистентов
```

---

## 🔧 Полезные команды

### Flutter

```bash
flutter run                        # Запустить приложение
flutter run -d <device>            # Запустить на устройстве
flutter devices                    # Список устройств
flutter clean                      # Очистить кэш
flutter pub get                    # Установить зависимости
flutter analyze                    # Проверить код
flutter doctor                     # Диагностика
```

### Горячая перезагрузка (во время работы)

- `r` - Hot reload (быстрая перезагрузка)
- `R` - Hot restart (полная перезагрузка)
- `q` - Выход

---

## 🐛 Частые проблемы

### "No devices found"

```bash
flutter devices                    # Проверить устройства
flutter emulators                  # Список эмуляторов
```

### "Build failed"

```bash
flutter clean
flutter pub get
flutter run
```

### "Connection refused" / "Network error"

Проверьте, что backend сервер работает:
```bash
curl https://student-connect-backend.onrender.com/
```

Если сервер спит, подождите 30-50 секунд и попробуйте снова.

### Google Fonts не загружаются

Это не критично - приложение будет использовать системные шрифты. Проверьте интернет-соединение на устройстве.

---

## 🎯 Тестирование функционала

1. **Регистрация:** Создайте новый аккаунт
2. **Лента:** Просмотрите посты других пользователей
3. **Создание поста:** Нажмите "+" → добавьте фото и текст
4. **Проекты:** Создайте проект с описанием и технологиями
5. **Чаты:** Найдите пользователя и напишите сообщение
6. **Профиль:** Отредактируйте свой профиль

---

## 📞 Дополнительная информация

- **Полная инструкция:** [SETUP_GUIDE.md](SETUP_GUIDE.md)
- **Гайд для AI:** [GUIDEFORAI.md](GUIDEFORAI.md)
- **GitHub:** https://github.com/Mustafa-java/student-connect-app
- **Backend Dashboard:** https://dashboard.render.com/web/srv-d8csddt7vvec73ckovt0

---

**СтудХаб** - Твои проекты. Твои люди. Твоё будущее. 🚀
