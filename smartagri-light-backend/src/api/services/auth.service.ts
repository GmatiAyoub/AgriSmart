/**
 * AUTH SERVICE
 * Login logic for the single account. It only READS the user table:
 * it never creates, edits or deletes accounts (the seed script creates the row).
 */
import argon2 from 'argon2';
import jwt from 'jsonwebtoken';
import { User } from '../models';
import { HttpError } from '../utils/http';

// Name of the HTTP-only cookie (alternative to the Bearer token)
export const AUTH_COOKIE = 'smartagri_session';

// Refuse to start without a secret: signing tokens with `undefined` would be a security hole
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) throw new Error('JWT_SECRET is not set');

// Single source of truth for the session length: used by BOTH the JWT and the cookie
const hours = Number(process.env.SESSION_HOURS ?? 8);
export const SESSION_SECONDS = (Number.isFinite(hours) && hours > 0 ? hours : 8) * 3600;

// Verifies credentials and returns a signed token.
export async function login(username: unknown, password: unknown) {
  if (typeof username !== 'string' || typeof password !== 'string' || !username || !password) {
    throw new HttpError(400, "Nom d'utilisateur et mot de passe obligatoires", 'VALIDATION');
  }

  const user = await User.findOne({ where: { username } });
  let valid = false;
  if (user) {
    try {
      valid = await argon2.verify(user.passwordHash, password); // Compares against the stored hash
    } catch {
      valid = false; // A malformed hash counts as a failed login
    }
  }
  // Same message for "unknown user" and "wrong password" so attackers can't tell which
  if (!user || !valid) throw new HttpError(401, 'Identifiants invalides', 'IDENTIFIANTS_INVALIDES');

  // The token only carries the user id (as `sub`), nothing sensitive
  const token = jwt.sign({}, JWT_SECRET as string, {
    subject: String(user.id),
    expiresIn: SESSION_SECONDS,
  });

  return { token, user: { id: user.id, username: user.username } };
}

// Validates a token and returns the user id inside it
export function verifyToken(token: string): number {
  try {
    const payload = jwt.verify(token, JWT_SECRET as string); // Checks signature and expiry
    const userId = Number(typeof payload === 'object' ? payload.sub : NaN);
    if (!Number.isInteger(userId)) throw new Error('bad subject');
    return userId;
  } catch {
    throw new HttpError(401, 'Session invalide ou expirée', 'SESSION_INVALIDE');
  }
}

// Used by GET /auth/me so the app can check whether its token is still valid
export async function getUtilisateur(userId: number) {
  // `attributes` excludes passwordHash from the query entirely
  const user = await User.findByPk(userId, { attributes: ['id', 'username'] });
  if (!user) throw new HttpError(401, 'Compte introuvable', 'SESSION_INVALIDE');
  return { id: user.id, username: user.username };
}
