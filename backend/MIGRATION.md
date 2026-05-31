# Миграция с SQLite на PostgreSQL

## Обзор

Этот проект был мигрирован с SQLite на PostgreSQL для улучшения производительности и масштабируемости.

## Что изменилось

### Backend код
- ✅ `database.js` - переписан для использования PostgreSQL (пакет `pg`)
- ✅ `server.js` - все SQL запросы обновлены для PostgreSQL синтаксиса
- ✅ Добавлен `dotenv` для управления переменными окружения
- ✅ Создан миграционный скрипт `migrate-sqlite-to-postgres.js`

### Зависимости
- ✅ Добавлен `pg` (PostgreSQL клиент)
- ✅ Добавлен `dotenv` (переменные окружения)
- ✅ Добавлен `sqlite3` (dev dependency, только для миграции)

## Настройка локальной разработки

### 1. Установка PostgreSQL

**Windows:**
```bash
# Скачать и установить PostgreSQL с официального сайта
# https://www.postgresql.org/download/windows/
```

**macOS:**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Linux:**
```bash
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql
```

### 2. Создание базы данных

```bash
# Войти в PostgreSQL
psql -U postgres

# Создать базу данных
CREATE DATABASE student_connect;

# Создать пользователя (опционально)
CREATE USER student_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE student_connect TO student_user;

# Выйти
\q
```

### 3. Настройка переменных окружения

Скопируйте `.env.example` в `.env` и обновите значения:

```bash
cp .env.example .env
```

Отредактируйте `.env`:
```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/student_connect
JWT_SECRET=student-connect-secret-key-2026
NODE_ENV=development
PORT=3000
```

### 4. Установка зависимостей

```bash
npm install
```

### 5. Инициализация схемы базы данных

При первом запуске сервер автоматически создаст все таблицы:

```bash
npm start
```

### 6. Миграция данных из SQLite (опционально)

Если у вас есть существующая база данных SQLite с данными:

```bash
npm run migrate
```

Этот скрипт:
- Подключится к SQLite (`student_connect.db`)
- Подключится к PostgreSQL (используя `DATABASE_URL`)
- Перенесет все данные из всех таблиц
- Пропустит дубликаты (ON CONFLICT DO NOTHING)

## Настройка на Render.com

### 1. Создание PostgreSQL базы данных

1. Войдите в [Render Dashboard](https://dashboard.render.com)
2. Нажмите "New +" → "PostgreSQL"
3. Заполните форму:
   - **Name:** student-connect-db
   - **Database:** student_connect
   - **User:** (автоматически)
   - **Region:** Frankfurt (или ближайший)
   - **Plan:** Free
4. Нажмите "Create Database"
5. Скопируйте **Internal Database URL**

### 2. Настройка Web Service

1. Откройте ваш Web Service на Render
2. Перейдите в "Environment"
3. Добавьте переменную окружения:
   - **Key:** `DATABASE_URL`
   - **Value:** (вставьте Internal Database URL)
4. Убедитесь, что `JWT_SECRET` установлен
5. Сохраните изменения

### 3. Деплой

```bash
git add .
git commit -m "Migrate to PostgreSQL"
git push origin main
```

Render автоматически:
- Установит зависимости (`npm install`)
- Запустит сервер (`npm start`)
- Сервер создаст схему базы данных при первом запуске

### 4. Миграция данных (если нужно)

Если нужно перенести данные из старой SQLite базы:

1. Скачайте `student_connect.db` с Render (если она там была)
2. Запустите миграцию локально:
   ```bash
   # В .env укажите production DATABASE_URL
   npm run migrate
   ```

## Проверка работы

### Локально

```bash
# Запустить сервер
npm start

# В другом терминале проверить
curl http://localhost:3000/
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

### Production

```bash
curl https://student-connect-backend.onrender.com/
```

## Различия между SQLite и PostgreSQL

### Типы данных
- SQLite `INTEGER` → PostgreSQL `INTEGER`
- SQLite `TEXT` → PostgreSQL `TEXT`
- SQLite `BIGINT` → PostgreSQL `BIGINT`

### Параметризованные запросы
- SQLite: `?` (позиционные)
- PostgreSQL: `$1, $2, $3` (нумерованные)

### Автоинкремент
- SQLite: `AUTOINCREMENT`
- PostgreSQL: `SERIAL` или `GENERATED ALWAYS AS IDENTITY`

Примечание: В нашем проекте используются UUID, поэтому автоинкремент не нужен.

### Булевы значения
- SQLite: `0` и `1` (INTEGER)
- PostgreSQL: `INTEGER` (для совместимости оставили 0/1)

## Откат на SQLite (если нужно)

Если по какой-то причине нужно вернуться на SQLite:

1. Восстановите старые файлы из git:
   ```bash
   git checkout <commit-before-migration> -- backend/database.js backend/server.js
   ```

2. Обновите `package.json`:
   ```bash
   npm uninstall pg dotenv
   npm install sql.js
   ```

3. Удалите `.env` файл

## Полезные команды PostgreSQL

```bash
# Подключиться к базе
psql -U postgres -d student_connect

# Список таблиц
\dt

# Описание таблицы
\d users

# Количество записей
SELECT COUNT(*) FROM users;

# Выйти
\q
```

## Troubleshooting

### "Connection refused"
- Проверьте, что PostgreSQL запущен: `pg_isready`
- Проверьте `DATABASE_URL` в `.env`

### "password authentication failed"
- Проверьте username и password в `DATABASE_URL`
- Убедитесь, что пользователь существует в PostgreSQL

### "database does not exist"
- Создайте базу данных: `createdb student_connect`

### "relation does not exist"
- Схема не создана. Перезапустите сервер: `npm start`

## Дополнительная информация

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [node-postgres (pg) Documentation](https://node-postgres.com/)
- [Render PostgreSQL Guide](https://render.com/docs/databases)

---

**Дата миграции:** 2026-05-31  
**Версия:** 2.0.0
