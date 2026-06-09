const cloudinary = require('cloudinary').v2;

const CLOUD_NAME = process.env.CLOUDINARY_CLOUD_NAME;
const API_KEY = process.env.CLOUDINARY_API_KEY;
const API_SECRET = process.env.CLOUDINARY_API_SECRET;

const isConfigured = !!(CLOUD_NAME && API_KEY && API_SECRET);

if (!isConfigured) {
  console.warn('⚠️ Cloudinary not configured — video/image uploads will fail');
}

cloudinary.config({
  cloud_name: CLOUD_NAME,
  api_key: API_KEY,
  api_secret: API_SECRET,
});

const FOLDER = 'student-connect/posts';

async function uploadImage(filePath, postId, index) {
  if (!isConfigured) throw new Error('Cloudinary not configured');
  const result = await cloudinary.uploader.upload(filePath, {
    folder: FOLDER,
    public_id: `${postId}/image_${index}`,
    resource_type: 'image',
  });
  return result.secure_url;
}

async function uploadVideo(filePath, postId) {
  if (!isConfigured) throw new Error('Cloudinary not configured');
  const result = await cloudinary.uploader.upload(filePath, {
    folder: FOLDER,
    public_id: `${postId}/video`,
    resource_type: 'video',
    eager: [{ width: 480, crop: 'scale' }],
    eager_async: true,
  });
  return result.secure_url;
}

function getVideoThumbnailUrl(videoUrl) {
  if (!videoUrl || !videoUrl.includes('cloudinary.com')) return null;
  return videoUrl.replace('/upload/', '/upload/w_480/').replace(/\.[^.]+$/, '.jpg');
}

async function deletePostFiles(postId) {
  try {
    await cloudinary.api.delete_resources_by_prefix(
      `${FOLDER}/${postId}/`,
      { resource_type: 'image' }
    );
  } catch (_) {}
  try {
    await cloudinary.api.delete_resources_by_prefix(
      `${FOLDER}/${postId}/`,
      { resource_type: 'video' }
    );
  } catch (_) {}
}

async function deleteFileByUrl(url) {
  if (!url || !url.includes('cloudinary.com')) return;
  try {
    const parts = url.split('/');
    const versionIdx = parts.findIndex(p => p.startsWith('v') && /^\d+$/.test(p.slice(1)));
    if (versionIdx === -1) return;
    const publicIdWithExt = parts.slice(versionIdx + 1).join('/');
    const publicId = publicIdWithExt.replace(/\.[^.]+$/, '');
    const isVideo = url.includes('/video/upload/');
    await cloudinary.uploader.destroy(publicId, {
      resource_type: isVideo ? 'video' : 'image',
    });
  } catch (e) {
    console.error('Delete from cloudinary error:', e.message);
  }
}

module.exports = { uploadImage, uploadVideo, getVideoThumbnailUrl, deletePostFiles, deleteFileByUrl };
