/**
 * AUTH MIDDLEWARE
 * Runs before protected controllers. Reads the token, verifies the JWT, and either attaches
 * the user id to the request or rejects with 401.
 * The token is accepted from the `Authorization: Bearer <token>` header (the mobile app)
 * or, as a fallback, from the session cookie (browser, Postman).
 */
import type { Request, Response, NextFunction } from 'express';
import { AUTH_COOKIE, verifyToken } from '../services/auth.service';
import { HttpError } from '../utils/http';

// Adds an optional `userId` field to Express's Request type, so req.userId is typed
declare global {
  namespace Express {
    interface Request {
      userId?: number;
    }
  }
}

// Finds the token: Bearer header first, then the cookie
function extractToken(req: Request): string | null {
  const header = req.headers.authorization;
  if (typeof header === 'string' && header.startsWith('Bearer ')) return header.slice(7).trim();
  const cookie = req.cookies?.[AUTH_COOKIE];
  return typeof cookie === 'string' && cookie ? cookie : null;
}

export function requireAuth(req: Request, _res: Response, next: NextFunction): void {
  const token = extractToken(req);
  if (!token) throw new HttpError(401, 'Authentification requise', 'AUTH_REQUISE');

  req.userId = verifyToken(token); // Throws 401 if the token is invalid or expired
  next(); // Authenticated: continue to the controller
}
