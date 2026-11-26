/**
 * AUTH CONTROLLER
 * Handles login, logout and "who am I".
 * Login returns the token in the body (for the mobile app) AND sets it in a cookie (for browsers).
 */
import type { Request, Response } from 'express';
import { AUTH_COOKIE, SESSION_SECONDS, getUtilisateur, login } from '../services/auth.service';
import { bodyOf } from '../utils/http';

// Cookie hardening: not readable by scripts, HTTPS-only in production, not sent cross-site
const cookieOptions = {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'strict' as const,
  path: '/',
};

// POST /api/auth/login   { username, password }  ->  { token, user }
export async function loginHandler(req: Request, res: Response) {
  const { username, password } = bodyOf(req);
  const { token, user } = await login(username, password);

  res.cookie(AUTH_COOKIE, token, { ...cookieOptions, maxAge: SESSION_SECONDS * 1000 });
  res.json({ token, user });
}

// POST /api/auth/logout: deletes the cookie (the mobile app simply forgets its token)
export function logoutHandler(_req: Request, res: Response) {
  res.clearCookie(AUTH_COOKIE, cookieOptions);
  res.status(204).send();
}

// GET /api/auth/me: protected by requireAuth in the route file
export async function meHandler(req: Request, res: Response) {
  res.json({ user: await getUtilisateur(req.userId as number) });
}
