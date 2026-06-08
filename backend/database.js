const { Pool } = require('pg');

// Подключение к PostgreSQL
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Проверка подключения
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
  process.exit(-1);
});

async function initDatabase() {
  const client = await pool.connect();
  try {
    console.log('🔧 Initializing database schema...');

    // Users table
    await client.query(`
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
        last_seen BIGINT,
        created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000
      )
    `);

    // Posts table
    await client.query(`
      CREATE TABLE IF NOT EXISTS posts (
        id TEXT PRIMARY KEY,
        author_id TEXT NOT NULL,
        content TEXT,
        project_id TEXT,
        images TEXT DEFAULT '[]',
        video_url TEXT,
        tags TEXT DEFAULT '[]',
        likes_count INTEGER DEFAULT 0,
        comments_count INTEGER DEFAULT 0,
        shares_count INTEGER DEFAULT 0,
        created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000
      )
    `);

    // Migration: add video_url column if not exists
    try {
      await client.query('ALTER TABLE posts ADD COLUMN video_url TEXT');
    } catch (e) {
      // column already exists, ignore
    }

    // Post likes table
    await client.query(`
      CREATE TABLE IF NOT EXISTS post_likes (
        post_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        liked_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000,
        PRIMARY KEY (post_id, user_id)
      )
    `);

    // Comments table
    await client.query(`
      CREATE TABLE IF NOT EXISTS comments (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL,
        author_id TEXT NOT NULL,
        content TEXT NOT NULL,
        reply_to_id TEXT,
        likes_count INTEGER DEFAULT 0,
        created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000
      )
    `);

    // Projects table
    await client.query(`
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
        created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000,
        updated_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000
      )
    `);

    // Project likes table
    await client.query(`
      CREATE TABLE IF NOT EXISTS project_likes (
        project_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        liked_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000,
        PRIMARY KEY (project_id, user_id)
      )
    `);

    // Chats table
    await client.query(`
      CREATE TABLE IF NOT EXISTS chats (
        id TEXT PRIMARY KEY,
        participant_ids TEXT NOT NULL,
        is_group INTEGER DEFAULT 0,
        last_message TEXT,
        last_message_type TEXT DEFAULT 'text',
        last_sender_id TEXT,
        last_message_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000,
        created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000
      )
    `);
    await client.query(`ALTER TABLE chats ADD COLUMN IF NOT EXISTS is_group INTEGER DEFAULT 0`);

    // Chat unread table
    await client.query(`
      CREATE TABLE IF NOT EXISTS chat_unread (
        chat_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        unread_count INTEGER DEFAULT 0,
        PRIMARY KEY (chat_id, user_id)
      )
    `);

    // Messages table
    await client.query(`
      CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        content TEXT,
        type TEXT DEFAULT 'text',
        attachments TEXT DEFAULT '[]',
        project_id TEXT,
        is_read INTEGER DEFAULT 0,
        read_at BIGINT,
        created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000
      )
    `);

    // Follows table
    await client.query(`
      CREATE TABLE IF NOT EXISTS follows (
        follower_id TEXT NOT NULL,
        following_id TEXT NOT NULL,
        followed_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000,
        PRIMARY KEY (follower_id, following_id)
      )
    `);

    // Project comments table
    await client.query(`
      CREATE TABLE IF NOT EXISTS project_comments (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        author_id TEXT NOT NULL,
        content TEXT NOT NULL,
        reply_to_id TEXT,
        likes_count INTEGER DEFAULT 0,
        created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000
      )
    `);

    // Teams table - команды для проектов
    await client.query(`
      CREATE TABLE IF NOT EXISTS teams (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        project_id TEXT,
        creator_id TEXT NOT NULL,
        chat_id TEXT,
        members TEXT DEFAULT '[]',
        created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000
      )
    `);

    // Team invitations table - приглашения в команды
    await client.query(`
      CREATE TABLE IF NOT EXISTS team_invitations (
        id TEXT PRIMARY KEY,
        team_id TEXT NOT NULL,
        from_user_id TEXT NOT NULL,
        to_user_id TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000
      )
    `);

    // Saved posts table - сохранённые посты
    await client.query(`
      CREATE TABLE IF NOT EXISTS saved_posts (
        post_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000,
        PRIMARY KEY (post_id, user_id)
      )
    `);

    // Saved projects table - сохранённые проекты
    await client.query(`
      CREATE TABLE IF NOT EXISTS saved_projects (
        project_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000,
        PRIMARY KEY (project_id, user_id)
      )
    `);

    // Notifications table - уведомления
    await client.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        data TEXT DEFAULT '{}',
        is_read BOOLEAN DEFAULT false,
        created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000
      )
    `);

    console.log('✅ Database schema initialized successfully');
  } catch (error) {
    console.error('❌ Error initializing database:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Экспорт pool для использования в server.js
module.exports = { pool, initDatabase };
