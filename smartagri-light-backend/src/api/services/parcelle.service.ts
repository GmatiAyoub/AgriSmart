/**
 * PARCELLE SERVICE
 * Business logic for parcelles: list, read, create, edit, delete, and the "irrigation"
 * button that opens or closes all the vannes of a parcelle at once.
 */
import { Parcelle, Vanne } from '../models';
import { HttpError, asEnum, asText } from '../utils/http';
import { annulerPlanificationsEnCours, definirEtatParcelle } from './simulation.service';

export const ACTIONS = ['ouvrir', 'fermer'] as const;

type ParcelleAvecVannes = Parcelle & { vannes?: Vanne[] };

function toDto(p: ParcelleAvecVannes, avecVannes = false) {
  const vannes = p.vannes ?? [];
  const json = p.toJSON() as Record<string, unknown>;
  if (!avecVannes) delete json.vannes; // the list stays light; the detail view includes them
  return {
    ...json,
    nombreVannes: vannes.length,
    irrigationActive: vannes.some((v) => v.etat === 'ouverte'),
  };
}

async function trouver(id: number): Promise<Parcelle> {
  const parcelle = await Parcelle.findByPk(id);
  if (!parcelle) throw new HttpError(404, 'Parcelle introuvable', 'PARCELLE_INTROUVABLE');
  return parcelle;
}

export async function listParcelles() {
  const parcelles = await Parcelle.findAll({
    include: [{ model: Vanne, as: 'vannes', attributes: ['id', 'nom', 'etat'] }],
    order: [['nom', 'ASC']],
  });
  return parcelles.map((p) => toDto(p as ParcelleAvecVannes));
}

// One parcelle with all its vannes (the screen that opens when a parcelle is pressed)
export async function getParcelle(id: number) {
  const parcelle = await Parcelle.findByPk(id, {
    include: [{ model: Vanne, as: 'vannes' }],
    order: [[{ model: Vanne, as: 'vannes' }, 'nom', 'ASC']],
  });
  if (!parcelle) throw new HttpError(404, 'Parcelle introuvable', 'PARCELLE_INTROUVABLE');
  return toDto(parcelle as ParcelleAvecVannes, true);
}

export async function createParcelle(input: Record<string, unknown>) {
  const parcelle = await Parcelle.create({
    nom: asText(input.nom, 'nom') as string,
    culture: (input.culture ?? input.crop ?? 'Tomates') as string,
    humidite: Number(input.humidite ?? input.humidity ?? 30),
    seuil: Number(input.seuil ?? input.threshold ?? 40),
    localisation: asText(input.localisation, 'localisation', { required: false, max: 150 }),
    notes: asText(input.notes, 'notes', { required: false, max: 2000 }),
  });
  return toDto(parcelle as ParcelleAvecVannes);
}

// Partial update: only the fields present in the request are changed
export async function updateParcelle(id: number, input: Record<string, unknown>) {
  const parcelle = await trouver(id);
  if (input.nom !== undefined) parcelle.nom = asText(input.nom, 'nom') as string;
  if (input.culture !== undefined) parcelle.culture = String(input.culture);
  if (input.humidite !== undefined) parcelle.humidite = Number(input.humidite);
  if (input.seuil !== undefined) parcelle.seuil = Number(input.seuil);
  if (input.localisation !== undefined) {
    parcelle.localisation = asText(input.localisation, 'localisation', { required: false, max: 150 });
  }
  if (input.notes !== undefined) {
    parcelle.notes = asText(input.notes, 'notes', { required: false, max: 2000 });
  }
  await parcelle.save();
  return getParcelle(id);
}

// Vannes and planifications are deleted with the parcelle (foreign keys with CASCADE)
export async function deleteParcelle(id: number): Promise<void> {
  const parcelle = await trouver(id);
  await parcelle.destroy();
}

// THE irrigation button: opens or closes every vanne of the parcelle in one call
export async function commanderParcelle(id: number, action: unknown) {
  const act = asEnum(action, 'action', ACTIONS);
  await trouver(id);

  const nombreVannes = await Vanne.count({ where: { parcelleId: id } });
  if (nombreVannes === 0) {
    throw new HttpError(409, "Cette parcelle n'a aucune vanne", 'AUCUNE_VANNE');
  }

  await definirEtatParcelle(id, act === 'ouvrir' ? 'ouverte' : 'fermee');
  await annulerPlanificationsEnCours(id); // manual control wins over a running planification

  return { parcelleId: id, action: act, nombreVannes, irrigationActive: act === 'ouvrir' };
}
