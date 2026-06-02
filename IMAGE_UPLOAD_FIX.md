# Исправление загрузки и отображения изображений

## Проблема

Изображения постов, созданные на одном устройстве, не отображались на другом устройстве.

**Причина:** 
- Flutter передавал локальные пути к изображениям (например, `/data/user/0/.../posts/post_123.jpg`)
- Backend просто сохранял эти пути в базу данных
- Другое устройство получало чужие локальные пути, которые у него не существуют

## Решение

### 1. Backend (server.js)

**Добавлено:**
- Новый multer middleware `uploadImages` для обработки изображений
- Раздача статических файлов из `/uploads/` через `express.static`
- Изменен эндпоинт `POST /api/posts` для приема файлов через multipart/form-data
- Изменен эндпоинт `POST /api/projects` для приема файлов через multipart/form-data

**Как работает:**
```javascript
// Принимаем до 5 изображений
app.post('/api/posts', authMiddleware, uploadImages.array('images', 5), async (req, res) => {
  // Сохраняем файлы в uploads/ и получаем их URL
  const imageUrls = req.files ? req.files.map(file => `/uploads/${file.filename}`) : [];
  
  // Сохраняем URL в базу данных
  await pool.query('INSERT INTO posts (..., images) VALUES (..., $5)', [..., JSON.stringify(imageUrls)]);
});

// Раздаем файлы по HTTP
app.use('/uploads', express.static(UPLOADS_DIR));
```

### 2. Flutter (api_service.dart)

**Изменено:**
- Метод `createPost()` теперь отправляет файлы через `FormData` вместо JSON
- Метод `createProject()` теперь отправляет файлы через `FormData` вместо JSON
- Функция `_parsePost()` конвертирует относительные пути (`/uploads/...`) в полные URL
- Функция `_parseProject()` конвертирует относительные пути (`/uploads/...`) в полные URL

**Как работает:**
```dart
// Создаем FormData и добавляем файлы
final formData = FormData();
for (final imagePath in images) {
  final file = File(imagePath);
  if (await file.exists()) {
    formData.files.add(MapEntry(
      'images',
      await MultipartFile.fromFile(imagePath, filename: fileName),
    ));
  }
}

// Отправляем с правильным content-type
await _dio.post('/api/posts', 
  data: formData,
  options: Options(headers: {'Content-Type': 'multipart/form-data'}),
);

// При получении конвертируем пути в URL
images = List<String>.from(rawImages).map((img) {
  if (img.startsWith('/uploads/')) {
    return '$_baseUrl$img'; // https://student-connect-backend.onrender.com/uploads/...
  }
  return img;
}).toList();
```

## Что изменилось для пользователей

### ДО исправления:
1. Пользователь создает пост с фото на устройстве А
2. Изображение сохраняется локально: `/data/user/0/.../post_123.jpg`
3. Этот путь сохраняется в базу данных
4. Устройство Б получает этот путь из БД
5. ❌ Изображение не отображается (путь не существует на устройстве Б)

### ПОСЛЕ исправления:
1. Пользователь создает пост с фото на устройстве А
2. Flutter отправляет файл изображения на сервер
3. Backend сохраняет файл в `uploads/post_1717349925-uuid.jpg`
4. Backend сохраняет в БД: `/uploads/post_1717349925-uuid.jpg`
5. Устройство Б получает путь из БД
6. Flutter конвертирует в полный URL: `https://student-connect-backend.onrender.com/uploads/post_1717349925-uuid.jpg`
7. ✅ Изображение загружается и отображается

## Тестирование

1. Запустить backend: `cd backend && npm start`
2. Запустить Flutter на устройстве 1: `flutter run`
3. Создать пост с изображением на устройстве 1
4. Запустить Flutter на устройстве 2: `flutter run -d <device-2>`
5. Проверить, что изображение отображается на устройстве 2

## Обратная совместимость

Старые посты с локальными путями останутся сломанными. Для их исправления можно:
- Вручную удалить старые посты
- Написать миграционный скрипт (не требуется для дипломной работы)

## Файлы изменены

### Backend:
- `backend/server.js` - добавлен multer для изображений, изменены POST /api/posts и POST /api/projects

### Flutter:
- `lib/services/api_service.dart` - изменены createPost(), createProject(), _parsePost(), _parseProject()

## Дата исправления
2026-06-02
