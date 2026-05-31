# Student Connect Backend

Backend API для мобильного приложения Student Connect.

## Технологии
- Node.js + Express
- PostgreSQL (pg)
- JWT Authentication
- Multer для загрузки файлов
- dotenv для переменных окружения

## Установка

```bash
npm install
```

## Настройка

1. Создайте файл `.env` на основе `.env.example`:
```bash
cp .env.example .env
```

2. Настройте PostgreSQL и обновите `DATABASE_URL` в `.env`:
```env
DATABASE_URL=postgresql://username:password@localhost:5432/student_connect
JWT_SECRET=student-connect-secret-key-2026
NODE_ENV=development
PORT=3000
```

3. Создайте базу данных PostgreSQL:
```bash
createdb student_connect
```

## Запуск

```bash
npm start
```

Сервер запустится на порту 3000 (или PORT из переменных окружения).
При первом запуске автоматически создастся схема базы данных.

## Миграция данных

Если у вас есть данные в SQLite (`student_connect.db`), выполните миграцию:

```bash
npm run migrate
```

Подробнее см. [MIGRATION.md](./MIGRATION.md)

## API Endpoints

### Аутентификация
- POST /api/auth/register - Регистрация
- POST /api/auth/login - Вход
- GET /api/auth/me - Текущий пользователь

### Пользователи
- GET /api/users - Список пользователей
- GET /api/users/:id - Информация о пользователе
- PUT /api/users/:id - Обновление профиля

### Посты
- GET /api/posts - Все посты
- POST /api/posts - Создать пост
- DELETE /api/posts/:id - Удалить пост
- POST /api/posts/:id/like - Лайк/анлайк
- GET /api/posts/:id/comments - Комментарии
- POST /api/posts/:id/comments - Добавить комментарий

### Проекты
- GET /api/projects - Все проекты
- POST /api/projects - Создать проект
- DELETE /api/projects/:id - Удалить проект
- POST /api/projects/:id/like - Лайк/анлайк
- POST /api/projects/:id/upload-zip - Загрузить ZIP
- GET /api/projects/:id/zip-file - Скачать ZIP

### Чаты
- GET /api/chats - Список чатов
- POST /api/chats - Создать чат
- GET /api/chats/:id/messages - Сообщения
- POST /api/chats/:id/messages - Отправить сообщение

### Подписки
- POST /api/follow/:userId - Подписаться/отписаться
- GET /api/follow/status/:userId - Статус подписки
