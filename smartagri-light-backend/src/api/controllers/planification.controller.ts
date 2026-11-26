/**
 * PLANIFICATION CONTROLLER
 * HTTP layer for planifications (managing them, not running them).
 */
import type { Request, Response } from 'express';
import * as planificationService from '../services/planification.service';
import { bodyOf, idParam, optionalId } from '../utils/http';

// GET /api/planifications?parcelleId=1
export async function list(req: Request, res: Response) {
  res.json(
    await planificationService.listPlanifications({ parcelleId: optionalId(req.query.parcelleId, 'parcelleId') })
  );
}

// GET /api/planifications/:id
export async function get(req: Request, res: Response) {
  res.json(await planificationService.getPlanification(idParam(req)));
}

// POST /api/planifications   { parcelleId, nom, heureDebut, dureeMinutes, joursSemaine, active? }
export async function create(req: Request, res: Response) {
  res.status(201).json(await planificationService.createPlanification(bodyOf(req)));
}

// PUT /api/planifications/:id
export async function update(req: Request, res: Response) {
  res.json(await planificationService.updatePlanification(idParam(req), bodyOf(req)));
}

// DELETE /api/planifications/:id
export async function remove(req: Request, res: Response) {
  await planificationService.deletePlanification(idParam(req));
  res.status(204).send();
}
