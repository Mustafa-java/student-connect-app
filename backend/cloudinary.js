const cloudinary = require('cloudinary').v2;

const CLOUD_NAME = process.env.CLOUDINARY_CLOUD_NAME;
const API_KEY = process.env.CLOUDINARY_API_KEY;
const API_SECRET = process.env.CLOUDINARY_API_SECRET;

const isConfigured = !!(CLOUD_NAME && API_KEY && API_SECRET);

if (!isConfigured) {
  console.warn('⚠️ Cloudinary not configured — uploads will fail');
}

cloudinary.config({
  cloud_name: CLOUD_NAME,
  api_key: API_KEY,
  api_secret: API_SECRET,
});

const FOLDER = 'student-connect';

async function withRetry(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (err) {
      const isLast = i === maxRetries - 1;
      if (isLast) throw err;
      console.warn(`Cloudinary retry ${i + 1}/${maxRetries}: ${err.message}`);
      await new Promise(r => setTimeout(r, 1000 * (i + 1)));
    }
  }
}

async function uploadImage(filePath, postId, index) {
  if (!isConfigured) throw new Error('Cloudinary not configured');
  const result = await withRetry(() =>
    cloudinary.uploader.upload(filePath, {
      folder: `${FOLDER}/posts`,
      public_id: `${postId}/image_${index}`,
      resource_type: 'image',
    })
  );
  return result.secure_url;
}

async function uploadVideo(filePath, postId) {
  if (!isConfigured) throw new Error('Cloudinary not configured');
  const result = await withRetry(() =>
    cloudinary.uploader.upload(filePath, {
      folder: `${FOLDER}/posts`,
      public_id: `${postId}/video`,
      resource_type: 'video',
      timeout: 60000,
    })
  );
  return result.secure_url;
}

async function uploadZip(filePath, projectId, index) {
  if (!isConfigured) throw new Error('Cloudinary not configured');
  const result = await withRetry(() =>
    cloudinary.uploader.upload(filePath, {
      folder: `${FOLDER}/projects`,
      public_id: `${projectId}/file_${index}`,
      resource_type: 'raw',
      timeout: 60000,
    })
  );
  return result.secure_url;
}

function getVideoThumbnailUrl(videoUrl) {
  if (!videoUrl || !videoUrl.includes('cloudinary.com')) return null;
  return videoUrl.replace('/upload/', '/upload/w_480/').replace(/\.[^.]+$/, '.jpg');
}

async function deleteResourcesByPrefix(prefix) {
  if (!isConfigured) return;
  try {
    const { resources } = await cloudinary.api.resources_by_asset_folder(`${FOLDER}/${prefix}`);
    const publicIds = resources.map(r => r.public_id);
    if (publicIds.length > 0) {
      await cloudinary.api.delete_resources(publicIds, { resource_type: 'image' });
    }
  } catch (_) {}
  try {
    const { resources } = await cloudinary.api.resources_by_asset_folder(`${FOLDER}/${prefix}`);
    const publicIds = resources.map(r => r.public_id);
    if (publicIds.length > 0) {
      await cloudinary.api.delete_resources(publicIds, { resource_type: 'video' });
    }
  } catch (_) {}
  try {
    const { resources } = await cloudinary.api.resources_by_asset_folder(`${FOLDER}/${prefix}`);
    const publicIds = resources.map(r => r.public_id);
    if (publicIds.length > 0) {
      await cloudinary.api.delete_resources(publicIds, { resource_type: 'raw' });
    }
  } catch (_) {}
}

async function deletePostFiles(postId) {
  await deleteResourcesByPrefix(`posts/${postId}`);
}

async function deleteProjectFiles(projectId) {
  await deleteResourcesByPrefix(`projects/${projectId}`);
}

module.exports = { uploadImage, uploadVideo, uploadZip, getVideoThumbnailUrl, deletePostFiles, deleteProjectFiles };
