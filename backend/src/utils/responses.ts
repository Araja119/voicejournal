import { Response } from 'express';

export function success<T>(res: Response, data: T, statusCode: number = 200): Response {
  return res.status(statusCode).json(data);
}

export function created<T>(res: Response, data: T): Response {
  return res.status(201).json(data);
}

export function noContent(res: Response): Response {
  return res.status(204).send();
}

export function accepted<T>(res: Response, data: T): Response {
  return res.status(202).json(data);
}

export function error(
  res: Response,
  statusCode: number,
  code: string,
  message: string,
  details?: Record<string, unknown>
): Response {
  return res.status(statusCode).json({
    error: {
      code,
      message,
      details,
    },
  });
}

export function paginated<T>(
  res: Response,
  data: T[],
  total: number,
  limit: number,
  offset: number
): Response {
  return res.status(200).json({
    data,
    total,
    limit,
    offset,
  });
}
