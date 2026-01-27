import { Request, Response, NextFunction } from 'express';
import { AppError } from '../utils/errors.js';
import { error } from '../utils/responses.js';

export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): Response {
  console.error('Error:', err);

  if (err instanceof AppError) {
    return error(res, err.statusCode, err.code, err.message, err.details);
  }

  // Handle JWT errors
  if (err.name === 'JsonWebTokenError') {
    return error(res, 401, 'UNAUTHORIZED', 'Invalid token');
  }

  if (err.name === 'TokenExpiredError') {
    return error(res, 401, 'UNAUTHORIZED', 'Token expired');
  }

  // Handle Prisma errors
  if (err.name === 'PrismaClientKnownRequestError') {
    const prismaError = err as unknown as { code: string; meta?: { target?: string[] } };
    if (prismaError.code === 'P2002') {
      const field = prismaError.meta?.target?.[0] || 'field';
      return error(res, 409, 'CONFLICT', `A record with this ${field} already exists`);
    }
    if (prismaError.code === 'P2025') {
      return error(res, 404, 'NOT_FOUND', 'Record not found');
    }
  }

  // Default internal error
  return error(
    res,
    500,
    'INTERNAL_ERROR',
    process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  );
}
