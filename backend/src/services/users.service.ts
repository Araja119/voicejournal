import prisma from '../utils/prisma.js';
import { NotFoundError } from '../utils/errors.js';
import { uploadProfilePhoto } from '../mocks/storage.js';
import type { UpdateUserInput, PushTokenInput } from '../validators/users.validators.js';

/**
 * Link all "self" relationship Person records to their owner User accounts
 * and sync the user's profile photo to them.
 * This runs on startup to fix any unlinked self-persons.
 */
export async function syncSelfPersonsWithUsers(): Promise<void> {
  try {
    // Find all persons with relationship "self" or "myself" that don't have a linkedUserId
    const selfPersons = await prisma.person.findMany({
      where: {
        relationship: { in: ['self', 'Self', 'myself', 'Myself'] },
        linkedUserId: null,
      },
      include: {
        owner: true,
      },
    });

    for (const person of selfPersons) {
      // Link the person to their owner
      await prisma.person.update({
        where: { id: person.id },
        data: {
          linkedUserId: person.ownerId,
          // Sync the owner's profile photo and name
          profilePhotoUrl: person.owner.profilePhotoUrl,
          name: person.owner.displayName,
        },
      });
      console.log(`Linked self-person "${person.name}" to user ${person.ownerId}`);
    }

    // Also sync profile photos for already-linked persons (in case user updated their photo before the sync was added)
    const linkedPersons = await prisma.person.findMany({
      where: {
        linkedUserId: { not: null },
      },
    });

    for (const person of linkedPersons) {
      // Fetch the linked user separately since the relation isn't defined in Prisma
      const linkedUser = await prisma.user.findUnique({
        where: { id: person.linkedUserId! },
      });

      if (linkedUser && person.profilePhotoUrl !== linkedUser.profilePhotoUrl) {
        await prisma.person.update({
          where: { id: person.id },
          data: {
            profilePhotoUrl: linkedUser.profilePhotoUrl,
            name: linkedUser.displayName,
          },
        });
        console.log(`Synced profile photo for linked person "${person.name}"`);
      }
    }
  } catch (error) {
    console.error('Error syncing self persons with users:', error);
  }
}

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

  // Sync name to any Person records linked to this user (e.g., "Myself" person for self-journals)
  if (input.display_name) {
    await prisma.person.updateMany({
      where: { linkedUserId: userId },
      data: { name: input.display_name },
    });
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

export async function updateProfilePhoto(
  userId: string,
  buffer: Buffer,
  contentType: string
): Promise<{ profile_photo_url: string }> {
  const result = await uploadProfilePhoto(buffer, userId, contentType);

  // Update user's profile photo
  await prisma.user.update({
    where: { id: userId },
    data: { profilePhotoUrl: result.url },
  });

  // Also sync profile photo to any Person records linked to this user
  await prisma.person.updateMany({
    where: { linkedUserId: userId },
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
