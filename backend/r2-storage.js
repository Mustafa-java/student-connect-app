const { S3Client, PutObjectCommand, DeleteObjectsCommand } = require('@aws-sdk/client-s3');
const fs = require('fs');
const path = require('path');

const ACCOUNT_ID = process.env.R2_ACCOUNT_ID;
const ACCESS_KEY_ID = process.env.R2_ACCESS_KEY_ID;
const SECRET_ACCESS_KEY = process.env.R2_SECRET_ACCESS_KEY;
const BUCKET = process.env.R2_BUCKET_NAME || 'student-connect-uploads';

const isConfigured = !!(ACCOUNT_ID && ACCESS_KEY_ID && SECRET_ACCESS_KEY);

if (!isConfigured) {
  console.warn('⚠️ R2 not configured — uploads will fail');
}

const s3 = isConfigured ? new S3Client({
  region: 'auto',
  endpoint: `https://${ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: ACCESS_KEY_ID,
    secretAccessKey: SECRET_ACCESS_KEY,
  },
}) : null;

const PUBLIC_URL_BASE = process.env.R2_PUBLIC_URL || '';

async function uploadFile(filePath, key, contentType) {
  if (!s3) throw new Error('R2 not configured');
  const fileBuffer = fs.readFileSync(filePath);
  await s3.send(new PutObjectCommand({
    Bucket: BUCKET,
    Key: key,
    Body: fileBuffer,
    ContentType: contentType,
  }));
  return `${PUBLIC_URL_BASE}/${key}`;
}

async function uploadImage(filePath, postId, index) {
  const ext = path.extname(filePath).toLowerCase();
  const mime = ext === '.png' ? 'image/png' : ext === '.gif' ? 'image/gif' : 'image/jpeg';
  const key = `posts/${postId}/image_${index}${ext}`;
  return uploadFile(filePath, key, mime);
}

async function uploadVideo(filePath, postId) {
  const ext = path.extname(filePath).toLowerCase();
  const key = `posts/${postId}/video${ext}`;
  return uploadFile(filePath, key, 'video/mp4');
}

async function uploadFileAsZip(filePath, postId, index) {
  const key = `projects/${postId}/file_${index}.zip`;
  return uploadFile(filePath, key, 'application/zip');
}

function getVideoThumbnailUrl(videoUrl) {
  return null;
}

async function deleteFilesByPrefix(prefix) {
  if (!s3) return;
  try {
    const { ListObjectsV2Command, paginateListObjectsV2 } = require('@aws-sdk/client-s3');
    const objects = [];
    const paginator = paginateListObjectsV2({ client: s3 }, { Bucket: BUCKET, Prefix: prefix });
    for await (const page of paginator) {
      if (page.Contents) {
        objects.push(...page.Contents.map(c => ({ Key: c.Key })));
      }
    }
    if (objects.length === 0) return;
    await s3.send(new DeleteObjectsCommand({
      Bucket: BUCKET,
      Delete: { Objects: objects },
    }));
  } catch (e) {
    console.error('R2 delete error:', e.message);
  }
}

async function deletePostFiles(postId) {
  await deleteFilesByPrefix(`posts/${postId}/`);
}

async function deleteProjectFiles(projectId) {
  await deleteFilesByPrefix(`projects/${projectId}/`);
}

module.exports = { uploadImage, uploadVideo, uploadFileAsZip, getVideoThumbnailUrl, deletePostFiles, deleteProjectFiles };
