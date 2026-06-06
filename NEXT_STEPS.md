# 🎯 Следующие шаги для завершения миграции

## ✅ Что уже сделано:
- Код обновлен для PostgreSQL
- Изменения закоммичены и отправлены на GitHub
- Документация готова

## 📋 Что нужно сделать сейчас:

### Шаг 1: Создать PostgreSQL базу данных на Render

1. Откройте браузер и перейдите на: **https://dashboard.render.com**
2. Войдите через GitHub (аккаунт Mustafa-java)
3. Нажмите кнопку **"New +"** в правом верхнем углу
4. Выберите **"PostgreSQL"**
5. Заполните форму:
   ```
   Name: student-connect-db
   Database: student_connect
   User: (оставьте автоматически)
   Region: Frankfurt (EU) или ближайший
   PostgreSQL Version: 15 или 16
   Datadog API Key: (оставьте пустым)
   Plan: Free
   ```
6. Нажмите **"Create Database"**
7. Дождитесь создания базы (1-2 минуты)
8. После создания вы увидите страницу с информацией о базе
9. **ВАЖНО:** Скопируйте **"Internal Database URL"** (начинается с `postgresql://`)
   - Это будет что-то вроде: `postgresql://student_connect_user:password@dpg-xxxxx-a/student_connect_db`

### Шаг 2: Настроить Web Service

1. В Render Dashboard перейдите в **"Web Services"**
2. Найдите и откройте ваш сервис: **student-connect-backend**
   - Прямая ссылка: https://dashboard.render.com/web/srv-d8csddt7vvec73ckovt0
3. Перейдите на вкладку **"Environment"** (слева в меню)
4. Найдите переменную `DATABASE_URL` или добавьте новую:
   - Нажмите **"Add Environment Variable"**
   - **Key:** `DATABASE_URL`
   - **Value:** (вставьте Internal Database URL из Шага 1)
5. Проверьте, что есть переменная `JWT_SECRET`:
   - Если нет, добавьте:
   - **Key:** `JWT_SECRET`
   - **Value:** `student-connect-secret-key-2026`
6. Добавьте переменную `NODE_ENV`:
   - **Key:** `NODE_ENV`
   - **Value:** `production`
7. Нажмите **"Save Changes"**

### Шаг 3: Дождаться автоматического деплоя

После сохранения переменных окружения Render автоматически:
1. Обнаружит изменения в GitHub (ваш push)
2. Начнет новый деплой
3. Установит зависимости (`npm install`)
4. Запустит сервер (`npm start`)
5. Сервер создаст схему базы данных при первом запуске

**Время деплоя:** 3-5 минут

Вы можете наблюдать за процессом:
- Перейдите на вкладку **"Logs"** в вашем Web Service
- Вы увидите процесс установки зависимостей и запуска сервера

### Шаг 4: Проверить работу API

После завершения деплоя (когда в логах увидите "Server running on port..."):

**Вариант 1: Через браузер**
Откройте: https://student-connect-backend.onrender.com/

Должны увидеть:
```json
{
  "name": "Student Connect API",
  "version": "2.0.0",
  "database": "PostgreSQL",
  "status": "running"
}
```

**Вариант 2: Через curl (если есть)**
```bash
curl https://student-connect-backend.onrender.com/
```

### Шаг 5: Протестировать регистрацию и логин

**Через Postman или любой REST клиент:**

1. **Регистрация:**
   - URL: `https://student-connect-backend.onrender.com/api/auth/register`
   - Method: POST
   - Headers: `Content-Type: application/json`
   - Body:
   ```json
   {
     "name": "Test User",
     "email": "test@example.com",
     "password": "password123",
     "university": "Test University"
   }
   ```

2. **Логин:**
   - URL: `https://student-connect-backend.onrender.com/api/auth/login`
   - Method: POST
   - Headers: `Content-Type: application/json`
   - Body:
   ```json
   {
     "email": "test@example.com",
     "password": "password123"
   }
   ```
   - Сохраните токен из ответа

3. **Получить профиль:**
   - URL: `https://student-connect-backend.onrender.com/api/auth/me`
   - Method: GET
   - Headers: `Authorization: Bearer ВАШ_ТОКЕН`

### Шаг 6: Протестировать Flutter приложение

1. Откройте Flutter приложение
2. Убедитесь, что в `lib/services/api_service.dart` используется production URL:
   ```dart
   static const String _baseUrl = 'https://student-connect-backend.onrender.com';
   ```
3. Запустите приложение на устройстве/эмуляторе
4. Попробуйте:
   - Регистрацию
   - Вход
   - Просмотр ленты
   - Создание поста
   - Чаты

## 🔍 Что проверить в логах Render

В логах должны быть строки:
```
✅ Connected to PostgreSQL database
🔧 Initializing database schema...
✅ Database schema initialized successfully
🚀 Server running on port 10000
```

## ⚠️ Возможные проблемы

### "Application failed to respond"
- Проверьте, что `DATABASE_URL` правильно установлен
- Проверьте логи на ошибки подключения к базе

### "Connection refused" в логах
- Убедитесь, что используете **Internal Database URL**, а не External
- Проверьте, что база данных создана и активна

### "password authentication failed"
- Проверьте, что скопировали полный URL с паролем
- Попробуйте пересоздать базу данных

## 📊 Проверка базы данных

Если хотите посмотреть, что в базе данных:

1. В Render Dashboard откройте вашу PostgreSQL базу
2. Перейдите на вкладку **"Connect"**
3. Скопируйте **"External Database URL"**
4. Используйте любой PostgreSQL клиент (pgAdmin, DBeaver, или psql):
   ```bash
   psql "postgresql://user:pass@host/db"
   ```
5. Выполните запросы:
   ```sql
   \dt                    -- список таблиц
   SELECT COUNT(*) FROM users;
   SELECT * FROM users LIMIT 5;
   ```

## ✅ Чеклист готовности

- [ ] PostgreSQL база создана на Render
- [ ] Internal Database URL скопирован
- [ ] DATABASE_URL добавлен в Environment
- [ ] JWT_SECRET установлен
- [ ] NODE_ENV=production установлен
- [ ] Деплой завершен успешно
- [ ] API отвечает на запросы
- [ ] Регистрация работает
- [ ] Логин работает
- [ ] Flutter приложение подключается к API

## 🎉 После успешного завершения

Миграция на PostgreSQL завершена! Теперь у вас:
- ✅ Более надежная и масштабируемая база данных
- ✅ Лучшая производительность
- ✅ Готовность к росту проекта
- ✅ Профессиональный стек для защиты диплома

---

**Время выполнения:** ~10-15 минут  
**Дата:** 2026-05-31

Если возникнут проблемы, см. [TESTING.md](./TESTING.md) раздел Troubleshooting.
