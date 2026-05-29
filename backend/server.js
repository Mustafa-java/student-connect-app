const express = require('express');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { getDb, saveDb } = require('./database');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'student-connect-secret-key';

// Создаём папку uploads если нет
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
    // Принимаем только ZIP и архивы
    const allowed = ['.zip', '.rar', '.7z', '.tar', '.gz'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowed.includes(ext) || file.mimetype.includes('zip') || file.mimetype.includes('archive')) {
      cb(null, true);
    } else {
      cb(new Error('Только ZIP/архивы файлы'));
    }
  }
});

// Helpers
function rowToObject(columns, values) {
  const o = {}; columns.forEach((c, i) => o[c] = values[i]); return o;
}
function querySingle(db, sql) {
  const r = db.exec(sql);
  return (r.length && r[0].values.length) ? rowToObject(r[0].columns, r[0].values[0]) : null;
}
function queryAll(db, sql) {
  const r = db.exec(sql);
  return (r.length && r[0].values.length) ? r[0].values.map(v => rowToObject(r[0].columns, v)) : [];
}

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true }));

// Логирование запросов для отладки
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Auto-save after each request
app.use((req, res, next) => {
  res.on('finish', () => { try { saveDb(); } catch(e) {} });
  next();
});

function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Не авторизован' });
  try { req.userId = jwt.verify(token, JWT_SECRET).userId; next(); }
  catch (e) { res.status(401).json({ error: 'Неверный токен' }); }
}

function sanitizeUser(u) { if (!u) return null; const { password_hash, ...r } = u; return r; }
function esc(s) { return (s || '').replace(/'/g, "''"); }

// ==================== AUTH ====================

app.post('/api/auth/register', async (req, res) => {
  try {
    const db = await getDb();
    const { name, email, password, university, faculty, course, bio, skills, avatar_url } = req.body;
    if (!name || !email || !password) return res.status(400).json({ error: 'name, email, password обязательны' });

    const existing = db.exec(`SELECT id FROM users WHERE email = '${esc(email)}'`);
    if (existing.length && existing[0].values.length) return res.status(409).json({ error: 'Email уже занят' });

    const hash = await bcrypt.hash(password, 10);
    const uid = uuidv4();
    db.run(`INSERT INTO users (id, name, email, password_hash, avatar_url, bio, university, faculty, course, skills)
      VALUES (?,?,?,?,?,?,?,?,?,?)`,
      [uid, name, email, hash, avatar_url||null, bio||null, university||null, faculty||null, course||null, JSON.stringify(skills||[])]);

    const token = jwt.sign({ userId: uid }, JWT_SECRET, { expiresIn: '30d' });
    const user = querySingle(db, `SELECT * FROM users WHERE id = '${uid}'`);
    res.status(201).json({ token, user: sanitizeUser(user) });
  } catch(e) { console.error(e); res.status(500).json({ error: 'Ошибка' }); }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    console.log('Login attempt:', req.body.email);
    const db = await getDb();
    const { email, password } = req.body;
    
    if (!email || !password) {
      console.log('Missing email or password');
      return res.status(400).json({ error: 'Email и пароль обязательны' });
    }
    
    const user = querySingle(db, `SELECT * FROM users WHERE email = '${esc(email)}'`);
    if (!user) {
      console.log('User not found:', email);
      return res.status(401).json({ error: 'Неверный email или пароль' });
    }
    
    console.log('User found:', user.name);
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      console.log('Invalid password for user:', email);
      return res.status(401).json({ error: 'Неверный email или пароль' });
    }
    
    db.run(`UPDATE users SET is_online = 1, last_seen = ? WHERE id = ?`, [Date.now(), user.id]);
    const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '30d' });
    console.log('Login successful for:', user.name);
    res.json({ token, user: sanitizeUser(user) });
  } catch(e) { 
    console.error('Login error:', e); 
    res.status(500).json({ error: 'Ошибка сервера: ' + e.message }); 
  }
});

app.get('/api/auth/me', authMiddleware, async (req, res) => {
  const db = await getDb();
  const user = querySingle(db, `SELECT * FROM users WHERE id = '${req.userId}'`);
  if (!user) return res.status(404).json({ error: 'Не найден' });
  res.json({ user: sanitizeUser(user) });
});

// ==================== USERS ====================

app.get('/api/users', authMiddleware, async (req, res) => {
  const db = await getDb();
  const users = queryAll(db, 'SELECT * FROM users ORDER BY created_at DESC LIMIT 100').map(sanitizeUser);
  res.json({ users });
});

app.get('/api/users/search', authMiddleware, async (req, res) => {
  const { q } = req.query;
  if (!q) return res.json({ users: [] });
  const db = await getDb();
  const users = queryAll(db, `SELECT * FROM users WHERE name LIKE '%${esc(q)}%' AND id != '${req.userId}' ORDER BY name LIMIT 20`).map(sanitizeUser);
  res.json({ users });
});

app.get('/api/users/:id', authMiddleware, async (req, res) => {
  const db = await getDb();
  const user = querySingle(db, `SELECT * FROM users WHERE id = '${req.params.id}'`);
  if (!user) return res.status(404).json({ error: 'Не найден' });
  res.json({ user: sanitizeUser(user) });
});

app.put('/api/users/:id', authMiddleware, async (req, res) => {
  if (req.params.id !== req.userId) return res.status(403).json({ error: 'Нет доступа' });
  const db = await getDb();
  const { name, bio, university, faculty, course, skills, avatar_url } = req.body;
  db.run(`UPDATE users SET name=COALESCE(?,name), bio=COALESCE(?,bio), university=COALESCE(?,university),
    faculty=COALESCE(?,faculty), course=COALESCE(?,course), skills=COALESCE(?,skills), avatar_url=COALESCE(?,avatar_url)
    WHERE id=?`, [name||null, bio||null, university||null, faculty||null, course||null, skills?JSON.stringify(skills):null, avatar_url||null, req.userId]);
  const user = querySingle(db, `SELECT * FROM users WHERE id = '${req.userId}'`);
  res.json({ user: sanitizeUser(user) });
});

// ==================== POSTS ====================

function enrichPost(db, post, userId) {
  return { ...post, author_skills: JSON.parse(post.author_skills||'[]'),
    is_liked: !!db.exec(`SELECT 1 FROM post_likes WHERE post_id='${post.id}' AND user_id='${userId}'`).length };
}

app.get('/api/posts', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const posts = queryAll(db, `
      SELECT p.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.university as author_university, u.is_online as author_is_online,
             u.skills as author_skills, u.projects_count as author_projects_count,
             u.followers_count as author_followers_count, u.following_count as author_following_count
      FROM posts p JOIN users u ON p.author_id = u.id ORDER BY p.created_at DESC LIMIT 50`);
    res.json({ posts: posts.map(p => enrichPost(db, p, req.userId)) });
  } catch(e) { res.status(500).json({ error: 'Ошибка' }); }
});

app.post('/api/posts', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const { content, project_id, images, tags } = req.body;
    const id = uuidv4();
    db.run(`INSERT INTO posts (id, author_id, content, project_id, images, tags) VALUES (?,?,?,?,?,?)`,
      [id, req.userId, content||null, project_id||null, JSON.stringify(images||[]), JSON.stringify(tags||[])]);
    const post = querySingle(db, `
      SELECT p.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.university as author_university, u.is_online as author_is_online,
             u.skills as author_skills, u.projects_count as author_projects_count,
             u.followers_count as author_followers_count, u.following_count as author_following_count
      FROM posts p JOIN users u ON p.author_id = u.id WHERE p.id = '${id}'`);
    res.status(201).json({ post: enrichPost(db, post, req.userId) });
  } catch(e) { res.status(500).json({ error: 'Ошибка' }); }
});

app.post('/api/posts/:id/like', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const { id } = req.params;
    const exists = db.exec(`SELECT 1 FROM post_likes WHERE post_id='${id}' AND user_id='${req.userId}'`);
    if (exists.length && exists[0].values.length) {
      db.run(`DELETE FROM post_likes WHERE post_id=? AND user_id=?`, [id, req.userId]);
      db.run(`UPDATE posts SET likes_count=MAX(0,likes_count-1) WHERE id=?`, [id]);
    } else {
      db.run(`INSERT INTO post_likes (post_id,user_id) VALUES (?,?)`, [id, req.userId]);
      db.run(`UPDATE posts SET likes_count=likes_count+1 WHERE id=?`, [id]);
    }
    const r = querySingle(db, `SELECT likes_count FROM posts WHERE id='${id}'`);
    const isLiked = !!(db.exec(`SELECT 1 FROM post_likes WHERE post_id='${id}' AND user_id='${req.userId}'`).length);
    res.json({ is_liked: isLiked, likes_count: r?.likes_count || 0 });
  } catch(e) { res.status(500).json({ error: 'Ошибка' }); }
});

// Удаление поста
app.delete('/api/posts/:id', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const { id } = req.params;
    const post = querySingle(db, `SELECT * FROM posts WHERE id='${id}'`);
    
    if (!post) {
      return res.status(404).json({ error: 'Пост не найден' });
    }
    
    if (post.author_id !== req.userId) {
      return res.status(403).json({ error: 'Нет доступа' });
    }
    
    // Удаляем лайки
    db.run(`DELETE FROM post_likes WHERE post_id=?`, [id]);
    // Удаляем комментарии
    db.run(`DELETE FROM comments WHERE post_id=?`, [id]);
    // Удаляем пост
    db.run(`DELETE FROM posts WHERE id=?`, [id]);
    
    console.log('Post deleted:', id);
    res.json({ ok: true });
  } catch(e) { 
    console.error('Delete post error:', e); 
    res.status(500).json({ error: 'Ошибка' }); 
  }
});

// ==================== COMMENTS ====================

app.get('/api/posts/:id/comments', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const comments = queryAll(db, `
      SELECT c.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.is_online as author_is_online
      FROM comments c JOIN users u ON c.author_id = u.id WHERE c.post_id='${req.params.id}' ORDER BY c.created_at ASC`);
    res.json({ comments });
  } catch(e) { res.status(500).json({ error: 'Ошибка' }); }
});

app.post('/api/posts/:id/comments', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const { content, reply_to_id } = req.body;
    if (!content) return res.status(400).json({ error: 'content обязателен' });
    const id = uuidv4();
    db.run(`INSERT INTO comments (id, post_id, author_id, content, reply_to_id) VALUES (?,?,?,?,?)`,
      [id, req.params.id, req.userId, content, reply_to_id||null]);
    db.run(`UPDATE posts SET comments_count=comments_count+1 WHERE id=?`, [req.params.id]);
    const comment = querySingle(db, `
      SELECT c.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.is_online as author_is_online
      FROM comments c JOIN users u ON c.author_id = u.id WHERE c.id='${id}'`);
    res.status(201).json({ comment });
  } catch(e) { res.status(500).json({ error: 'Ошибка' }); }
});

// ==================== PROJECTS ====================

function enrichProject(db, p, userId) {
  return { ...p, author_skills: JSON.parse(p.author_skills||'[]'), team_members: JSON.parse(p.team_members||'[]'),
    is_liked: !!db.exec(`SELECT 1 FROM project_likes WHERE project_id='${p.id}' AND user_id='${userId}'`).length };
}

app.get('/api/projects', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const projects = queryAll(db, `
      SELECT p.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.university as author_university, u.is_online as author_is_online,
             u.skills as author_skills, u.projects_count as author_projects_count,
             u.followers_count as author_followers_count, u.following_count as author_following_count
      FROM projects p JOIN users u ON p.author_id = u.id ORDER BY p.created_at DESC LIMIT 50`);
    res.json({ projects: projects.map(p => enrichProject(db, p, req.userId)) });
  } catch(e) { res.status(500).json({ error: 'Ошибка' }); }
});

app.post('/api/projects', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const { title, description, images, skills, status, university_tags } = req.body;
    if (!title || !description) return res.status(400).json({ error: 'title и description обязательны' });
    const id = uuidv4();
    db.run(`INSERT INTO projects (id,author_id,title,description,images,skills,status,university_tags)
      VALUES (?,?,?,?,?,?,?,?)`, [id, req.userId, title, description, JSON.stringify(images||[]),
      JSON.stringify(skills||[]), status||'idea', JSON.stringify(university_tags||[])]);
    db.run(`UPDATE users SET projects_count=projects_count+1 WHERE id=?`, [req.userId]);
    const project = querySingle(db, `
      SELECT p.*, u.name as author_name, u.email as author_email, u.avatar_url as author_avatar,
             u.university as author_university, u.is_online as author_is_online,
             u.skills as author_skills, u.projects_count as author_projects_count,
             u.followers_count as author_followers_count, u.following_count as author_following_count
      FROM projects p JOIN users u ON p.author_id = u.id WHERE p.id='${id}'`);
    res.status(201).json({ project: enrichProject(db, project, req.userId) });
  } catch(e) { res.status(500).json({ error: 'Ошибка' }); }
});

app.post('/api/projects/:id/views', authMiddleware, async (req, res) => {
  const db = await getDb();
  db.run(`UPDATE projects SET views_count=views_count+1 WHERE id=?`, [req.params.id]);
  res.json({ ok: true });
});

app.post('/api/projects/:id/like', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const { id } = req.params;
    const exists = db.exec(`SELECT 1 FROM project_likes WHERE project_id='${id}' AND user_id='${req.userId}'`);
    if (exists.length && exists[0].values.length) {
      db.run(`DELETE FROM project_likes WHERE project_id=? AND user_id=?`, [id, req.userId]);
      db.run(`UPDATE projects SET likes_count=MAX(0,likes_count-1) WHERE id=?`, [id]);
    } else {
      db.run(`INSERT INTO project_likes (project_id,user_id) VALUES (?,?)`, [id, req.userId]);
      db.run(`UPDATE projects SET likes_count=likes_count+1 WHERE id=?`, [id]);
    }
    const r = querySingle(db, `SELECT likes_count FROM projects WHERE id='${id}'`);
    const isLiked = !!(db.exec(`SELECT 1 FROM project_likes WHERE project_id='${id}' AND user_id='${req.userId}'`).length);
    res.json({ is_liked: isLiked, likes_count: r?.likes_count || 0 });
  } catch(e) { res.status(500).json({ error: 'Ошибка' }); }
});

// Удаление проекта
app.delete('/api/projects/:id', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const { id } = req.params;
    const project = querySingle(db, `SELECT * FROM projects WHERE id='${id}'`);
    
    if (!project) {
      return res.status(404).json({ error: 'Проект не найден' });
    }
    
    if (project.author_id !== req.userId) {
      return res.status(403).json({ error: 'Нет доступа' });
    }
    
    // Удаляем лайки
    db.run(`DELETE FROM project_likes WHERE project_id=?`, [id]);
    // Удаляем файл с диска если есть
    if (project.zip_file_disk_name) {
      const filePath = path.join(UPLOADS_DIR, project.zip_file_disk_name);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        console.log('Deleted file:', filePath);
      }
    }
    // Удаляем проект
    db.run(`DELETE FROM projects WHERE id=?`, [id]);
    
    console.log('Project deleted:', id);
    res.json({ ok: true });
  } catch(e) { 
    console.error('Delete project error:', e); 
    res.status(500).json({ error: 'Ошибка' }); 
  }
});

// ==================== PROJECT ZIP FILES ====================

// Загрузка ZIP файла проекта
app.post('/api/projects/:id/upload-zip', authMiddleware, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'Файл не загружен' });

    const db = await getDb();
    const { id } = req.params;
    const project = querySingle(db, `SELECT * FROM projects WHERE id='${id}'`);
    if (!project) return res.status(404).json({ error: 'Проект не найден' });
    if (project.author_id !== req.userId) return res.status(403).json({ error: 'Нет доступа' });

    const zipUrl = `/api/projects/${id}/zip-file`;
    const zipName = req.file.originalname; // Оригинальное имя для отображения
    const zipSize = req.file.size;
    const zipFileNameOnDisk = req.file.filename; // Уникальное имя файла на диске

    console.log('Uploaded file:', {
      originalName: zipName,
      diskName: zipFileNameOnDisk,
      size: zipSize
    });

    db.run(`UPDATE projects SET zip_file_url=?, zip_file_name=?, zip_file_size=?, zip_file_disk_name=? WHERE id=?`,
      [zipUrl, zipName, zipSize, zipFileNameOnDisk, id]);

    res.json({
      zip_file_url: zipUrl,
      zip_file_name: zipName,
      zip_file_size: zipSize
    });
  } catch(e) {
    console.error(e);
    res.status(500).json({ error: 'Ошибка загрузки файла' });
  }
});

// Скачивание ZIP файла проекта
app.get('/api/projects/:id/zip-file', authMiddleware, async (req, res) => {
  try {
    console.log('Download request for project:', req.params.id);
    const db = await getDb();
    const { id } = req.params;
    const project = querySingle(db, `SELECT * FROM projects WHERE id='${id}'`);
    
    if (!project) {
      console.log('Project not found:', id);
      return res.status(404).json({ error: 'Проект не найден' });
    }

    if (!project.zip_file_url || !project.zip_file_name) {
      console.log('No zip file attached for project:', id);
      return res.status(404).json({ error: 'ZIP файл не прикреплён' });
    }

    // Используем уникальное имя файла на диске
    const zipFileName = project.zip_file_disk_name || project.zip_file_name;
    const filePath = path.join(UPLOADS_DIR, zipFileName);
    
    console.log('Looking for file:', zipFileName);
    
    if (!fs.existsSync(filePath)) {
      console.log('File not found on disk:', filePath);
      return res.status(404).json({ error: 'Файл не найден на сервере' });
    }

    const fileStats = fs.statSync(filePath);
    console.log('Found file:', zipFileName, 'Size:', fileStats.size, 'bytes');
    console.log('Original name:', project.zip_file_name);

    // Отправляем файл с правильными заголовками
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

// ==================== CHATS ====================

app.get('/api/chats', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const pattern = `%"${req.userId}"%`;
    const chatRows = db.exec(`SELECT * FROM chats WHERE participant_ids LIKE '${esc(pattern)}' ORDER BY last_message_at DESC`);
    if (!chatRows.length || !chatRows[0].values.length) return res.json({ chats: [] });

    const chats = [];
    for (const v of chatRows[0].values) {
      const chat = rowToObject(chatRows[0].columns, v);
      const participants = JSON.parse(chat.participant_ids);
      const otherId = participants.find(x => x !== req.userId);
      const otherUser = sanitizeUser(querySingle(db, `SELECT * FROM users WHERE id='${otherId}'`));
      const unreadRow = db.exec(`SELECT unread_count FROM chat_unread WHERE chat_id='${chat.id}' AND user_id='${req.userId}'`);
      const unread = unreadRow.length && unreadRow[0].values.length ? unreadRow[0].values[0][0] : 0;

      let lastMessage = null;
      if (chat.last_sender_id) {
        const sender = sanitizeUser(querySingle(db, `SELECT id,name,email,avatar_url,is_online FROM users WHERE id='${chat.last_sender_id}'`));
        lastMessage = { id: chat.id+'_last', chat_id: chat.id, sender, content: chat.last_message, type: chat.last_message_type, created_at: chat.last_message_at };
      }

      chats.push({ id: chat.id, other_user: otherUser, last_message: lastMessage,
        unread_count: unread, is_online: otherUser?.is_online||false, last_message_at: chat.last_message_at, created_at: chat.created_at });
    }
    res.json({ chats });
  } catch(e) { console.error(e); res.status(500).json({ error: 'Ошибка' }); }
});

app.post('/api/chats', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const { other_user_id } = req.body;
    if (!other_user_id) return res.status(400).json({ error: 'other_user_id обязателен' });
    const pids = [req.userId, other_user_id].sort();
    const pidsJson = JSON.stringify(pids);
    const existing = querySingle(db, `SELECT * FROM chats WHERE participant_ids = '${esc(pidsJson)}'`);
    if (existing) return res.json({ chat_id: existing.id, created: false });

    const chatId = uuidv4();
    db.run(`INSERT INTO chats (id, participant_ids) VALUES (?,?)`, [chatId, pidsJson]);
    db.run(`INSERT INTO chat_unread (chat_id, user_id, unread_count) VALUES (?,?,0)`, [chatId, req.userId]);
    db.run(`INSERT INTO chat_unread (chat_id, user_id, unread_count) VALUES (?,?,0)`, [chatId, other_user_id]);
    res.status(201).json({ chat_id: chatId, created: true });
  } catch(e) { res.status(500).json({ error: 'Ошибка' }); }
});

app.get('/api/chats/:id/messages', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const chat = querySingle(db, `SELECT * FROM chats WHERE id='${req.params.id}'`);
    if (!chat) return res.status(404).json({ error: 'Чат не найден' });
    if (!JSON.parse(chat.participant_ids).includes(req.userId)) return res.status(403).json({ error: 'Нет доступа' });

    const messages = queryAll(db, `
      SELECT m.*, u.name as sender_name, u.email as sender_email, u.avatar_url as sender_avatar,
             u.is_online as sender_is_online
      FROM messages m JOIN users u ON m.sender_id = u.id WHERE m.chat_id='${req.params.id}'
      ORDER BY m.created_at DESC LIMIT 100`);
    res.json({ messages });
  } catch(e) { res.status(500).json({ error: 'Ошибка' }); }
});

app.post('/api/chats/:id/messages', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const { content, type, attachments, project_id } = req.body;
    if (!content) return res.status(400).json({ error: 'content обязателен' });
    const chat = querySingle(db, `SELECT * FROM chats WHERE id='${req.params.id}'`);
    if (!chat) return res.status(404).json({ error: 'Чат не найден' });
    const participants = JSON.parse(chat.participant_ids);
    if (!participants.includes(req.userId)) return res.status(403).json({ error: 'Нет доступа' });

    const msgId = uuidv4();
    const receiverId = participants.find(x => x !== req.userId);
    db.run(`INSERT INTO messages (id,chat_id,sender_id,content,type,attachments,project_id) VALUES (?,?,?,?,?,?,?)`,
      [msgId, req.params.id, req.userId, content, type||'text', JSON.stringify(attachments||[]), project_id||null]);
    db.run(`UPDATE chats SET last_message=?, last_message_type=?, last_sender_id=?, last_message_at=? WHERE id=?`,
      [content, type||'text', req.userId, Date.now(), req.params.id]);
    db.run(`UPDATE chat_unread SET unread_count=unread_count+1 WHERE chat_id=? AND user_id=?`, [req.params.id, receiverId]);

    const sender = sanitizeUser(querySingle(db, `SELECT id,name,email,avatar_url,is_online FROM users WHERE id='${req.userId}'`));
    res.status(201).json({ message: { id: msgId, chat_id: req.params.id, sender, content, type: type||'text', is_read: false, created_at: Date.now() } });
  } catch(e) { res.status(500).json({ error: 'Ошибка' }); }
});

app.post('/api/chats/:id/read', authMiddleware, async (req, res) => {
  const db = await getDb();
  db.run(`UPDATE chat_unread SET unread_count=0 WHERE chat_id=? AND user_id=?`, [req.params.id, req.userId]);
  db.run(`UPDATE messages SET is_read=1, read_at=? WHERE chat_id=? AND sender_id!=? AND is_read=0`, [Date.now(), req.params.id, req.userId]);
  res.json({ ok: true });
});

// ==================== FOLLOWS ====================

app.post('/api/follow/:userId', authMiddleware, async (req, res) => {
  try {
    const db = await getDb();
    const { userId: fid } = req;
    const tid = req.params.userId;
    if (fid === tid) return res.status(400).json({ error: 'Нельзя на себя' });

    const exists = db.exec(`SELECT 1 FROM follows WHERE follower_id='${fid}' AND following_id='${tid}'`);
    if (exists.length && exists[0].values.length) {
      db.run(`DELETE FROM follows WHERE follower_id=? AND following_id=?`, [fid, tid]);
      db.run(`UPDATE users SET following_count=MAX(0,following_count-1) WHERE id=?`, [fid]);
      db.run(`UPDATE users SET followers_count=MAX(0,followers_count-1) WHERE id=?`, [tid]);
      res.json({ is_following: false });
    } else {
      db.run(`INSERT INTO follows (follower_id, following_id) VALUES (?,?)`, [fid, tid]);
      db.run(`UPDATE users SET following_count=following_count+1 WHERE id=?`, [fid]);
      db.run(`UPDATE users SET followers_count=followers_count+1 WHERE id=?`, [tid]);
      res.json({ is_following: true });
    }
  } catch(e) { res.status(500).json({ error: 'Ошибка' }); }
});

app.get('/api/follow/status/:userId', authMiddleware, async (req, res) => {
  const db = await getDb();
  const r = db.exec(`SELECT 1 FROM follows WHERE follower_id='${req.userId}' AND following_id='${req.params.userId}'`);
  res.json({ is_following: !!(r.length && r[0].values.length) });
});

app.get('/api/followers/:userId', authMiddleware, async (req, res) => {
  const db = await getDb();
  const followers = queryAll(db, `SELECT u.* FROM follows f JOIN users u ON f.follower_id=u.id WHERE f.following_id='${req.params.userId}' ORDER BY f.followed_at DESC`).map(sanitizeUser);
  res.json({ followers });
});

app.get('/api/following/:userId', authMiddleware, async (req, res) => {
  const db = await getDb();
  const following = queryAll(db, `SELECT u.* FROM follows f JOIN users u ON f.following_id=u.id WHERE f.follower_id='${req.params.userId}' ORDER BY f.followed_at DESC`).map(sanitizeUser);
  res.json({ following });
});

// ==================== START ====================

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Внутренняя ошибка сервера' });
});

async function start() {
  try {
    await getDb();
    console.log('Database initialized');
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Backend: http://localhost:${PORT}`);
      console.log(`📡 Listening on all interfaces`);
    });
  } catch (e) {
    console.error('Failed to start server:', e);
    process.exit(1);
  }
}
start();
