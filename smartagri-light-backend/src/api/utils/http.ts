/**
 * HTTP HELPERS (shared utilities)
 * - HttpError: an error carrying an HTTP status AND an optional stable code,
 *   so the mobile app can react to the code instead of parsing the message.
 * - validators: check and clean untrusted input.
 */
import type { Request } from 'express';

export type Body = Record<string, unknown>;

export class HttpError extends Error {
  status: number;
  code?: string; // e.g. 'PARCELLE_INTROUVABLE'
  constructor(status: number, message: string, code?: string) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

export const isRecord = (v: unknown): v is Body =>
  typeof v === 'object' && v !== null && !Array.isArray(v);

export const bodyOf = (req: Request): Body => (isRecord(req.body) ? req.body : {});

// Validates a string field: trims, enforces max length, handles required/optional
export function asText(
  v: unknown,
  field: string,
  opts: { required?: boolean; max?: number } = {}
): string | null {
  const { required = true, max = 100 } = opts;
  if (v === undefined || v === null || v === '') {
    if (required) throw new HttpError(400, `${field} est obligatoire`, 'VALIDATION');
    return null;
  }
  if (typeof v !== 'string') throw new HttpError(400, `${field} doit être un texte`, 'VALIDATION');
  const t = v.trim();
  if (!t) {
    if (required) throw new HttpError(400, `${field} est obligatoire`, 'VALIDATION');
    return null;
  }
  if (t.length > max) {
    throw new HttpError(400, `${field} : ${max} caractères maximum`, 'VALIDATION');
  }
  return t;
}

// Validates an integer within [min, max]. Accepts numeric strings (query params).
export function asInt(v: unknown, field: string, min: number, max: number): number {
  const n = typeof v === 'string' && v.trim() !== '' ? Number(v) : v;
  if (typeof n !== 'number' || !Number.isInteger(n) || n < min || n > max) {
    throw new HttpError(400, `${field} doit être un entier entre ${min} et ${max}`, 'VALIDATION');
  }
  return n;
}

// Validates that a value is one of a fixed list
export function asEnum<T extends string>(v: unknown, field: string, allowed: readonly T[]): T {
  if (typeof v !== 'string' || !allowed.includes(v as T)) {
    throw new HttpError(400, `${field} doit valoir : ${allowed.join(', ')}`, 'VALIDATION');
  }
  return v as T;
}

// Route parameter -> validated positive integer (bad id = clean 400, not a database error)
export const idParam = (req: Request, name = 'id'): number =>
  asInt(req.params[name], name, 1, 4294967295);

// Optional query id such as ?parcelleId=2. Returns undefined when absent.
export function optionalId(v: unknown, field: string): number | undefined {
  if (v === undefined || v === '') return undefined;
  return asInt(v, field, 1, 4294967295);
}
