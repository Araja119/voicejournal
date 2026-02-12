import { z } from 'zod';

export const signupSchema = z.object({
  email: z.string().email('Invalid email format'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  display_name: z.string().min(1, 'Display name is required').max(100),
  phone_number: z.string().optional(),
});

export const loginSchema = z.object({
  email: z.string().email('Invalid email format'),
  password: z.string().min(1, 'Password is required'),
});

export const refreshSchema = z.object({
  refresh_token: z.string().min(1, 'Refresh token is required'),
});

export const forgotPasswordSchema = z.object({
  email: z.string().email('Invalid email format'),
});

export const resetPasswordSchema = z.object({
  token: z.string().min(1, 'Token is required'),
  new_password: z.string().min(8, 'Password must be at least 8 characters'),
});

export type SignupInput = z.infer<typeof signupSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
export const appleSignInSchema = z.object({
  identity_token: z.string().min(1, 'Identity token is required'),
  authorization_code: z.string().min(1, 'Authorization code is required'),
  apple_user_id: z.string().min(1, 'Apple user ID is required'),
  email: z.string().email().nullable().optional(),
  full_name: z.string().nullable().optional(),
});

export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;
export type AppleSignInInput = z.infer<typeof appleSignInSchema>;
