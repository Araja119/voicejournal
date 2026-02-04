/**
 * Storage provider router.
 * Uses Cloudflare R2 when STORAGE_PROVIDER=r2, otherwise falls back to local mock.
 *
 * getSignedUrl is always async regardless of provider.
 */

export type { UploadResult } from '../mocks/storage.js';

// Use a flexible type to support both mock (sync getSignedUrl) and R2 (async getSignedUrl)
interface StorageProvider {
  uploadFile: typeof import('../mocks/storage.js').uploadFile;
  uploadAudio: typeof import('../mocks/storage.js').uploadAudio;
  uploadImage: typeof import('../mocks/storage.js').uploadImage;
  uploadProfilePhoto: typeof import('../mocks/storage.js').uploadProfilePhoto;
  uploadJournalCover: typeof import('../mocks/storage.js').uploadJournalCover;
  uploadPersonPhoto: typeof import('../mocks/storage.js').uploadPersonPhoto;
  deleteFile: typeof import('../mocks/storage.js').deleteFile;
  generateRecordingId: typeof import('../mocks/storage.js').generateRecordingId;
  getSignedUrl: (keyOrUrl: string, expiresInSeconds?: number) => string | Promise<string>;
}

let _mod: StorageProvider;

if (process.env.STORAGE_PROVIDER === 'r2') {
  _mod = await import('./r2-storage.js') as StorageProvider;
} else {
  _mod = await import('../mocks/storage.js') as StorageProvider;
}

export const uploadFile = _mod.uploadFile;
export const uploadAudio = _mod.uploadAudio;
export const uploadImage = _mod.uploadImage;
export const uploadProfilePhoto = _mod.uploadProfilePhoto;
export const uploadJournalCover = _mod.uploadJournalCover;
export const uploadPersonPhoto = _mod.uploadPersonPhoto;
export const deleteFile = _mod.deleteFile;
export const generateRecordingId = _mod.generateRecordingId;

// getSignedUrl: always async — wraps the mock's sync return if needed
const _rawGetSignedUrl = _mod.getSignedUrl;
export async function getSignedUrl(keyOrUrl: string, expiresInSeconds: number = 3600): Promise<string> {
  return _rawGetSignedUrl(keyOrUrl, expiresInSeconds);
}
