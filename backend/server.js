require('dotenv').config();

const express = require('express');
const https = require('https');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { pool, initDatabase } = require('./database');
const cloudinary = require('./cloudinary');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'student-connect-secret-key';

// Получить базовый URL сервера
function getBaseUrl(req) {
  return `${req.protocol}://${req.get('host')}`;
}

// Конвертировать пути изображений в полные URL
function convertImageUrls(images, baseUrl) {
  if (!images) return [];
  try {
    const imageArray = typeof images === 'string' ? JSON.parse(images) : images;
    return imageArray.map(img => {
      if (img.startsWith('/uploads/')) {
        return `${baseUrl}${img}`;
      }
      return img;
    });
  } catch (e) {
    return [];
  }
}

function parseParticipantIds(participantIds) {
  if (!participantIds) return [];
  try {
    const parsed = JSON.parse(participantIds);
    return Array.isArray(parsed) ? parsed : [];
  } catch (e) {
    return participantIds.split(',').filter(Boolean);
  }
}

// Создаём папку uploads если нет
// Временная папка для multer (файлы удаляются после загрузки в Cloudinary)
const UPLOADS_DIR = path.join(__dirname, 'uploads');
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Настройка multer для ZIP файлов
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOADS_DIR),
  filename: (req, file, cb) => {
    const uniqueName = `${Date.now()}-${uuidv4()}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  }
});
const upload = multer({
  storage,
  limits: { fileSize: 50 * 1024 * 1024 }, // 50MB max
  fileFilter: (req, file, cb) => {
    const allowed = ['.zip', '.rar', '.7z', '.tar', '.gz'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowed.includes(ext) || file.mimetype.includes('zip') || file.mimetype.includes('archive')) {
      cb(null, true);
    } else {
      cb(new Error('Только ZIP/архивы файлы'));
    }
  }
});

// Настройка multer для изображений/видео постов
const imageStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOADS_DIR),
  filename: (req, file, cb) => {
    const uniqueName = `post_${Date.now()}-${uuidv4()}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  }
});
const uploadImages = multer({
  storage: imageStorage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max per image
  fileFilter: (req, file, cb) => {
    const allowed = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowed.includes(ext) || file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Только изображения'));
    }
  }
});

// Настройка multer для видео
const videoStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOADS_DIR),
  filename: (req, file, cb) => {
    const uniqueName = `video_${Date.now()}-${uuidv4()}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  }
});
const uploadVideo = multer({
  storage: videoStorage,
  limits: { fileSize: 100 * 1024 * 1024 }, // 100MB max
  fileFilter: (req, file, cb) => {
    const allowed = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowed.includes(ext) || file.mimetype.startsWith('video/')) {
      cb(null, true);
    } else {
      cb(new Error('Только видео файлы'));
    }
  }
});

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true }));

// Раздавать статические файлы из uploads/
app.use('/uploads', express.static(UPLOADS_DIR));

// Логирование запросов
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Не авторизован' });
  try {
    req.userId = jwt.verify(token, JWT_SECRET).userId;
    next();
  } catch (e) {
    res.status(401).json({ error: 'Неверный токен' });
  }
}

function sanitizeUser(u) {
  if (!u) return null;
  const { password_hash, ...r } = u;
  return r;
}

// ==================== ROOT ====================

app.get('/', (req, res) => {
  res.json({
    name: 'Student Connect API',
    version: '2.0.0',
    database: 'PostgreSQL',
    status: 'running',
    endpoints: {
      auth: '/api/auth/*',
      users: '/api/users',
      posts: '/api/posts',
      projects: '/api/projects',
      chats: '/api/chats',
      messages: '/api/chats/:id/messages'
    }
  });
});

// ==================== AUTH ====================

app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password, university, faculty, course, bio, skills, avatar_url } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'name, email, password обязательны' });
    }

    const existing = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'Email уже занят' });
    }

    const hash = await bcrypt.hash(password, 10);
    const uid = uuidv4();

    await pool.query(
      `INSERT INTO users (id, name, email, password_hash, avatar_url, bio, university, faculty, course, skills)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
      [uid, name, email, hash, avatar_url || null, bio || null, university || null, faculty || null, course || null, JSON.stringify(skills || [])]
    );

    const token = jwt.sign({ userId: uid }, JWT_SECRET, { expiresIn: '30d' });
    const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [uid]);
    res.status(201).json({ token, user: sanitizeUser(userResult.rows[0]) });
  } catch(e) {
    console.error('Register error:', e);
    res.status(500).json({ error: 'Ошибка регистрации' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    console.log('Login attempt:', req.body.email);
    const { email, password } = req.body;

    if (!email || !password) {
      console.log('Missing email or password');
      return res.status(400).json({ error: 'Email и пароль обязательны' });
    }

    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      console.log('User not found:', email);
      return res.status(401).json({ error: 'Неверный email или пароль' });
    }

    const user = result.rows[0];
    console.log('User found:', user.name);

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      console.log('Invalid password for user:', email);
      return res.status(401).json({ error: 'Неверный email или пароль' });
    }

    await pool.query('UPDATE users SET is_online = 1, last_seen = $1 WHERE id = $2', [Date.now(), user.id]);
    const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '30d' });
    console.log('Login successful for:', user.name);
    res.json({ token, user: sanitizeUser(user) });
  } catch(e) {
    console.error('Login error:', e);
    res.status(500).json({ error: 'Ошибка сервера: ' + e.message });
  }
});

app.get('/api/auth/me', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [req.userId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Не найден' });
    }
    res.json({ user: sanitizeUser(result.rows[0]) });
  } catch(e) {
    res.status(500).json({ error: 'Ошибка' });
  }
});

// ==================== USERS ====================

app.get('/api/users', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users ORDER BY created_at DESC LIMIT 100');
    res.json({ users: result.rows.map(sanitizeUser) });
  } catch(e) {
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.get('/api/users/search', authMiddleware, async (req, res) => {
  try {
    const { q } = req.query;
    if (!q) return res.json({ users: [] });

    const result = await pool.query(
      'SELECT * FROM users WHERE name ILIKE $1 AND id != $2 ORDER BY name LIMIT 20',
      [`%${q}%`, req.userId]
    );
    res.json({ users: result.rows.map(sanitizeUser) });
  } catch(e) {
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.get('/api/users/:id', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Не найден' });
    }
    res.json({ user: sanitizeUser(result.rows[0]) });
  } catch(e) {
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.put('/api/users/:id', authMiddleware, async (req, res) => {
  try {
    if (req.params.id !== req.userId) {
      return res.status(403).json({ error: 'Нет доступа' });
    }

    const { name, bio, university, faculty, course, skills, avatar_url } = req.body;

    await pool.query(
      `UPDATE users SET
        name = COALESCE($1, name),
        bio = COALESCE($2, bio),
        university = COALESCE($3, university),
        faculty = COALESCE($4, faculty),
        course = COALESCE($5, course),
        skills = COALESCE($6, skills),
        avatar_url = COALESCE($7, avatar_url)
      WHERE id = $8`,
      [name || null, bio || null, university || null, faculty || null, course || null,
       skills ? JSON.stringify(skills) : null, avatar_url || null, req.userId]
    );

    const result = await pool.query('SELECT * FROM users WHERE id = $1', [req.userId]);
    res.json({ user: sanitizeUser(result.rows[0]) });
  } catch(e) {
    res.status(500).json({ error: 'Ошибка' });
  }
});

// ==================== POSTS ====================

async function enrichPost(postId, userId) {
  const likeResult = await pool.query(
    'SELECT 1 FROM post_likes WHERE post_id = $1 AND user_id = $2',
    [postId, userId]
  );
  return likeResult.rows.length > 0;
}

async function enrichPostSaved(postId, userId) {
  const result = await pool.query(
    'SELECT 1 FROM saved_posts WHERE post_id = $1 AND user_id = $2',
    [postId, userId]
  );
  return result.rows.length > 0;
}

async function enrichProjectSaved(projectId, userId) {
  const result = await pool.query(
    'SELECT 1 FROM saved_projects WHERE project_id = $1 AND user_id = $2',
    [projectId, userId]
  );
  return result.rows.length > 0;
}

app.get('/api/posts', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT p.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.university as author_university, u.is_online as author_is_online,
             u.skills as author_skills, u.projects_count as author_projects_count,
             u.followers_count as author_followers_count, u.following_count as author_following_count
      FROM posts p JOIN users u ON p.author_id = u.id
      ORDER BY p.created_at DESC LIMIT 50
    `);

    const baseUrl = getBaseUrl(req);
    const posts = await Promise.all(result.rows.map(async (p) => {
      let video_url = p.video_url;
      if (video_url && video_url.startsWith('/uploads/')) video_url = `${baseUrl}${video_url}`;
      let video_thumbnail_url = p.video_thumbnail_url;
      if (video_thumbnail_url && video_thumbnail_url.startsWith('/uploads/')) video_thumbnail_url = `${baseUrl}${video_thumbnail_url}`;
      return {
        ...p,
        video_url,
        video_thumbnail_url,
        images: JSON.stringify(convertImageUrls(p.images, baseUrl)),
        author_skills: JSON.parse(p.author_skills || '[]'),
        is_liked: await enrichPost(p.id, req.userId),
        is_saved: await enrichPostSaved(p.id, req.userId)
      };
    }));

    res.json({ posts });
  } catch(e) {
    console.error('Get posts error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

const postUpload = multer({
  storage: imageStorage,
  limits: { fileSize: 100 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const imageExts = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    const videoExts = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (imageExts.includes(ext) || videoExts.includes(ext) ||
        file.mimetype.startsWith('image/') || file.mimetype.startsWith('video/')) {
      cb(null, true);
    } else {
      cb(new Error('Только изображения и видео'));
    }
  }
});

app.post('/api/posts', authMiddleware, postUpload.fields([
  { name: 'images', maxCount: 5 },
  { name: 'video', maxCount: 1 }
]), async (req, res) => {
  try {
    const { content, project_id, tags } = req.body;
    const id = uuidv4();

    const uploadedFiles = req.files || {};
    const imageFiles = uploadedFiles['images'] || [];
    const videoFiles = uploadedFiles['video'] || [];

    // Загружаем изображения последовательно (избегаем rate limit Cloudinary)
    const imageUrls = [];
    for (let i = 0; i < imageFiles.length; i++) {
      const url = await cloudinary.uploadImage(imageFiles[i].path, id, i);
      imageUrls.push(url);
    }

    // Загружаем видео в R2
    let videoUrl = null;
    let videoThumbnailUrl = null;
    if (videoFiles.length > 0) {
      videoUrl = await cloudinary.uploadVideo(videoFiles[0].path, id);
      videoThumbnailUrl = cloudinary.getVideoThumbnailUrl(videoUrl);
    }

    // Удаляем временные файлы
    for (const f of [...imageFiles, ...videoFiles]) {
      try { fs.unlinkSync(f.path); } catch (_) {}
    }

    // Парсим tags если это строка
    let tagsArray = [];
    if (tags) {
      try {
        tagsArray = typeof tags === 'string' ? JSON.parse(tags) : tags;
      } catch (e) {
        tagsArray = [];
      }
    }

    if (videoUrl) {
      await pool.query(
        'INSERT INTO posts (id, author_id, content, project_id, images, tags, video_url, video_thumbnail_url) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
        [id, req.userId, content || null, project_id || null, JSON.stringify(imageUrls), JSON.stringify(tagsArray), videoUrl, videoThumbnailUrl]
      );
    } else {
      await pool.query(
        'INSERT INTO posts (id, author_id, content, project_id, images, tags) VALUES ($1, $2, $3, $4, $5, $6)',
        [id, req.userId, content || null, project_id || null, JSON.stringify(imageUrls), JSON.stringify(tagsArray)]
      );
    }

    const result = await pool.query(`
      SELECT p.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.university as author_university, u.is_online as author_is_online,
             u.skills as author_skills, u.projects_count as author_projects_count,
             u.followers_count as author_followers_count, u.following_count as author_following_count
      FROM posts p JOIN users u ON p.author_id = u.id WHERE p.id = $1
    `, [id]);

    const post = result.rows[0];
    post.images = JSON.stringify(imageUrls);
    post.video_url = videoUrl;
    post.video_thumbnail_url = videoThumbnailUrl;
    post.author_skills = JSON.parse(post.author_skills || '[]');
    post.is_liked = await enrichPost(post.id, req.userId);
    post.is_saved = await enrichPostSaved(post.id, req.userId);

    console.log('Post created with images:', imageUrls.length, 'video:', !!videoUrl);
    res.status(201).json({ post });
  } catch(e) {
    console.error('Create post error:', e);
    res.status(500).json({ error: 'Ошибка создания поста' });
  }
});

app.post('/api/posts/:id/like', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const likeCheck = await pool.query(
      'SELECT 1 FROM post_likes WHERE post_id = $1 AND user_id = $2',
      [id, req.userId]
    );

    if (likeCheck.rows.length > 0) {
      await pool.query('DELETE FROM post_likes WHERE post_id = $1 AND user_id = $2', [id, req.userId]);
      await pool.query('UPDATE posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = $1', [id]);
    } else {
      await pool.query('INSERT INTO post_likes (post_id, user_id) VALUES ($1, $2)', [id, req.userId]);
      await pool.query('UPDATE posts SET likes_count = likes_count + 1 WHERE id = $1', [id]);
    }

    const result = await pool.query('SELECT likes_count FROM posts WHERE id = $1', [id]);
    const isLiked = await enrichPost(id, req.userId);

    res.json({ is_liked: isLiked, likes_count: result.rows[0]?.likes_count || 0 });
  } catch(e) {
    console.error('Like post error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.delete('/api/posts/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const postResult = await pool.query('SELECT * FROM posts WHERE id = $1', [id]);

    if (postResult.rows.length === 0) {
      return res.status(404).json({ error: 'Пост не найден' });
    }

    if (postResult.rows[0].author_id !== req.userId) {
      return res.status(403).json({ error: 'Нет доступа' });
    }

    // Удаляем файлы из R2
    await cloudinary.deletePostFiles(id);

    await pool.query('DELETE FROM post_likes WHERE post_id = $1', [id]);
    await pool.query('DELETE FROM comments WHERE post_id = $1', [id]);
    await pool.query('DELETE FROM posts WHERE id = $1', [id]);

    console.log('Post deleted:', id);
    res.json({ ok: true });
  } catch(e) {
    console.error('Delete post error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.put('/api/posts/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { content, tags } = req.body;
    
    const postResult = await pool.query('SELECT * FROM posts WHERE id = $1', [id]);
    
    if (postResult.rows.length === 0) {
      return res.status(404).json({ error: 'Пост не найден' });
    }
    
    if (postResult.rows[0].author_id !== req.userId) {
      return res.status(403).json({ error: 'Нет доступа' });
    }
    
    let tagsArray = [];
    if (tags) {
      try {
        tagsArray = typeof tags === 'string' ? JSON.parse(tags) : tags;
      } catch (e) {
        tagsArray = [];
      }
    }
    
    await pool.query(
      'UPDATE posts SET content = $1, tags = $2 WHERE id = $3',
      [content || null, JSON.stringify(tagsArray), id]
    );
    
    const result = await pool.query(`
      SELECT p.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.university as author_university, u.is_online as author_is_online,
             u.skills as author_skills, u.projects_count as author_projects_count,
             u.followers_count as author_followers_count, u.following_count as author_following_count
      FROM posts p JOIN users u ON p.author_id = u.id WHERE p.id = $1
    `, [id]);
    
    const baseUrl = getBaseUrl(req);
    const post = result.rows[0];
    post.images = JSON.stringify(convertImageUrls(post.images, baseUrl));
    if (post.video_url) post.video_url = post.video_url.startsWith('/uploads/') ? `${baseUrl}${post.video_url}` : post.video_url;
    if (post.video_thumbnail_url) post.video_thumbnail_url = post.video_thumbnail_url.startsWith('/uploads/') ? `${baseUrl}${post.video_thumbnail_url}` : post.video_thumbnail_url;
    post.author_skills = JSON.parse(post.author_skills || '[]');
    post.is_liked = await enrichPost(post.id, req.userId);
    post.is_saved = await enrichPostSaved(post.id, req.userId);
    
    console.log('Post updated:', id);
    res.json({ post });
  } catch(e) {
    console.error('Update post error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// ==================== POST SAVE/UNSAVE ====================

app.post('/api/posts/:id/save', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const check = await pool.query(
      'SELECT 1 FROM saved_posts WHERE post_id = $1 AND user_id = $2',
      [id, req.userId]
    );

    if (check.rows.length > 0) {
      await pool.query('DELETE FROM saved_posts WHERE post_id = $1 AND user_id = $2', [id, req.userId]);
    } else {
      await pool.query('INSERT INTO saved_posts (post_id, user_id) VALUES ($1, $2)', [id, req.userId]);
    }

    const isSaved = await enrichPostSaved(id, req.userId);
    res.json({ is_saved: isSaved });
  } catch(e) {
    console.error('Save post error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// ==================== GET SAVED ITEMS ====================

app.get('/api/saved/posts', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT p.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.university as author_university, u.is_online as author_is_online,
             u.skills as author_skills, u.projects_count as author_projects_count,
             u.followers_count as author_followers_count, u.following_count as author_following_count
      FROM posts p
      JOIN users u ON p.author_id = u.id
      JOIN saved_posts sp ON sp.post_id = p.id
      WHERE sp.user_id = $1
      ORDER BY sp.created_at DESC
    `, [req.userId]);

    const baseUrl = getBaseUrl(req);
    const posts = await Promise.all(result.rows.map(async (p) => ({
      ...p,
      images: JSON.stringify(convertImageUrls(p.images, baseUrl)),
      author_skills: JSON.parse(p.author_skills || '[]'),
      is_liked: await enrichPost(p.id, req.userId),
      is_saved: true
    })));

    res.json({ posts });
  } catch(e) {
    console.error('Get saved posts error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.get('/api/saved/projects', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT p.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.university as author_university, u.is_online as author_is_online,
             u.skills as author_skills, u.projects_count as author_projects_count,
             u.followers_count as author_followers_count, u.following_count as author_following_count
      FROM projects p
      JOIN users u ON p.author_id = u.id
      JOIN saved_projects sp ON sp.project_id = p.id
      WHERE sp.user_id = $1
      ORDER BY sp.created_at DESC
    `, [req.userId]);

    const baseUrl = getBaseUrl(req);
    const projects = await Promise.all(result.rows.map(async (p) => ({
      ...p,
      images: JSON.stringify(convertImageUrls(p.images, baseUrl)),
      author_skills: JSON.parse(p.author_skills || '[]'),
      team_members: JSON.parse(p.team_members || '[]'),
      is_liked: await enrichProject(p.id, req.userId),
      is_saved: true
    })));

    res.json({ projects });
  } catch(e) {
    console.error('Get saved projects error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// ==================== COMMENTS ====================

app.get('/api/posts/:id/comments', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT c.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.is_online as author_is_online
      FROM comments c JOIN users u ON c.author_id = u.id
      WHERE c.post_id = $1 ORDER BY c.created_at ASC
    `, [req.params.id]);

    res.json({ comments: result.rows });
  } catch(e) {
    console.error('Get comments error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.post('/api/posts/:id/comments', authMiddleware, async (req, res) => {
  try {
    const { content, reply_to_id } = req.body;
    if (!content) {
      return res.status(400).json({ error: 'content обязателен' });
    }

    const id = uuidv4();
    await pool.query(
      'INSERT INTO comments (id, post_id, author_id, content, reply_to_id) VALUES ($1, $2, $3, $4, $5)',
      [id, req.params.id, req.userId, content, reply_to_id || null]
    );

    await pool.query('UPDATE posts SET comments_count = comments_count + 1 WHERE id = $1', [req.params.id]);

    const result = await pool.query(`
      SELECT c.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.is_online as author_is_online
      FROM comments c JOIN users u ON c.author_id = u.id WHERE c.id = $1
    `, [id]);

    res.status(201).json({ comment: result.rows[0] });
  } catch(e) {
    console.error('Create comment error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// ==================== PROJECTS ====================

async function enrichProject(projectId, userId) {
  const likeResult = await pool.query(
    'SELECT 1 FROM project_likes WHERE project_id = $1 AND user_id = $2',
    [projectId, userId]
  );
  return likeResult.rows.length > 0;
}

app.get('/api/projects', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT p.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.university as author_university, u.is_online as author_is_online,
             u.skills as author_skills, u.projects_count as author_projects_count,
             u.followers_count as author_followers_count, u.following_count as author_following_count
      FROM projects p JOIN users u ON p.author_id = u.id
      ORDER BY p.created_at DESC LIMIT 50
    `);

    const baseUrl = getBaseUrl(req);
    const projects = await Promise.all(result.rows.map(async (p) => ({
      ...p,
      images: JSON.stringify(convertImageUrls(p.images, baseUrl)),
      author_skills: JSON.parse(p.author_skills || '[]'),
      team_members: JSON.parse(p.team_members || '[]'),
      is_liked: await enrichProject(p.id, req.userId),
      is_saved: await enrichProjectSaved(p.id, req.userId)
    })));

    res.json({ projects });
  } catch(e) {
    console.error('Get projects error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.post('/api/projects', authMiddleware, uploadImages.array('images', 5), async (req, res) => {
  try {
    const { title, description, skills, status, university_tags } = req.body;
    if (!title || !description) {
      return res.status(400).json({ error: 'title и description обязательны' });
    }

    const id = uuidv4();

    // Получаем URL загруженных изображений
    const imageUrls = req.files ? req.files.map(file => `/uploads/${file.filename}`) : [];

    // Парсим массивы если это строки
    let skillsArray = [];
    if (skills) {
      try {
        skillsArray = typeof skills === 'string' ? JSON.parse(skills) : skills;
      } catch (e) {
        skillsArray = [];
      }
    }

    let universityTagsArray = [];
    if (university_tags) {
      try {
        universityTagsArray = typeof university_tags === 'string' ? JSON.parse(university_tags) : university_tags;
      } catch (e) {
        universityTagsArray = [];
      }
    }

    await pool.query(
      `INSERT INTO projects (id, author_id, title, description, images, skills, status, university_tags)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [id, req.userId, title, description, JSON.stringify(imageUrls),
       JSON.stringify(skillsArray), status || 'idea', JSON.stringify(universityTagsArray)]
    );

    await pool.query('UPDATE users SET projects_count = projects_count + 1 WHERE id = $1', [req.userId]);

    const result = await pool.query(`
      SELECT p.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.university as author_university, u.is_online as author_is_online,
             u.skills as author_skills, u.projects_count as author_projects_count,
             u.followers_count as author_followers_count, u.following_count as author_following_count
      FROM projects p JOIN users u ON p.author_id = u.id WHERE p.id = $1
    `, [id]);

    const baseUrl = getBaseUrl(req);
    const project = result.rows[0];
    project.images = JSON.stringify(convertImageUrls(project.images, baseUrl));
    project.author_skills = JSON.parse(project.author_skills || '[]');
    project.team_members = JSON.parse(project.team_members || '[]');
    project.is_liked = await enrichProject(project.id, req.userId);
    project.is_saved = await enrichProjectSaved(project.id, req.userId);

    console.log('Project created with images:', imageUrls);
    res.status(201).json({ project });
  } catch(e) {
    console.error('Create project error:', e);
    res.status(500).json({ error: 'Ошибка создания проекта' });
  }
});

app.post('/api/projects/:id/views', authMiddleware, async (req, res) => {
  try {
    await pool.query('UPDATE projects SET views_count = views_count + 1 WHERE id = $1', [req.params.id]);
    res.json({ ok: true });
  } catch(e) {
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.post('/api/projects/:id/like', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const likeCheck = await pool.query(
      'SELECT 1 FROM project_likes WHERE project_id = $1 AND user_id = $2',
      [id, req.userId]
    );

    if (likeCheck.rows.length > 0) {
      await pool.query('DELETE FROM project_likes WHERE project_id = $1 AND user_id = $2', [id, req.userId]);
      await pool.query('UPDATE projects SET likes_count = GREATEST(0, likes_count - 1) WHERE id = $1', [id]);
    } else {
      await pool.query('INSERT INTO project_likes (project_id, user_id) VALUES ($1, $2)', [id, req.userId]);
      await pool.query('UPDATE projects SET likes_count = likes_count + 1 WHERE id = $1', [id]);
    }

    const result = await pool.query('SELECT likes_count FROM projects WHERE id = $1', [id]);
    const isLiked = await enrichProject(id, req.userId);

    res.json({ is_liked: isLiked, likes_count: result.rows[0]?.likes_count || 0 });
  } catch(e) {
    console.error('Like project error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.delete('/api/projects/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const projectResult = await pool.query('SELECT * FROM projects WHERE id = $1', [id]);

    if (projectResult.rows.length === 0) {
      return res.status(404).json({ error: 'Проект не найден' });
    }

    const project = projectResult.rows[0];
    if (project.author_id !== req.userId) {
      return res.status(403).json({ error: 'Нет доступа' });
    }

    // Удаляем файлы из R2
    await cloudinary.deleteProjectFiles(id);

    await pool.query('DELETE FROM project_likes WHERE project_id = $1', [id]);

    if (project.zip_file_disk_name) {
      const filePath = path.join(UPLOADS_DIR, project.zip_file_disk_name);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        console.log('Deleted file:', filePath);
      }
    }

    await pool.query('DELETE FROM projects WHERE id = $1', [id]);

    console.log('Project deleted:', id);
    res.json({ ok: true });
  } catch(e) {
    console.error('Delete project error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.put('/api/projects/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, skills, status } = req.body;
    
    const projectResult = await pool.query('SELECT * FROM projects WHERE id = $1', [id]);
    
    if (projectResult.rows.length === 0) {
      return res.status(404).json({ error: 'Проект не найден' });
    }
    
    if (projectResult.rows[0].author_id !== req.userId) {
      return res.status(403).json({ error: 'Нет доступа' });
    }
    
    let skillsArray = [];
    if (skills) {
      try {
        skillsArray = typeof skills === 'string' ? JSON.parse(skills) : skills;
      } catch (e) {
        skillsArray = [];
      }
    }
    
    await pool.query(
      'UPDATE projects SET title = $1, description = $2, skills = $3, status = $4 WHERE id = $5',
      [title || null, description || null, JSON.stringify(skillsArray), status || 'idea', id]
    );
    
    const result = await pool.query(`
      SELECT p.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.university as author_university, u.is_online as author_is_online,
             u.skills as author_skills, u.projects_count as author_projects_count,
             u.followers_count as author_followers_count, u.following_count as author_following_count
      FROM projects p JOIN users u ON p.author_id = u.id WHERE p.id = $1
    `, [id]);
    
    const baseUrl = getBaseUrl(req);
    const project = result.rows[0];
    project.images = JSON.stringify(convertImageUrls(project.images, baseUrl));
    project.author_skills = JSON.parse(project.author_skills || '[]');
    project.team_members = JSON.parse(project.team_members || '[]');
    project.is_liked = await enrichProject(project.id, req.userId);
    project.is_saved = await enrichProjectSaved(project.id, req.userId);
    
    console.log('Project updated:', id);
    res.json({ project });
  } catch(e) {
    console.error('Update project error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// ==================== PROJECT SAVE/UNSAVE ====================

app.post('/api/projects/:id/save', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const check = await pool.query(
      'SELECT 1 FROM saved_projects WHERE project_id = $1 AND user_id = $2',
      [id, req.userId]
    );

    if (check.rows.length > 0) {
      await pool.query('DELETE FROM saved_projects WHERE project_id = $1 AND user_id = $2', [id, req.userId]);
    } else {
      await pool.query('INSERT INTO saved_projects (project_id, user_id) VALUES ($1, $2)', [id, req.userId]);
    }

    const isSaved = await enrichProjectSaved(id, req.userId);
    res.json({ is_saved: isSaved });
  } catch(e) {
    console.error('Save project error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// ==================== PROJECT ZIP FILES ====================

app.post('/api/projects/:id/upload-zip', authMiddleware, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Файл не загружен' });
    }

    const { id } = req.params;
    const projectResult = await pool.query('SELECT * FROM projects WHERE id = $1', [id]);

    if (projectResult.rows.length === 0) {
      return res.status(404).json({ error: 'Проект не найден' });
    }

    if (projectResult.rows[0].author_id !== req.userId) {
      return res.status(403).json({ error: 'Нет доступа' });
    }

    // Сохраняем файл локально на сервере
    const diskName = `${id}_${Date.now()}${path.extname(req.file.originalname)}`;
    const destPath = path.join(UPLOADS_DIR, diskName);

    // Удаляем старый ZIP если был
    const oldZip = projectResult.rows[0].zip_file_disk_name;
    if (oldZip) {
      const oldPath = path.join(UPLOADS_DIR, oldZip);
      try { fs.unlinkSync(oldPath); } catch (_) {}
    }

    fs.renameSync(req.file.path, destPath);
    const zipName = req.file.originalname;
    const zipSize = req.file.size;

    console.log('Saved zip locally:', { originalName: zipName, size: zipSize, diskName });

    await pool.query(
      'UPDATE projects SET zip_file_url = $1, zip_file_name = $2, zip_file_size = $3, zip_file_disk_name = $4 WHERE id = $5',
      [null, zipName, zipSize, diskName, id]
    );

    res.json({
      zip_file_url: null,
      zip_file_name: zipName,
      zip_file_size: zipSize
    });
  } catch(e) {
    console.error('Upload zip error:', e);
    res.status(500).json({ error: 'Ошибка загрузки файла' });
  }
});

app.get('/api/projects/:id/zip-file', authMiddleware, async (req, res) => {
  try {
    console.log('Download request for project:', req.params.id);
    const { id } = req.params;
    const projectResult = await pool.query('SELECT * FROM projects WHERE id = $1', [id]);

    if (projectResult.rows.length === 0) {
      console.log('Project not found:', id);
      return res.status(404).json({ error: 'Проект не найден' });
    }

    const project = projectResult.rows[0];
    if (!project.zip_file_url || !project.zip_file_name) {
      console.log('No zip file attached for project:', id);
      return res.status(404).json({ error: 'ZIP файл не прикреплён' });
    }

    // Файл на сервере (локальное хранение)
    const diskName = project.zip_file_disk_name;
    if (!diskName) {
      console.log('No disk name for zip:', id);
      return res.status(404).json({ error: 'Файл не найден' });
    }

    const filePath = path.join(UPLOADS_DIR, diskName);
    console.log('Looking for file:', diskName);

    if (!fs.existsSync(filePath)) {
      console.log('File not found on disk:', filePath);
      return res.status(404).json({ error: 'Файл не найден на сервере' });
    }

    const fileStats = fs.statSync(filePath);
    console.log('Found file:', diskName, 'Size:', fileStats.size, 'bytes');
    console.log('Original name:', project.zip_file_name);

    res.setHeader('Content-Disposition', `attachment; filename="${encodeURIComponent(project.zip_file_name)}"`);
    res.setHeader('Content-Type', 'application/zip');
    res.setHeader('Content-Length', fileStats.size);

    const fileStream = fs.createReadStream(filePath);
    fileStream.pipe(res);
  } catch(e) {
    console.error('Download error:', e);
    res.status(500).json({ error: 'Ошибка скачивания: ' + e.message });
  }
});

// ==================== PROJECT COMMENTS ====================

app.get('/api/projects/:id/comments', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT c.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.is_online as author_is_online
      FROM project_comments c JOIN users u ON c.author_id = u.id
      WHERE c.project_id = $1 ORDER BY c.created_at ASC
    `, [req.params.id]);

    res.json({ comments: result.rows });
  } catch(e) {
    console.error('Get project comments error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.post('/api/projects/:id/comments', authMiddleware, async (req, res) => {
  try {
    const { content, reply_to_id } = req.body;
    if (!content) {
      return res.status(400).json({ error: 'content обязателен' });
    }

    const id = uuidv4();
    await pool.query(
      'INSERT INTO project_comments (id, project_id, author_id, content, reply_to_id) VALUES ($1, $2, $3, $4, $5)',
      [id, req.params.id, req.userId, content, reply_to_id || null]
    );

    await pool.query('UPDATE projects SET comments_count = comments_count + 1 WHERE id = $1', [req.params.id]);

    const result = await pool.query(`
      SELECT c.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.is_online as author_is_online
      FROM project_comments c JOIN users u ON c.author_id = u.id WHERE c.id = $1
    `, [id]);

    res.status(201).json({ comment: result.rows[0] });
  } catch(e) {
    console.error('Create project comment error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// ==================== CHATS ====================

app.get('/api/chats', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM chats WHERE participant_ids LIKE $1 OR participant_ids LIKE $2 ORDER BY last_message_at DESC`,
      [`%"${req.userId}"%`, `%${req.userId}%`]
    );

    const chats = [];
    for (const chat of result.rows) {
      const participants = parseParticipantIds(chat.participant_ids);
      if (!participants.includes(req.userId)) continue;

      const otherId = participants.find(x => x !== req.userId);
      const isGroup = participants.length > 2;

      let team = null;
      if (isGroup) {
        const teamResult = await pool.query('SELECT id, name FROM teams WHERE chat_id = $1', [chat.id]);
        team = teamResult.rows[0] || null;
      }

      const otherUserResult = await pool.query('SELECT * FROM users WHERE id = $1', [otherId]);
      const otherUser = sanitizeUser(otherUserResult.rows[0]) || {
        id: chat.id,
        name: team?.name || 'Командный чат',
        email: '',
        avatar_url: null,
        is_online: false
      };

      const unreadResult = await pool.query(
        'SELECT unread_count FROM chat_unread WHERE chat_id = $1 AND user_id = $2',
        [chat.id, req.userId]
      );
      const unread = unreadResult.rows.length > 0 ? unreadResult.rows[0].unread_count : 0;

      let lastMessage = null;
      if (chat.last_sender_id) {
        const senderResult = await pool.query(
          'SELECT id, name, email, avatar_url, is_online FROM users WHERE id = $1',
          [chat.last_sender_id]
        );
        const sender = sanitizeUser(senderResult.rows[0]);
        lastMessage = {
          id: chat.id + '_last',
          chat_id: chat.id,
          sender,
          content: chat.last_message,
          type: chat.last_message_type,
          created_at: chat.last_message_at
        };
      }

      chats.push({
        id: chat.id,
        other_user: otherUser,
        title: isGroup ? (team?.name || 'Командный чат') : otherUser.name,
        is_group: isGroup,
        participant_ids: JSON.stringify(participants),
        last_message: lastMessage,
        unread_count: unread,
        is_online: isGroup ? false : (otherUser?.is_online || false),
        last_message_at: chat.last_message_at,
        created_at: chat.created_at
      });
    }

    res.json({ chats });
  } catch(e) {
    console.error('Get chats error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.post('/api/chats', authMiddleware, async (req, res) => {
  try {
    const { other_user_id } = req.body;
    if (!other_user_id) {
      return res.status(400).json({ error: 'other_user_id обязателен' });
    }

    const pids = [req.userId, other_user_id].sort();
    const pidsJson = JSON.stringify(pids);

    const existingResult = await pool.query(
      'SELECT * FROM chats WHERE participant_ids = $1',
      [pidsJson]
    );

    if (existingResult.rows.length > 0) {
      return res.json({ chat_id: existingResult.rows[0].id, created: false });
    }

    const chatId = uuidv4();
    await pool.query('INSERT INTO chats (id, participant_ids) VALUES ($1, $2)', [chatId, pidsJson]);
    await pool.query('INSERT INTO chat_unread (chat_id, user_id, unread_count) VALUES ($1, $2, 0)', [chatId, req.userId]);
    await pool.query('INSERT INTO chat_unread (chat_id, user_id, unread_count) VALUES ($1, $2, 0)', [chatId, other_user_id]);

    res.status(201).json({ chat_id: chatId, created: true });
  } catch(e) {
    console.error('Create chat error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.get('/api/chats/:id/messages', authMiddleware, async (req, res) => {
  try {
    const chatResult = await pool.query('SELECT * FROM chats WHERE id = $1', [req.params.id]);

    if (chatResult.rows.length === 0) {
      return res.status(404).json({ error: 'Чат не найден' });
    }

    const chat = chatResult.rows[0];
    const participants = parseParticipantIds(chat.participant_ids);
    if (!participants.includes(req.userId)) {
      return res.status(403).json({ error: 'Нет доступа' });
    }

    const messagesResult = await pool.query(`
      SELECT m.*, u.name as sender_name, u.email as sender_email, u.avatar_url as sender_avatar,
             u.is_online as sender_is_online
      FROM messages m JOIN users u ON m.sender_id = u.id
      WHERE m.chat_id = $1
      ORDER BY m.created_at DESC LIMIT 100
    `, [req.params.id]);

    res.json({ messages: messagesResult.rows });
  } catch(e) {
    console.error('Get messages error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.post('/api/chats/:id/messages', authMiddleware, async (req, res) => {
  try {
    const { content, type, attachments, project_id } = req.body;
    if (!content) {
      return res.status(400).json({ error: 'content обязателен' });
    }

    const chatResult = await pool.query('SELECT * FROM chats WHERE id = $1', [req.params.id]);
    if (chatResult.rows.length === 0) {
      return res.status(404).json({ error: 'Чат не найден' });
    }

    const chat = chatResult.rows[0];
    const participants = parseParticipantIds(chat.participant_ids);
    if (!participants.includes(req.userId)) {
      return res.status(403).json({ error: 'Нет доступа' });
    }

    const msgId = uuidv4();
    await pool.query(
      'INSERT INTO messages (id, chat_id, sender_id, content, type, attachments, project_id) VALUES ($1, $2, $3, $4, $5, $6, $7)',
      [msgId, req.params.id, req.userId, content, type || 'text', JSON.stringify(attachments || []), project_id || null]
    );

    await pool.query(
      'UPDATE chats SET last_message = $1, last_message_type = $2, last_sender_id = $3, last_message_at = $4 WHERE id = $5',
      [content, type || 'text', req.userId, Date.now(), req.params.id]
    );

    for (const participantId of participants.filter(x => x !== req.userId)) {
      await pool.query(
        'INSERT INTO chat_unread (chat_id, user_id, unread_count) VALUES ($1, $2, 1) ON CONFLICT (chat_id, user_id) DO UPDATE SET unread_count = chat_unread.unread_count + 1',
        [req.params.id, participantId]
      );
    }

    const senderResult = await pool.query(
      'SELECT id, name, email, avatar_url, is_online FROM users WHERE id = $1',
      [req.userId]
    );
    const sender = sanitizeUser(senderResult.rows[0]);

    res.status(201).json({
      message: {
        id: msgId,
        chat_id: req.params.id,
        sender,
        content,
        type: type || 'text',
        is_read: false,
        created_at: Date.now()
      }
    });
  } catch(e) {
    console.error('Send message error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.post('/api/chats/:id/read', authMiddleware, async (req, res) => {
  try {
    await pool.query(
      'UPDATE chat_unread SET unread_count = 0 WHERE chat_id = $1 AND user_id = $2',
      [req.params.id, req.userId]
    );

    await pool.query(
      'UPDATE messages SET is_read = 1, read_at = $1 WHERE chat_id = $2 AND sender_id != $3 AND is_read = 0',
      [Date.now(), req.params.id, req.userId]
    );

    res.json({ ok: true });
  } catch(e) {
    console.error('Mark read error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// ==================== FOLLOWS ====================

app.post('/api/follow/:userId', authMiddleware, async (req, res) => {
  try {
    const fid = req.userId;
    const tid = req.params.userId;

    if (fid === tid) {
      return res.status(400).json({ error: 'Нельзя на себя' });
    }

    const existsResult = await pool.query(
      'SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = $2',
      [fid, tid]
    );

    if (existsResult.rows.length > 0) {
      await pool.query('DELETE FROM follows WHERE follower_id = $1 AND following_id = $2', [fid, tid]);
      await pool.query('UPDATE users SET following_count = GREATEST(0, following_count - 1) WHERE id = $1', [fid]);
      await pool.query('UPDATE users SET followers_count = GREATEST(0, followers_count - 1) WHERE id = $1', [tid]);
      res.json({ is_following: false });
    } else {
      await pool.query('INSERT INTO follows (follower_id, following_id) VALUES ($1, $2)', [fid, tid]);
      await pool.query('UPDATE users SET following_count = following_count + 1 WHERE id = $1', [fid]);
      await pool.query('UPDATE users SET followers_count = followers_count + 1 WHERE id = $1', [tid]);
      res.json({ is_following: true });
    }
  } catch(e) {
    console.error('Follow error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.get('/api/follow/status/:userId', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = $2',
      [req.userId, req.params.userId]
    );
    res.json({ is_following: result.rows.length > 0 });
  } catch(e) {
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.get('/api/followers/:userId', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT u.* FROM follows f
      JOIN users u ON f.follower_id = u.id
      WHERE f.following_id = $1
      ORDER BY f.followed_at DESC
    `, [req.params.userId]);

    res.json({ followers: result.rows.map(sanitizeUser) });
  } catch(e) {
    console.error('Get followers error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

app.get('/api/following/:userId', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT u.* FROM follows f
      JOIN users u ON f.following_id = u.id
      WHERE f.follower_id = $1
      ORDER BY f.followed_at DESC
    `, [req.params.userId]);

    res.json({ following: result.rows.map(sanitizeUser) });
  } catch(e) {
    console.error('Get following error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// ==================== TEAMS ====================

// Создать команду
app.post('/api/teams', authMiddleware, async (req, res) => {
  try {
    const { name, project_id, member_ids } = req.body;
    
    if (!name) {
      return res.status(400).json({ error: 'Название команды обязательно' });
    }
    
    const teamId = uuidv4();
    const chatId = uuidv4();
    
    // Добавляем создателя в список участников
    let members = [req.userId];
    if (member_ids && Array.isArray(member_ids)) {
      members = [...new Set([...members, ...member_ids])]; // Убираем дубликаты
    }
    
    // Создаем групповой чат для команды
    const participantIds = JSON.stringify(members);
    await pool.query(
      'INSERT INTO chats (id, participant_ids, is_group, last_message, last_sender_id, last_message_at) VALUES ($1, $2, $3, $4, $5, $6)',
      [chatId, participantIds, 1, 'Команда создана', req.userId, Date.now()]
    );
    
    // Создаем команду
    await pool.query(
      'INSERT INTO teams (id, name, project_id, creator_id, chat_id, members) VALUES ($1, $2, $3, $4, $5, $6)',
      [teamId, name, project_id || null, req.userId, chatId, JSON.stringify(members)]
    );
    
    // Инициализируем unread для всех участников
    for (const memberId of members) {
      await pool.query(
        'INSERT INTO chat_unread (chat_id, user_id, unread_count) VALUES ($1, $2, $3) ON CONFLICT (chat_id, user_id) DO NOTHING',
        [chatId, memberId, 0]
      );
    }
    
    const result = await pool.query('SELECT * FROM teams WHERE id = $1', [teamId]);
    
    res.status(201).json({ team: result.rows[0] });
  } catch(e) {
    console.error('Create team error:', e);
    res.status(500).json({ error: 'Ошибка создания команды' });
  }
});

// Получить команды пользователя
app.get('/api/teams/my', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM teams WHERE members::jsonb @> $1 ORDER BY created_at DESC`,
      [JSON.stringify([req.userId])]
    );
    
    res.json({ teams: result.rows });
  } catch(e) {
    console.error('Get my teams error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// Пригласить пользователя в команду (создаёт уведомление)
app.post('/api/teams/:teamId/invite', authMiddleware, async (req, res) => {
  try {
    const { teamId } = req.params;
    const { user_id } = req.body;
    
    if (!user_id) {
      return res.status(400).json({ error: 'user_id обязателен' });
    }
    
    // Проверяем что команда существует
    const teamResult = await pool.query('SELECT * FROM teams WHERE id = $1', [teamId]);
    if (teamResult.rows.length === 0) {
      return res.status(404).json({ error: 'Команда не найдена' });
    }
    
    const team = teamResult.rows[0];
    const members = JSON.parse(team.members || '[]');
    
    // Проверяем что текущий пользователь в команде
    if (!members.includes(req.userId)) {
      return res.status(403).json({ error: 'Вы не состоите в этой команде' });
    }
    
    // Проверяем что пользователь еще не в команде
    if (members.includes(user_id)) {
      return res.status(400).json({ error: 'Пользователь уже в команде' });
    }
    
    // Создаём приглашение
    const invitationId = uuidv4();
    await pool.query(
      'INSERT INTO team_invitations (id, team_id, from_user_id, to_user_id, status) VALUES ($1, $2, $3, $4, $5)',
      [invitationId, teamId, req.userId, user_id, 'pending']
    );
    
    // Создаём уведомление для приглашённого пользователя
    const notificationId = uuidv4();
    await pool.query(
      `INSERT INTO notifications (id, user_id, type, data) VALUES ($1, $2, $3, $4)`,
      [notificationId, user_id, 'team_invite', JSON.stringify({
        invitation_id: invitationId,
        team_id: teamId,
        team_name: team.name,
        from_user_id: req.userId
      })]
    );
    
    // Получаем имя приглашающего для ответа
    const userResult = await pool.query('SELECT name FROM users WHERE id = $1', [req.userId]);
    const fromUserName = userResult.rows[0]?.name || 'Пользователь';
    
    res.json({
      ok: true,
      invitation_id: invitationId,
      message: `Приглашение отправлено пользователю`
    });
  } catch(e) {
    console.error('Invite to team error:', e);
    res.status(500).json({ error: 'Ошибка приглашения' });
  }
});

// Покинуть команду
app.post('/api/teams/:teamId/leave', authMiddleware, async (req, res) => {
  try {
    const { teamId } = req.params;
    
    const teamResult = await pool.query('SELECT * FROM teams WHERE id = $1', [teamId]);
    if (teamResult.rows.length === 0) {
      return res.status(404).json({ error: 'Команда не найдена' });
    }
    
    const team = teamResult.rows[0];
    let members = JSON.parse(team.members || '[]');
    
    // Удаляем пользователя из команды
    members = members.filter(id => id !== req.userId);
    
    if (members.length === 0) {
      // Если последний участник, удаляем команду
      await pool.query('DELETE FROM teams WHERE id = $1', [teamId]);
      return res.json({ deleted: true });
    }
    
    await pool.query(
      'UPDATE teams SET members = $1 WHERE id = $2',
      [JSON.stringify(members), teamId]
    );
    
    // Удаляем из чата
    if (team.chat_id) {
      const chatResult = await pool.query('SELECT * FROM chats WHERE id = $1', [team.chat_id]);
      if (chatResult.rows.length > 0) {
        const chat = chatResult.rows[0];
        const participantIds = parseParticipantIds(chat.participant_ids).filter(id => id !== req.userId);
        await pool.query(
          'UPDATE chats SET participant_ids = $1 WHERE id = $2',
          [JSON.stringify(participantIds), team.chat_id]
        );
      }
    }
    
    res.json({ ok: true });
  } catch(e) {
    console.error('Leave team error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// Получить команду по ID чата
app.get('/api/teams/by-chat/:chatId', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM teams WHERE chat_id = $1', [req.params.chatId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Команда не найдена' });
    }
    res.json({ team: result.rows[0] });
  } catch(e) {
    console.error('Get team by chat error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// Получить участников команды с деталями
app.get('/api/teams/:teamId/members', authMiddleware, async (req, res) => {
  try {
    const { teamId } = req.params;
    const teamResult = await pool.query('SELECT * FROM teams WHERE id = $1', [teamId]);
    if (teamResult.rows.length === 0) {
      return res.status(404).json({ error: 'Команда не найдена' });
    }
    const team = teamResult.rows[0];
    const members = JSON.parse(team.members || '[]');
    
    if (members.length === 0) {
      return res.json({ members: [] });
    }
    
    const userResult = await pool.query(
      `SELECT id, name, email, avatar_url, university, is_online FROM users WHERE id = ANY($1)`,
      [members]
    );
    
    res.json({ members: userResult.rows, creator_id: team.creator_id });
  } catch(e) {
    console.error('Get team members error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// Удалить участника из команды (только создатель)
app.post('/api/teams/:teamId/remove-member', authMiddleware, async (req, res) => {
  try {
    const { teamId } = req.params;
    const { user_id } = req.body;
    
    if (!user_id) {
      return res.status(400).json({ error: 'user_id обязателен' });
    }
    
    const teamResult = await pool.query('SELECT * FROM teams WHERE id = $1', [teamId]);
    if (teamResult.rows.length === 0) {
      return res.status(404).json({ error: 'Команда не найдена' });
    }
    
    const team = teamResult.rows[0];
    
    if (team.creator_id !== req.userId) {
      return res.status(403).json({ error: 'Только создатель команды может удалять участников' });
    }
    
    if (user_id === req.userId) {
      return res.status(400).json({ error: 'Используйте выход из команды' });
    }
    
    let members = JSON.parse(team.members || '[]');
    if (!members.includes(user_id)) {
      return res.status(400).json({ error: 'Пользователь не в команде' });
    }
    
    members = members.filter(id => id !== user_id);
    await pool.query('UPDATE teams SET members = $1 WHERE id = $2', [JSON.stringify(members), teamId]);
    
    if (team.chat_id) {
      const chatResult = await pool.query('SELECT * FROM chats WHERE id = $1', [team.chat_id]);
      if (chatResult.rows.length > 0) {
        const participantIds = parseParticipantIds(chatResult.rows[0].participant_ids)
          .filter(id => id !== user_id);
        await pool.query('UPDATE chats SET participant_ids = $1 WHERE id = $2', [JSON.stringify(participantIds), team.chat_id]);
        await pool.query('DELETE FROM chat_unread WHERE chat_id = $1 AND user_id = $2', [team.chat_id, user_id]);
      }
    }
    
    res.json({ ok: true });
  } catch(e) {
    console.error('Remove member error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// ==================== NOTIFICATIONS ====================

// Получить уведомления пользователя
app.get('/api/notifications', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT n.*, u.name as from_user_name, u.avatar_url as from_user_avatar,
              t.name as team_name
       FROM notifications n
       LEFT JOIN users u ON u.id = COALESCE(n.data, '{}')::jsonb->>'from_user_id'
       LEFT JOIN teams t ON t.id = COALESCE(n.data, '{}')::jsonb->>'team_id'
       WHERE n.user_id = $1
       ORDER BY n.created_at DESC LIMIT 50`,
      [req.userId]
    );
    
    res.json({ notifications: result.rows });
  } catch(e) {
    console.error('Get notifications error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// Отметить уведомление как прочитанное
app.post('/api/notifications/:id/read', authMiddleware, async (req, res) => {
  try {
    await pool.query(
      'UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2',
      [req.params.id, req.userId]
    );
    res.json({ ok: true });
  } catch(e) {
    console.error('Mark notification read error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// Получить количество непрочитанных уведомлений
app.get('/api/notifications/unread-count', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = $1 AND is_read = false',
      [req.userId]
    );
    res.json({ count: parseInt(result.rows[0]?.count || '0') });
  } catch(e) {
    console.error('Unread count error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// ==================== TEAM INVITATIONS (with notifications) ====================

// Принять приглашение
app.post('/api/team-invitations/:id/accept', authMiddleware, async (req, res) => {
  try {
    const invResult = await pool.query(
      'SELECT * FROM team_invitations WHERE id = $1 AND to_user_id = $2 AND status = $3',
      [req.params.id, req.userId, 'pending']
    );
    
    if (invResult.rows.length === 0) {
      return res.status(404).json({ error: 'Приглашение не найдено' });
    }
    
    const inv = invResult.rows[0];
    
    // Добавляем пользователя в команду
    const teamResult = await pool.query('SELECT * FROM teams WHERE id = $1', [inv.team_id]);
    if (teamResult.rows.length === 0) {
      return res.status(404).json({ error: 'Команда не найдена' });
    }
    
    const team = teamResult.rows[0];
    let members = JSON.parse(team.members || '[]');
    if (!members.includes(req.userId)) {
      members.push(req.userId);
      await pool.query('UPDATE teams SET members = $1 WHERE id = $2', [JSON.stringify(members), team.id]);
    }
    
    // Добавляем в чат
    if (team.chat_id) {
      const chatResult = await pool.query('SELECT * FROM chats WHERE id = $1', [team.chat_id]);
      if (chatResult.rows.length > 0) {
        const chat = chatResult.rows[0];
        let participantIds = parseParticipantIds(chat.participant_ids);
        if (!participantIds.includes(req.userId)) {
          participantIds.push(req.userId);
          await pool.query('UPDATE chats SET participant_ids = $1 WHERE id = $2', [JSON.stringify(participantIds), team.chat_id]);
        }
        await pool.query(
          'INSERT INTO chat_unread (chat_id, user_id, unread_count) VALUES ($1, $2, $3) ON CONFLICT (chat_id, user_id) DO NOTHING',
          [team.chat_id, req.userId, 0]
        );
      }
    }
    
    // Обновляем статус приглашения
    await pool.query('UPDATE team_invitations SET status = $1 WHERE id = $2', ['accepted', req.params.id]);
    
    // Удаляем уведомление
    await pool.query(
      "DELETE FROM notifications WHERE user_id = $1 AND type = 'team_invite' AND data::jsonb->>'invitation_id' = $2",
      [req.userId, req.params.id]
    );
    
    res.json({ ok: true, team_id: inv.team_id });
  } catch(e) {
    console.error('Accept invitation error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// Отклонить приглашение
app.post('/api/team-invitations/:id/reject', authMiddleware, async (req, res) => {
  try {
    const invResult = await pool.query(
      'SELECT * FROM team_invitations WHERE id = $1 AND to_user_id = $2 AND status = $3',
      [req.params.id, req.userId, 'pending']
    );
    
    if (invResult.rows.length === 0) {
      return res.status(404).json({ error: 'Приглашение не найдено' });
    }
    
    await pool.query('UPDATE team_invitations SET status = $1 WHERE id = $2', ['rejected', req.params.id]);
    
    // Удаляем уведомление
    await pool.query(
      "DELETE FROM notifications WHERE user_id = $1 AND type = 'team_invite' AND data::jsonb->>'invitation_id' = $2",
      [req.userId, req.params.id]
    );
    
    res.json({ ok: true });
  } catch(e) {
    console.error('Reject invitation error:', e);
    res.status(500).json({ error: 'Ошибка' });
  }
});

// Удалить чат (для пользователя)
app.post('/api/chats/:chatId/delete', authMiddleware, async (req, res) => {
  try {
    const { chatId } = req.params;
    
    // Проверяем что пользователь участник чата
    const chatResult = await pool.query('SELECT * FROM chats WHERE id = $1', [chatId]);
    if (chatResult.rows.length === 0) {
      return res.status(404).json({ error: 'Чат не найден' });
    }
    
    const chat = chatResult.rows[0];
    const participantIds = parseParticipantIds(chat.participant_ids);
    
    if (!participantIds.includes(req.userId)) {
      return res.status(403).json({ error: 'Вы не участник чата' });
    }
    
    // Для группового чата — удаляем пользователя из участников
    // Если после этого участников не осталось, удаляем чат полностью
    if (chat.is_group) {
      const updatedParticipants = participantIds.filter(id => id !== req.userId);
      if (updatedParticipants.length === 0) {
        // Удаляем все сообщения и сам чат
        await pool.query('DELETE FROM messages WHERE chat_id = $1', [chatId]);
        await pool.query('DELETE FROM chat_unread WHERE chat_id = $1', [chatId]);
        await pool.query('DELETE FROM chats WHERE id = $1', [chatId]);
      } else {
        await pool.query('UPDATE chats SET participant_ids = $1 WHERE id = $2',
          [JSON.stringify(updatedParticipants), chatId]);
        await pool.query('DELETE FROM chat_unread WHERE chat_id = $1 AND user_id = $2',
          [chatId, req.userId]);
      }
    } else {
      // Для личного чата — удаляем полностью (оба участника видят удаление)
      await pool.query('DELETE FROM messages WHERE chat_id = $1', [chatId]);
      await pool.query('DELETE FROM chat_unread WHERE chat_id = $1', [chatId]);
      await pool.query('DELETE FROM chats WHERE id = $1', [chatId]);
    }
    
    res.json({ ok: true });
  } catch(e) {
    console.error('Delete chat error:', e);
    res.status(500).json({ error: 'Ошибка удаления чата' });
  }
});

// ==================== START ====================

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Внутренняя ошибка сервера' });
});

async function start() {
  try {
    await initDatabase();
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Backend: http://localhost:${PORT}`);
      console.log(`📡 Database: PostgreSQL`);
      console.log(`📡 Listening on all interfaces`);
    });
  } catch (e) {
    console.error('Failed to start server:', e);
    process.exit(1);
  }
}
start();
