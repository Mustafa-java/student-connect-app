# Student Connect Backend

Backend API для мобильного приложения Student Connect.

## Технологии
- Node.js + Express
- SQLite (sql.js)
- JWT Authentication
- Multer для загрузки файлов

## Установка

```bash
npm install
```

## Запуск

```bash
npm start
```

Сервер запустится на порту 3000 (или PORT из переменных окружения).

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
