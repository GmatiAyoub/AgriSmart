/**
 * SIMULATION SERVICE
 * The ONLY place where "the hardware" is pretended. Opening or closing simply writes the new
 * state in the database, as if the valves had obeyed instantly.
 * If real hardware is added one day (MQTT, relays...), this is the file to replace:
 * send the real command here, and update `etat` when the device confirms.
 */
import { Op } from 'sequelize';
import { Planification, Vanne } from '../models';
import type { Etat } from '../models/vanne.model';

// Sets every vanne of a parcelle to the given state. Returns how many were changed.
export async function definirEtatParcelle(parcelleId: number, etat: Etat): Promise<number> {
  const [count] = await Vanne.update({ etat, etatMajLe: new Date() }, { where: { parcelleId } });
  return count;
}

// Sets one vanne to the given state.
export async function definirEtatVanne(vanneId: number, etat: Etat): Promise<void> {
  await Vanne.update({ etat, etatMajLe: new Date() }, { where: { id: vanneId } });
}

// Manual control wins over automation: any planification running on this parcelle loses its
// stop timer. Its `derniereExecution` is untouched, so it will not restart again today.
export async function annulerPlanificationsEnCours(parcelleId: number): Promise<void> {
  await Planification.update(
    { actifJusqua: null },
    { where: { parcelleId, actifJusqua: { [Op.ne]: null } } }
  );
}
