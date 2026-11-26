/**
 * VANNE SERVICE
 * Business logic for vannes: list (all or per parcelle), read, create, edit, delete, command.
 * A command opens or closes the valve AND its pump together (one state for both).
 */
import { Parcelle, Vanne } from '../models';
import { HttpError, asEnum, asInt, asText } from '../utils/http';
import { ACTIONS } from './parcelle.service';
import { annulerPlanificationsEnCours, definirEtatVanne } from './simulation.service';

export async function listVannes(filter: { parcelleId?: number } = {}) {
  return Vanne.findAll({
    where: filter.parcelleId ? { parcelleId: filter.parcelleId } : {},
    order: [['nom', 'ASC']],
  });
}

export async function getVanne(id: number) {
  const vanne = await Vanne.findByPk(id);
  if (!vanne) throw new HttpError(404, 'Vanne introuvable', 'VANNE_INTROUVABLE');
  return vanne;
}

// A vanne is created closed, inside an existing parcelle
export async function createVanne(input: Record<string, unknown>) {
  const parcelleId = asInt(input.parcelleId, 'parcelleId', 1, 4294967295);
  const parcelle = await Parcelle.findByPk(parcelleId);
  if (!parcelle) throw new HttpError(404, 'Parcelle introuvable', 'PARCELLE_INTROUVABLE');

  return Vanne.create({ nom: asText(input.nom, 'nom') as string, parcelleId });
}

// Only the name can be edited. A vanne stays in its parcelle.
export async function updateVanne(id: number, input: Record<string, unknown>) {
  const vanne = await getVanne(id);
  if (input.nom !== undefined) vanne.nom = asText(input.nom, 'nom') as string;
  await vanne.save();
  return vanne;
}

export async function deleteVanne(id: number): Promise<void> {
  const vanne = await getVanne(id);
  await vanne.destroy();
}

// Opens or closes one vanne (simulation: the state is written straight away)
export async function commanderVanne(id: number, action: unknown) {
  const act = asEnum(action, 'action', ACTIONS);
  const vanne = await getVanne(id);

  await definirEtatVanne(vanne.id, act === 'ouvrir' ? 'ouverte' : 'fermee');
  await annulerPlanificationsEnCours(vanne.parcelleId); // manual control wins over a running planification

  return getVanne(id); // the app gets the new state in the answer
}
