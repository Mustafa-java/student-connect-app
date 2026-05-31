# Инструкция по тестированию и деплою PostgreSQL

## Статус миграции

✅ **Код полностью готов к работе с PostgreSQL:**
- ✅ `database.js` - PostgreSQL схема
- ✅ `server.js` - все запросы используют `pool.query`
- ✅ `package.json` - зависимости обновлены
- ✅ `.env` файлы созданы
- ✅ Миграционный скрипт готов
- ✅ Документация обновлена

## Варианты тестирования

### Вариант 1: Деплой на Render (Рекомендуется)

Это самый простой способ, так как Render предоставляет бесплатную PostgreSQL базу данных.

#### Шаг 1: Создать PostgreSQL базу на Render

1. Войдите на https://dashboard.render.com
2. Нажмите **"New +"** → **"PostgreSQL"**
3. Заполните форму:
   - **Name:** `student-connect-db`
   - **Database:** `student_connect`
   - **Region:** Frankfurt (EU) или ближайший
   - **PostgreSQL Version:** 15 (или новее)
   - **Plan:** Free
4. Нажмите **"Create Database"**
5. Дождитесь создания (1-2 минуты)
6. Скопируйте **"Internal Database URL"** (начинается с `postgresql://`)

#### Шаг 2: Обновить Web Service

1. Откройте ваш Web Service: https://dashboard.render.com/web/srv-d8csddt7vvec73ckovt0
2. Перейдите в **"Environment"**
3. Найдите или добавьте переменную `DATABASE_URL`:
   - **Key:** `DATABASE_URL`
   - **Value:** (вставьте Internal Database URL из шага 1)
4. Убедитесь, что `JWT_SECRET` установлен:
   - **Key:** `JWT_SECRET`
   - **Value:** `student-connect-secret-key-2026`
5. Нажмите **"Save Changes"**

#### Шаг 3: Деплой

```bash
cd "C:\Users\admin\vs_code_dock\flutter_apps\student-connect-app"

# Добавить все изменения
git add .

# Создать коммит
git commit -m "Migrate to PostgreSQL"

# Отправить на GitHub
git push origin main
```

Render автоматически:
- Обнаружит изменения в GitHub
- Установит зависимости (`npm install`)
- Запустит сервер (`npm start`)
- Сервер создаст схему БД при первом запуске

#### Шаг 4: Проверка

Через 3-5 минут после деплоя:

```bash
curl https://student-connect-backend.onrender.com/
```

Ожидаемый ответ:
```json
{
  "name": "Student Connect API",
  "version": "2.0.0",
  "database": "PostgreSQL",
  "status": "running"
}
```

### Вариант 2: Локальное тестирование (требует установку PostgreSQL)

#### Установка PostgreSQL на Windows

1. Скачайте PostgreSQL: https://www.postgresql.org/download/windows/
2. Запустите установщик
3. Выберите компоненты: PostgreSQL Server, pgAdmin 4, Command Line Tools
4. Установите пароль для пользователя `postgres` (запомните его!)
5. Порт: оставьте 5432
6. Завершите установку

#### Создание базы данных

```bash
# Войти в PostgreSQL (введите пароль)
psql -U postgres

# В psql консоли:
CREATE DATABASE student_connect;
\q
```

#### Настройка .env

Обновите файл `backend/.env`:
```env
DATABASE_URL=postgresql://postgres:ВАШ_ПАРОЛЬ@localhost:5432/student_connect
JWT_SECRET=student-connect-secret-key-2026
NODE_ENV=development
PORT=3000
```

#### Запуск

```bash
cd backend
npm start
```

#### Проверка

```bash
curl http://localhost:3000/
```

### Вариант 3: Использовать облачную PostgreSQL (без локальной установки)

Можно использовать бесплатные облачные PostgreSQL сервисы:

1. **ElephantSQL** (https://www.elephantsql.com/) - 20MB бесплатно
2. **Supabase** (https://supabase.com/) - 500MB бесплатно
3. **Neon** (https://neon.tech/) - 3GB бесплатно

После создания базы скопируйте Connection String и используйте в `.env`.

## Миграция существующих данных

Если в `backend/student_connect.db` есть важные данные:

### На Render (после деплоя)

1. Скачайте `student_connect.db` с Render (если она там была)
2. Положите файл в `backend/student_connect.db` локально
3. Обновите `.env` с production `DATABASE_URL` из Render
4. Запустите миграцию:
   ```bash
   cd backend
   npm run migrate
   ```

### Локально

```bash
cd backend
npm run migrate
```

## Проверка работы API

После успешного запуска протестируйте основные эндпоинты:

### 1. Регистрация
```bash
curl -X POST https://student-connect-backend.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "university": "Test University"
  }'
```

### 2. Логин
```bash
curl -X POST https://student-connect-backend.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

Сохраните токен из ответа.

### 3. Получить текущего пользователя
```bash
curl https://student-connect-backend.onrender.com/api/auth/me \
  -H "Authorization: Bearer ВАШ_ТОКЕН"
```

## Troubleshooting

### "Connection refused" или "ECONNREFUSED"
- Проверьте, что PostgreSQL запущен
- Проверьте `DATABASE_URL` в `.env`
- Проверьте, что порт 5432 не занят

### "password authentication failed"
- Проверьте username и password в `DATABASE_URL`
- Убедитесь, что пользователь существует в PostgreSQL

### "database does not exist"
- Создайте базу: `createdb student_connect`
- Или через psql: `CREATE DATABASE student_connect;`

### "relation does not exist"
- Схема не создана
- Перезапустите сервер: `npm start`
- Проверьте логи на ошибки при инициализации

### Render: "Application failed to respond"
- Проверьте логи в Render Dashboard
- Убедитесь, что `DATABASE_URL` установлен
- Проверьте, что база данных создана и доступна

## Следующие шаги

После успешного деплоя:

1. ✅ Протестируйте все API эндпоинты
2. ✅ Обновите Flutter приложение (если нужно)
3. ✅ Проверьте работу на реальном устройстве
4. ✅ Обновите документацию для защиты диплома

## Полезные команды

```bash
# Проверить статус Render сервиса
curl https://student-connect-backend.onrender.com/

# Посмотреть логи на Render
# Откройте Dashboard → Logs

# Подключиться к PostgreSQL на Render
# Используйте External Database URL из Render Dashboard
psql "postgresql://user:pass@host/db"

# Список таблиц
\dt

# Количество пользователей
SELECT COUNT(*) FROM users;
```

---

**Рекомендация:** Используйте Вариант 1 (Render) для быстрого тестирования без локальной установки PostgreSQL.
