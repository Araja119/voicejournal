import bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import prisma from '../utils/prisma.js';
import {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
  getRefreshTokenExpiry,
} from '../utils/jwt.js';
import { ConflictError, UnauthorizedError, NotFoundError } from '../utils/errors.js';
import { sendPasswordResetEmail } from '../mocks/email.js';
import type { SignupInput, LoginInput } from '../validators/auth.validators.js';

const SALT_ROUNDS = 12;

export interface AuthTokens {
  access_token: string;
  refresh_token: string;
}

export interface UserWithTokens {
  user: {
    id: string;
    email: string;
    display_name: string;
    phone_number: string | null;
    profile_photo_url: string | null;
    subscription_tier: string;
    created_at: Date;
  };
  access_token: string;
  refresh_token: string;
}

export async function signup(input: SignupInput): Promise<UserWithTokens> {
  // Check if email already exists
  const existing = await prisma.user.findUnique({
    where: { email: input.email },
  });

  if (existing) {
    throw new ConflictError('Email already registered');
  }

  // Hash password
  const passwordHash = await bcrypt.hash(input.password, SALT_ROUNDS);

  // Create user
  const user = await prisma.user.create({
    data: {
      email: input.email,
      passwordHash,
      displayName: input.display_name,
      phoneNumber: input.phone_number,
    },
  });

  // Generate tokens
  const tokens = await createTokensForUser(user.id, user.email);

  return {
    user: {
      id: user.id,
      email: user.email,
      display_name: user.displayName,
      phone_number: user.phoneNumber,
      profile_photo_url: user.profilePhotoUrl,
      subscription_tier: user.subscriptionTier,
      created_at: user.createdAt,
    },
    ...tokens,
  };
}

export async function login(input: LoginInput): Promise<UserWithTokens> {
  // Find user
  const user = await prisma.user.findUnique({
    where: { email: input.email },
  });

  if (!user) {
    throw new UnauthorizedError('Invalid email or password');
  }

  // Verify password
  const isValid = await bcrypt.compare(input.password, user.passwordHash);

  if (!isValid) {
    throw new UnauthorizedError('Invalid email or password');
  }

  // Generate tokens
  const tokens = await createTokensForUser(user.id, user.email);

  return {
    user: {
      id: user.id,
      email: user.email,
      display_name: user.displayName,
      phone_number: user.phoneNumber,
      profile_photo_url: user.profilePhotoUrl,
      subscription_tier: user.subscriptionTier,
      created_at: user.createdAt,
    },
    ...tokens,
  };
}

export async function refreshTokens(refreshToken: string): Promise<{ access_token: string }> {
  // Verify refresh token
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    throw new UnauthorizedError('Invalid refresh token');
  }

  // Check if refresh token exists in database
  const storedToken = await prisma.refreshToken.findUnique({
    where: { token: refreshToken },
    include: { user: true },
  });

  if (!storedToken || storedToken.expiresAt < new Date()) {
    throw new UnauthorizedError('Refresh token expired or invalid');
  }

  // Generate new access token
  const accessToken = generateAccessToken({
    userId: storedToken.user.id,
    email: storedToken.user.email,
  });

  return { access_token: accessToken };
}

export async function logout(userId: string): Promise<void> {
  // Delete all refresh tokens for user
  await prisma.refreshToken.deleteMany({
    where: { userId },
  });
}

export async function forgotPassword(email: string): Promise<void> {
  const user = await prisma.user.findUnique({
    where: { email },
  });

  // Always return success to prevent email enumeration
  if (!user) {
    return;
  }

  // Generate reset token (store it in a simple way for now - could use a separate table)
  const resetToken = uuidv4();

  // In a real app, store this token with expiry in database
  // For now, just send the email
  await sendPasswordResetEmail(user.email, resetToken, user.displayName);
}

export async function resetPassword(token: string, newPassword: string): Promise<void> {
  // In a real app, validate the reset token from database
  // For mock purposes, we'll just accept any token and require an email

  // This is a simplified implementation
  // In production, you'd store reset tokens in the database with expiry
  throw new NotFoundError('Password reset not implemented in mock mode');
}

async function createTokensForUser(userId: string, email: string): Promise<AuthTokens> {
  const tokenId = uuidv4();

  const accessToken = generateAccessToken({ userId, email });
  const refreshToken = generateRefreshToken({ userId, tokenId });

  // Store refresh token
  await prisma.refreshToken.create({
    data: {
      id: tokenId,
      token: refreshToken,
      userId,
      expiresAt: getRefreshTokenExpiry(),
    },
  });

  return {
    access_token: accessToken,
    refresh_token: refreshToken,
  };
}
