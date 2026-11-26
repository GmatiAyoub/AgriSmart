/**
 * ERROR MIDDLEWARE
 * Converts every error into a JSON response: { message, code? }.
 * `code` is stable and meant for the app; `message` is a French text for people.
 */
import type { ErrorRequestHandler, RequestHandler } from 'express';
import { HttpError } from '../utils/http';

export const notFoundHandler: RequestHandler = (_req, res) => {
  res.status(404).json({ message: 'Route introuvable', code: 'ROUTE_INTROUVABLE' });
};

export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  // Expected errors thrown by our code
  if (err instanceof HttpError) {
    res.status(err.status).json({ message: err.message, ...(err.code ? { code: err.code } : {}) });
    return;
  }
  // Database unique constraint violated
  if (err?.name === 'SequelizeUniqueConstraintError') {
    res.status(409).json({ message: 'Un enregistrement avec ces valeurs existe déjà', code: 'DUPLICATE' });
    return;
  }
  // Malformed JSON sent by the client
  if (err?.type === 'entity.parse.failed') {
    res.status(400).json({ message: 'Corps JSON invalide', code: 'JSON_INVALIDE' });
    return;
  }
  // Anything else is a bug: log it, don't leak details
  console.error('[error]', err);
  res.status(500).json({ message: 'Erreur interne du serveur', code: 'INTERNAL' });
};
