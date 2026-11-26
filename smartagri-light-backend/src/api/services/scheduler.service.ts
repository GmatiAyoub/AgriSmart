/**
 * SCHEDULER SERVICE (simulation)
 * Every few seconds it looks at the planifications:
 *   (1) stops the ones whose time is over  -> closes the vannes of their parcelle
 *   (2) starts the ones that are due now   -> opens the vannes of their parcelle
 * Nothing is sent to any hardware: the states are written straight in the database.
 */
import { Op } from 'sequelize';
import { Planification } from '../models';
import { definirEtatParcelle } from './simulation.service';

const tickSeconds = Number(process.env.SCHEDULER_TICK_SECONDS ?? 15);
const TICK_MS = (Number.isFinite(tickSeconds) && tickSeconds > 0 ? tickSeconds : 15) * 1000;
const TIMEZONE = process.env.APP_TIMEZONE ?? 'Africa/Tunis';
const WEEKDAYS: Record<string, number> = { Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6 };

let timer: NodeJS.Timeout | null = null;
let ticking = false; // prevents two ticks from overlapping if one runs long

export function startScheduler(): void {
  if (timer) return;
  timer = setInterval(() => void tick(), TICK_MS);
  void tick(); // also run once at startup
  console.log(`[scheduler] started (every ${TICK_MS / 1000}s)`);
}

export function stopScheduler(): void {
  if (timer) clearInterval(timer);
  timer = null;
}

// Current date, minutes since midnight and weekday in the farm's timezone (not the server's)
function localParts(date: Date) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: TIMEZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    weekday: 'short',
    hourCycle: 'h23',
  }).formatToParts(date);

  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? '';
  return {
    date: `${get('year')}-${get('month')}-${get('day')}`,
    minutes: Number(get('hour')) * 60 + Number(get('minute')),
    weekday: WEEKDAYS[get('weekday')],
  };
}

async function tick(): Promise<void> {
  if (ticking) return;
  ticking = true;
  try {
    const now = new Date();
    await stopExpired(now);
    await startDue(now);
  } catch (err) {
    console.error('[scheduler] tick failed', err);
  } finally {
    ticking = false;
  }
}

// Planifications whose end time has passed: close their vannes
async function stopExpired(now: Date): Promise<void> {
  const expired = await Planification.findAll({ where: { actifJusqua: { [Op.lte]: now } } });
  for (const planification of expired) {
    await definirEtatParcelle(planification.parcelleId, 'fermee');
    await planification.update({ actifJusqua: null });
    console.log(`[scheduler] « ${planification.nom} » finished: vannes closed`);
  }
}

// Planifications that should be running now but are not: open their vannes
async function startDue(now: Date): Promise<void> {
  const local = localParts(now);
  const candidates = await Planification.findAll({ where: { active: true, actifJusqua: null } });

  for (const planification of candidates) {
    if (planification.derniereExecution === local.date) continue; // already ran today
    if (!planification.joursSemaine.includes(local.weekday)) continue;

    const [h, m] = planification.heureDebut.split(':').map(Number);
    const ecoule = local.minutes - (h * 60 + m);
    if (ecoule < 0 || ecoule >= planification.dureeMinutes) continue; // not inside its window

    const restantMin = planification.dureeMinutes - ecoule;
    await definirEtatParcelle(planification.parcelleId, 'ouverte');
    await planification.update({
      derniereExecution: local.date,
      actifJusqua: new Date(now.getTime() + restantMin * 60_000),
    });
    console.log(`[scheduler] « ${planification.nom} » started: vannes open for ${restantMin} min`);
  }
}
