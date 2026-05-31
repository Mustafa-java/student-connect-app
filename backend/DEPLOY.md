# 🚀 Быстрый деплой на Render с PostgreSQL

## Что нужно сделать

### 1. Создать PostgreSQL базу данных на Render

1. Откройте: https://dashboard.render.com
2. Нажмите **"New +"** → **"PostgreSQL"**
3. Настройки:
   - Name: `student-connect-db`
   - Database: `student_connect`
   - Region: Frankfurt (EU)
   - Plan: **Free**
4. Нажмите **"Create Database"**
5. Скопируйте **"Internal Database URL"**

### 2. Настроить Web Service

1. Откройте: https://dashboard.render.com/web/srv-d8csddt7vvec73ckovt0
2. Перейдите в **"Environment"**
3. Добавьте/обновите переменные:
   ```
   DATABASE_URL = (вставьте Internal Database URL)
   JWT_SECRET = student-connect-secret-key-2026
   NODE_ENV = production
   ```
4. Сохраните изменения

### 3. Деплой кода

```bash
cd "C:\Users\admin\vs_code_dock\flutter_apps\student-connect-app"
git add .
git commit -m "Migrate to PostgreSQL"
git push origin main
```

### 4. Проверка (через 3-5 минут)

```bash
curl https://student-connect-backend.onrender.com/
```

Должен вернуть:
```json
{
  "name": "Student Connect API",
  "version": "2.0.0",
  "database": "PostgreSQL",
  "status": "running"
}
```

## Готово! ✅

Backend теперь работает с PostgreSQL.

Подробная инструкция: [TESTING.md](./TESTING.md)
