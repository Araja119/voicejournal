import { S3Client, PutObjectCommand, DeleteObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl as s3GetSignedUrl } from '@aws-sdk/s3-request-presigner';
import { v4 as uuidv4 } from 'uuid';

export interface UploadResult {
  url: string;
  key: string;
  size: number;
}

const R2_ACCOUNT_ID = process.env.R2_ACCOUNT_ID!;
const R2_ACCESS_KEY_ID = process.env.R2_ACCESS_KEY_ID!;
const R2_SECRET_ACCESS_KEY = process.env.R2_SECRET_ACCESS_KEY!;
const R2_BUCKET_NAME = process.env.R2_BUCKET_NAME || 'voicejournal';

const s3Client = new S3Client({
  region: 'auto',
  endpoint: `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: R2_ACCESS_KEY_ID,
    secretAccessKey: R2_SECRET_ACCESS_KEY,
  },
});

function getExtensionFromContentType(contentType: string): string {
  const map: Record<string, string> = {
    'audio/mpeg': '.mp3',
    'audio/mp4': '.m4a',
    'audio/x-m4a': '.m4a',
    'audio/m4a': '.m4a',
    'audio/aac': '.aac',
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

export async function uploadFile(
  buffer: Buffer,
  folder: string,
  filename: string,
  contentType: string
): Promise<UploadResult> {
  const ext = getExtensionFromContentType(contentType);
  const key = `${folder}/${filename}${ext}`;

  await s3Client.send(new PutObjectCommand({
    Bucket: R2_BUCKET_NAME,
    Key: key,
    Body: buffer,
    ContentType: contentType,
  }));

  return {
    url: key,
    key,
    size: buffer.length,
  };
}

export async function uploadImage(
  buffer: Buffer,
  folder: string,
  id: string,
  contentType: string
): Promise<UploadResult> {
  return uploadFile(buffer, folder, id, contentType);
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

export async function uploadProfilePhoto(
  buffer: Buffer,
  userId: string,
  contentType: string
): Promise<UploadResult> {
  return uploadFile(buffer, 'profiles', userId, contentType);
}

export async function uploadJournalCover(
  buffer: Buffer,
  journalId: string,
  contentType: string
): Promise<UploadResult> {
  return uploadFile(buffer, 'covers', journalId, contentType);
}

export async function uploadPersonPhoto(
  buffer: Buffer,
  personId: string,
  contentType: string
): Promise<UploadResult> {
  return uploadFile(buffer, 'people', personId, contentType);
}

export async function deleteFile(key: string): Promise<void> {
  await s3Client.send(new DeleteObjectCommand({
    Bucket: R2_BUCKET_NAME,
    Key: key,
  }));
}

export async function getSignedUrl(keyOrUrl: string, expiresInSeconds: number = 3600): Promise<string> {
  // Extract key from full URL if needed (handles legacy data)
  let key = keyOrUrl;
  if (keyOrUrl.startsWith('http://') || keyOrUrl.startsWith('https://')) {
    const uploadsIndex = keyOrUrl.indexOf('/uploads/');
    if (uploadsIndex !== -1) {
      key = keyOrUrl.substring(uploadsIndex + '/uploads/'.length);
    }
  }

  const command = new GetObjectCommand({
    Bucket: R2_BUCKET_NAME,
    Key: key,
  });

  return s3GetSignedUrl(s3Client, command, { expiresIn: expiresInSeconds });
}

export function generateRecordingId(): string {
  return uuidv4();
}
