import prisma from '../utils/prisma.js';
import { NotFoundError } from '../utils/errors.js';
import { uploadProfilePhoto } from '../mocks/storage.js';
import type { UpdateUserInput, PushTokenInput } from '../validators/users.validators.js';

export interface UserProfile {
  id: string;
  email: string;
  display_name: string;
  phone_number: string | null;
  profile_photo_url: string | null;
  subscription_tier: string;
  created_at: Date;
}

export async function getProfile(userId: string): Promise<UserProfile> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
  });

  if (!user) {
    throw new NotFoundError('User');
  }

  return {
    id: user.id,
    email: user.email,
    display_name: user.displayName,
    phone_number: user.phoneNumber,
    profile_photo_url: user.profilePhotoUrl,
    subscription_tier: user.subscriptionTier,
    created_at: user.createdAt,
  };
}

export async function updateProfile(userId: string, input: UpdateUserInput): Promise<UserProfile> {
  const user = await prisma.user.update({
    where: { id: userId },
    data: {
      displayName: input.display_name,
      phoneNumber: input.phone_number,
    },
  });

  return {
    id: user.id,
    email: user.email,
    display_name: user.displayName,
    phone_number: user.phoneNumber,
    profile_photo_url: user.profilePhotoUrl,
    subscription_tier: user.subscriptionTier,
    created_at: user.createdAt,
  };
}

export async function updateProfilePhoto(
  userId: string,
  buffer: Buffer,
  contentType: string
): Promise<{ profile_photo_url: string }> {
  const result = await uploadProfilePhoto(buffer, userId, contentType);

  await prisma.user.update({
    where: { id: userId },
    data: { profilePhotoUrl: result.url },
  });

  return { profile_photo_url: result.url };
}

export async function registerPushToken(userId: string, input: PushTokenInput): Promise<void> {
  // Check if token already exists
  const existing = await prisma.pushToken.findFirst({
    where: {
      userId,
      token: input.token,
    },
  });

  if (existing) {
    return;
  }

  await prisma.pushToken.create({
    data: {
      userId,
      token: input.token,
      platform: input.platform,
    },
  });
}

export async function getUserPushTokens(userId: string): Promise<string[]> {
  const tokens = await prisma.pushToken.findMany({
    where: { userId },
    select: { token: true },
  });

  return tokens.map((t) => t.token);
}
