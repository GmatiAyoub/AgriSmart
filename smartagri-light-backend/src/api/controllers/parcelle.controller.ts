/**
 * PARCELLE CONTROLLER
 * HTTP layer for parcelles. Each handler is one call into parcelle.service.
 */
import type { Request, Response } from 'express';
import * as parcelleService from '../services/parcelle.service';
import { bodyOf, idParam } from '../utils/http';

// GET /api/parcelles
export async function list(_req: Request, res: Response) {
  res.json(await parcelleService.listParcelles());
}

// GET /api/parcelles/:id   (includes the vannes)
export async function get(req: Request, res: Response) {
  res.json(await parcelleService.getParcelle(idParam(req)));
}

// POST /api/parcelles   { nom, localisation?, notes? }
export async function create(req: Request, res: Response) {
  res.status(201).json(await parcelleService.createParcelle(bodyOf(req)));
}

// PUT /api/parcelles/:id
export async function update(req: Request, res: Response) {
  res.json(await parcelleService.updateParcelle(idParam(req), bodyOf(req)));
}

// DELETE /api/parcelles/:id
export async function remove(req: Request, res: Response) {
  await parcelleService.deleteParcelle(idParam(req));
  res.status(204).send(); // 204 = success, no body
}

// POST /api/parcelles/:id/irrigation   { action: "ouvrir" | "fermer" }
export async function irrigation(req: Request, res: Response) {
  res.json(await parcelleService.commanderParcelle(idParam(req), bodyOf(req).action));
}
