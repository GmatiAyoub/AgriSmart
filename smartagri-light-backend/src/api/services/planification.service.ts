/**
 * PLANIFICATION SERVICE
 * Rules for planifications: validation, no overlap on the same parcelle, and stopping a
 * running planification when it is disabled, retimed or deleted.
 * The basic database operations come from the Planification model (Sequelize).
 * Actual EXECUTION happens in scheduler.service.ts.
 */
import { Op } from 'sequelize';
import { Parcelle, Planification } from '../models';
import { HttpError, asInt, asText } from '../utils/http';
import { definirEtatParcelle } from './simulation.service';

const TIME_RE = /^([01]\d|2[0-3]):[0-5]\d$/; // Strict 24h "HH:mm"
const DAY = 1440; // minutes
const WEEK = 7 * DAY;

// Validates a start time string
function parseHeure(v: unknown): string {
  if (typeof v !== 'string' || !TIME_RE.test(v)) {
    throw new HttpError(400, 'heureDebut doit être au format HH:mm', 'VALIDATION');
  }
  return v;
}

// Validates the weekday list, removes duplicates and sorts it
function parseJours(v: unknown): number[] {
  if (!Array.isArray(v) || v.length === 0 || v.length > 7) {
    throw new HttpError(
      400,
      'joursSemaine doit être une liste non vide de jours (0 = dimanche ... 6 = samedi)',
      'VALIDATION'
    );
  }
  const jours = v.map((d) => asInt(d, 'joursSemaine', 0, 6));
  return [...new Set(jours)].sort((a, b) => a - b);
}

/* ------------------------- Overlap detection ------------------------- */

// Each run becomes an interval [start, end) on a weekly timeline measured in minutes
function runsOf(jours: number[], heure: string, duree: number): [number, number][] {
  const [h, m] = heure.split(':').map(Number);
  return jours.map((d) => {
    const start = d * DAY + h * 60 + m;
    return [start, start + duree];
  });
}

// The week is circular: a Saturday-night run can spill into Sunday morning
function overlaps(a: [number, number], b: [number, number]): boolean {
  return [-WEEK, 0, WEEK].some((shift) => a[0] < b[1] + shift && b[0] + shift < a[1]);
}

// Rejects the change if it collides with another active planification of the same parcelle
async function verifierChevauchement(
  parcelleId: number,
  jours: number[],
  heure: string,
  duree: number,
  ignoreId?: number
): Promise<void> {
  const autres = await Planification.findAll({
    where: { parcelleId, active: true, ...(ignoreId ? { id: { [Op.ne]: ignoreId } } : {}) },
  });
  const miennes = runsOf(jours, heure, duree);

  for (const autre of autres) {
    const siennes = runsOf(autre.joursSemaine, autre.heureDebut, autre.dureeMinutes);
    if (miennes.some((a) => siennes.some((b) => overlaps(a, b)))) {
      throw new HttpError(
        409,
        `Chevauchement avec la planification « ${autre.nom} » de la même parcelle`,
        'PLANIFICATION_CHEVAUCHEMENT'
      );
    }
  }
}

/* --------------------------- Operations --------------------------- */

// Each planification carries its parcelle's name so the screen can show it without a second request
export async function listPlanifications(filter: { parcelleId?: number } = {}) {
  return Planification.findAll({
    where: filter.parcelleId ? { parcelleId: filter.parcelleId } : {},
    include: [{ model: Parcelle, as: 'parcelle', attributes: ['id', 'nom'] }],
    order: [['heureDebut', 'ASC']],
  });
}

export async function getPlanification(id: number) {
  const planification = await Planification.findByPk(id, {
    include: [{ model: Parcelle, as: 'parcelle', attributes: ['id', 'nom'] }],
  });
  if (!planification) {
    throw new HttpError(404, 'Planification introuvable', 'PLANIFICATION_INTROUVABLE');
  }
  return planification;
}

export async function createPlanification(input: Record<string, unknown>) {
  const parcelleId = asInt(input.parcelleId, 'parcelleId', 1, 4294967295);
  if (!(await Parcelle.findByPk(parcelleId))) {
    throw new HttpError(404, 'Parcelle introuvable', 'PARCELLE_INTROUVABLE');
  }

  const nom = asText(input.nom, 'nom') as string;
  const heureDebut = parseHeure(input.heureDebut);
  const dureeMinutes = asInt(input.dureeMinutes, 'dureeMinutes', 1, 1440);
  const joursSemaine = parseJours(input.joursSemaine);
  const active = input.active === undefined ? true : input.active === true;

  // A disabled planification never runs, so it can't conflict
  if (active) await verifierChevauchement(parcelleId, joursSemaine, heureDebut, dureeMinutes);

  const creee = await Planification.create({ parcelleId, nom, heureDebut, dureeMinutes, joursSemaine, active });
  return getPlanification(creee.id);
}

// Partial update. The parcelle cannot be changed (delete and recreate instead).
export async function updatePlanification(id: number, input: Record<string, unknown>) {
  const planification = await Planification.findByPk(id);
  if (!planification) {
    throw new HttpError(404, 'Planification introuvable', 'PLANIFICATION_INTROUVABLE');
  }

  if (input.nom !== undefined) planification.nom = asText(input.nom, 'nom') as string;
  if (input.heureDebut !== undefined) planification.heureDebut = parseHeure(input.heureDebut);
  if (input.dureeMinutes !== undefined) {
    planification.dureeMinutes = asInt(input.dureeMinutes, 'dureeMinutes', 1, 1440);
  }
  if (input.joursSemaine !== undefined) planification.joursSemaine = parseJours(input.joursSemaine);
  if (input.active !== undefined) {
    if (typeof input.active !== 'boolean') throw new HttpError(400, 'active doit être un booléen', 'VALIDATION');
    planification.active = input.active;
  }

  if (planification.active) {
    await verifierChevauchement(
      planification.parcelleId,
      planification.joursSemaine,
      planification.heureDebut,
      planification.dureeMinutes,
      planification.id // ignore itself
    );
  }

  // If it is running right now and gets disabled or retimed, stop it so it doesn't keep stale timing
  if (planification.actifJusqua && (!planification.active || input.heureDebut || input.dureeMinutes)) {
    await arreter(planification);
  }

  await planification.save();
  return getPlanification(id);
}

export async function deletePlanification(id: number): Promise<void> {
  const planification = await Planification.findByPk(id);
  if (!planification) {
    throw new HttpError(404, 'Planification introuvable', 'PLANIFICATION_INTROUVABLE');
  }
  if (planification.actifJusqua) await arreter(planification); // don't leave the vannes open
  await planification.destroy();
}

// Closes the parcelle's vannes and clears the running marker (simulation)
async function arreter(planification: Planification): Promise<void> {
  await definirEtatParcelle(planification.parcelleId, 'fermee');
  planification.actifJusqua = null;
}
