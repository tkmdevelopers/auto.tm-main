import * as bcrypt from 'bcryptjs';
import * as crypto from 'crypto';

export async function hashToken(token: string): Promise<string> {
  // SHA256 the token first to ensure it fits within bcrypt's 72-byte limit
  const sha = crypto.createHash('sha256').update(token).digest('hex');
  return bcrypt.hash(sha, 10);
}

export async function validateToken(token: string, hash: string): Promise<boolean> {
  const sha = crypto.createHash('sha256').update(token).digest('hex');
  return bcrypt.compare(sha, hash);
}
