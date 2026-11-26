/**
 * VANNE CONTROLLER
 * HTTP layer for vannes. Each handler is one call into vanne.service.
 */
import type { Request, Response } from 'express';
import * as vanneService from '../services/vanne.service';
import { bodyOf, idParam, optionalId } from '../utils/http';

// GET /api/vannes?parcelleId=1
export async function list(req: Request, res: Response) {
  res.json(await vanneService.listVannes({ parcelleId: optionalId(req.query.parcelleId, 'parcelleId') }));
}

// GET /api/vannes/:id
export async function get(req: Request, res: Response) {
  res.json(await vanneService.getVanne(idParam(req)));
}

// POST /api/vannes   { nom, parcelleId }
export async function create(req: Request, res: Response) {
  res.status(201).json(await vanneService.createVanne(bodyOf(req)));
}

// PUT /api/vannes/:id   { nom }
export async function update(req: Request, res: Response) {
  res.json(await vanneService.updateVanne(idParam(req), bodyOf(req)));
}

// DELETE /api/vannes/:id
export async function remove(req: Request, res: Response) {
  await vanneService.deleteVanne(idParam(req));
  res.status(204).send();
}

// POST /api/vannes/:id/commande   { action: "ouvrir" | "fermer" }
export async function commande(req: Request, res: Response) {
  res.json(await vanneService.commanderVanne(idParam(req), bodyOf(req).action));
}
