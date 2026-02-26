/**
 * Returns the WEB_APP_URL with guaranteed https:// prefix.
 * Ensures links are always valid URLs even if the env var omits the protocol.
 */
export function getAppUrl(): string {
  let url = process.env.WEB_APP_URL || 'http://localhost:3000';
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://' + url;
  }
  return url.replace(/\/+$/, '');
}
