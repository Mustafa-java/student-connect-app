const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, 'student_connect.db');

let db = null;
let SQL;

async function getDb() {
  if (!db) {
    if (!SQL) {
      SQL = await initSqlJs();
    }

    // Загружаем существующую БД или создаём новую
    try {
      if (fs.existsSync(DB_PATH)) {
        const buffer = fs.readFileSync(DB_PATH);
        db = new SQL.Database(buffer);
      } else {
        db = new SQL.Database();
        initDatabase();
        saveDb();
      }
    } catch (e) {
      db = new SQL.Database();
      initDatabase();
      saveDb();
    }
  }
  return db;
}

function saveDb() {
  if (db) {
    const data = db.export();
    const buffer = Buffer.from(data);
    fs.writeFileSync(DB_PATH, buffer);
  }
}

function initDatabase() {
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      avatar_url TEXT,
      bio TEXT,
      university TEXT,
      faculty TEXT,
      course TEXT,
      skills TEXT DEFAULT '[]',
      projects_count INTEGER DEFAULT 0,
      followers_count INTEGER DEFAULT 0,
      following_count INTEGER DEFAULT 0,
      is_online INTEGER DEFAULT 0,
      last_seen INTEGER,
      created_at INTEGER DEFAULT (CAST((julianday('now') - 2440587.5)*86400000 AS INTEGER))
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS posts (
      id TEXT PRIMARY KEY,
      author_id TEXT NOT NULL,
      content TEXT,
      project_id TEXT,
      images TEXT DEFAULT '[]',
      tags TEXT DEFAULT '[]',
      likes_count INTEGER DEFAULT 0,
      comments_count INTEGER DEFAULT 0,
      shares_count INTEGER DEFAULT 0,
      created_at INTEGER DEFAULT (CAST((julianday('now') - 2440587.5)*86400000 AS INTEGER))
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS post_likes (
      post_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      liked_at INTEGER DEFAULT (CAST((julianday('now') - 2440587.5)*86400000 AS INTEGER)),
      PRIMARY KEY (post_id, user_id)
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS comments (
      id TEXT PRIMARY KEY,
      post_id TEXT NOT NULL,
      author_id TEXT NOT NULL,
      content TEXT NOT NULL,
      reply_to_id TEXT,
      likes_count INTEGER DEFAULT 0,
      created_at INTEGER DEFAULT (CAST((julianday('now') - 2440587.5)*86400000 AS INTEGER))
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS projects (
      id TEXT PRIMARY KEY,
      author_id TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      images TEXT DEFAULT '[]',
      skills TEXT DEFAULT '[]',
      team_members TEXT DEFAULT '[]',
      status TEXT DEFAULT 'idea',
      likes_count INTEGER DEFAULT 0,
      comments_count INTEGER DEFAULT 0,
      views_count INTEGER DEFAULT 0,
      university_tags TEXT DEFAULT '[]',
      zip_file_url TEXT,
      zip_file_name TEXT,
      zip_file_size INTEGER DEFAULT 0,
      zip_file_disk_name TEXT,
      created_at INTEGER DEFAULT (CAST((julianday('now') - 2440587.5)*86400000 AS INTEGER)),
      updated_at INTEGER DEFAULT (CAST((julianday('now') - 2440587.5)*86400000 AS INTEGER))
    )
  `);

  // Миграция для существующих БД - добавляем колонки если их нет
  try {
    db.run(`ALTER TABLE projects ADD COLUMN zip_file_url TEXT`);
    db.run(`ALTER TABLE projects ADD COLUMN zip_file_name TEXT`);
    db.run(`ALTER TABLE projects ADD COLUMN zip_file_size INTEGER DEFAULT 0`);
    db.run(`ALTER TABLE projects ADD COLUMN zip_file_disk_name TEXT`);
  } catch(e) {
    // Колонки уже существуют - игнорируем ошибку
  }

  db.run(`
    CREATE TABLE IF NOT EXISTS project_likes (
      project_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      liked_at INTEGER DEFAULT (CAST((julianday('now') - 2440587.5)*86400000 AS INTEGER)),
      PRIMARY KEY (project_id, user_id)
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS chats (
      id TEXT PRIMARY KEY,
      participant_ids TEXT NOT NULL,
      last_message TEXT,
      last_message_type TEXT DEFAULT 'text',
      last_sender_id TEXT,
      last_message_at INTEGER DEFAULT (CAST((julianday('now') - 2440587.5)*86400000 AS INTEGER)),
      created_at INTEGER DEFAULT (CAST((julianday('now') - 2440587.5)*86400000 AS INTEGER))
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS chat_unread (
      chat_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      unread_count INTEGER DEFAULT 0,
      PRIMARY KEY (chat_id, user_id)
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS messages (
      id TEXT PRIMARY KEY,
      chat_id TEXT NOT NULL,
      sender_id TEXT NOT NULL,
      content TEXT,
      type TEXT DEFAULT 'text',
      attachments TEXT DEFAULT '[]',
      project_id TEXT,
      is_read INTEGER DEFAULT 0,
      read_at INTEGER,
      created_at INTEGER DEFAULT (CAST((julianday('now') - 2440587.5)*86400000 AS INTEGER))
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS follows (
      follower_id TEXT NOT NULL,
      following_id TEXT NOT NULL,
      followed_at INTEGER DEFAULT (CAST((julianday('now') - 2440587.5)*86400000 AS INTEGER)),
      PRIMARY KEY (follower_id, following_id)
    )
  `);

  saveDb();
}

module.exports = { getDb, saveDb };
