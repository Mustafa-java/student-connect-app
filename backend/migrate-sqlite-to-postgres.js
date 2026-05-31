require('dotenv').config();
const { Pool } = require('pg');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// PostgreSQL connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// SQLite connection
const dbPath = path.join(__dirname, 'student_connect.db');
const sqliteDb = new sqlite3.Database(dbPath);

// Utility function to promisify SQLite queries
function sqliteAll(query, params = []) {
  return new Promise((resolve, reject) => {
    sqliteDb.all(query, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
}

async function migrateTable(tableName, columns) {
  console.log(`\n📦 Migrating table: ${tableName}`);

  try {
    // Get data from SQLite
    const rows = await sqliteAll(`SELECT * FROM ${tableName}`);
    console.log(`   Found ${rows.length} rows in SQLite`);

    if (rows.length === 0) {
      console.log(`   ⏭️  Skipping empty table`);
      return;
    }

    // Insert into PostgreSQL
    let migrated = 0;
    for (const row of rows) {
      const columnNames = columns.join(', ');
      const placeholders = columns.map((_, i) => `$${i + 1}`).join(', ');
      const values = columns.map(col => row[col]);

      const query = `
        INSERT INTO ${tableName} (${columnNames})
        VALUES (${placeholders})
        ON CONFLICT DO NOTHING
      `;

      try {
        await pool.query(query, values);
        migrated++;
      } catch (err) {
        console.error(`   ❌ Error inserting row:`, err.message);
      }
    }

    console.log(`   ✅ Migrated ${migrated}/${rows.length} rows`);
  } catch (err) {
    console.error(`   ❌ Error migrating ${tableName}:`, err.message);
  }
}

async function migrate() {
  console.log('🚀 Starting migration from SQLite to PostgreSQL...\n');

  try {
    // Test connections
    console.log('🔌 Testing connections...');
    await pool.query('SELECT NOW()');
    console.log('   ✅ PostgreSQL connected');

    await sqliteAll('SELECT 1');
    console.log('   ✅ SQLite connected\n');

    // Migrate tables in order (respecting foreign keys)
    await migrateTable('users', [
      'id', 'name', 'email', 'password_hash', 'avatar_url', 'bio',
      'university', 'faculty', 'course', 'skills', 'projects_count',
      'followers_count', 'following_count', 'is_online', 'last_seen', 'created_at'
    ]);

    await migrateTable('posts', [
      'id', 'author_id', 'content', 'project_id', 'images', 'tags',
      'likes_count', 'comments_count', 'shares_count', 'created_at'
    ]);

    await migrateTable('post_likes', [
      'post_id', 'user_id', 'liked_at'
    ]);

    await migrateTable('comments', [
      'id', 'post_id', 'author_id', 'content', 'reply_to_id',
      'likes_count', 'created_at'
    ]);

    await migrateTable('projects', [
      'id', 'author_id', 'title', 'description', 'images', 'skills',
      'team_members', 'status', 'likes_count', 'comments_count',
      'views_count', 'university_tags', 'zip_file_url', 'zip_file_name',
      'zip_file_size', 'zip_file_disk_name', 'created_at', 'updated_at'
    ]);

    await migrateTable('project_likes', [
      'project_id', 'user_id', 'liked_at'
    ]);

    await migrateTable('chats', [
      'id', 'participant_ids', 'last_message', 'last_message_type',
      'last_sender_id', 'last_message_at', 'created_at'
    ]);

    await migrateTable('chat_unread', [
      'chat_id', 'user_id', 'unread_count'
    ]);

    await migrateTable('messages', [
      'id', 'chat_id', 'sender_id', 'content', 'type', 'attachments',
      'project_id', 'is_read', 'read_at', 'created_at'
    ]);

    await migrateTable('follows', [
      'follower_id', 'following_id', 'followed_at'
    ]);

    console.log('\n✅ Migration completed successfully!');
  } catch (err) {
    console.error('\n❌ Migration failed:', err);
  } finally {
    sqliteDb.close();
    await pool.end();
  }
}

// Run migration
migrate();
