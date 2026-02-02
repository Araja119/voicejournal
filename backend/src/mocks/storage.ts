import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

const UPLOAD_DIR = process.env.UPLOAD_DIR || './uploads';

// Ensure upload directories exist
function ensureDir(dir: string): void {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

export interface UploadResult {
  url: string;
  key: string;
  size: number;
}

export async function uploadFile(
  buffer: Buffer,
  folder: string,
  filename: string,
  contentType: string
): Promise<UploadResult> {
  const dir = path.join(UPLOAD_DIR, folder);
  ensureDir(dir);

  const ext = getExtensionFromContentType(contentType);
  const key = `${folder}/${filename}${ext}`;
  const filePath = path.join(UPLOAD_DIR, key);

  await fs.promises.writeFile(filePath, buffer);

  console.log(`=== MOCK STORAGE ===`);
  console.log(`Uploaded: ${key}`);
  console.log(`Size: ${buffer.length} bytes`);
  console.log(`====================`);

  return {
    url: `${process.env.APP_URL}/uploads/${key}`,
    key,
    size: buffer.length,
  };
}

export async function uploadAudio(
  buffer: Buffer,
  userId: string,
  journalId: string,
  recordingId: string
): Promise<UploadResult> {
  const folder = `recordings/${userId}/${journalId}`;
  return uploadFile(buffer, folder, recordingId, 'audio/mpeg');
}

export async function uploadImage(
  buffer: Buffer,
  folder: string,
  id: string,
  contentType: string
): Promise<UploadResult> {
  return uploadFile(buffer, folder, id, contentType);
}

export async function uploadProfilePhoto(buffer: Buffer, userId: string, contentType: string): Promise<UploadResult> {
  return uploadImage(buffer, 'profiles', userId, contentType);
}

export async function uploadJournalCover(buffer: Buffer, journalId: string, contentType: string): Promise<UploadResult> {
  return uploadImage(buffer, 'covers', journalId, contentType);
}

export async function uploadPersonPhoto(buffer: Buffer, personId: string, contentType: string): Promise<UploadResult> {
  return uploadImage(buffer, 'people', personId, contentType);
}

export async function deleteFile(key: string): Promise<void> {
  const filePath = path.join(UPLOAD_DIR, key);

  if (fs.existsSync(filePath)) {
    await fs.promises.unlink(filePath);
    console.log(`=== MOCK STORAGE ===`);
    console.log(`Deleted: ${key}`);
    console.log(`====================`);
  }
}

export function getSignedUrl(keyOrUrl: string, _expiresInSeconds: number = 3600): string {
  // In production, this would return a signed URL from S3/R2
  // For mock, just return the direct URL with a fake signature

  // If it's already a full URL, extract the path
  const appUrl = process.env.APP_URL || 'http://localhost:3000';
  let key = keyOrUrl;

  if (keyOrUrl.startsWith('http://') || keyOrUrl.startsWith('https://')) {
    // Extract the path after /uploads/
    const uploadsIndex = keyOrUrl.indexOf('/uploads/');
    if (uploadsIndex !== -1) {
      key = keyOrUrl.substring(uploadsIndex + '/uploads/'.length);
    }
  }

  return `${appUrl}/uploads/${key}?sig=mock&exp=${Date.now() + _expiresInSeconds * 1000}`;
}

function getExtensionFromContentType(contentType: string): string {
  const map: Record<string, string> = {
    'audio/mpeg': '.mp3',
    'audio/mp4': '.m4a',
    'audio/webm': '.webm',
    'audio/ogg': '.ogg',
    'audio/wav': '.wav',
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/gif': '.gif',
    'image/webp': '.webp',
  };

  return map[contentType] || '';
}

export function generateRecordingId(): string {
  return uuidv4();
}
