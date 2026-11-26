/**
 * SEED SCRIPT (run with `pnpm run seed`, not part of the API)
 * 1) creates the tables if they do not exist
 * 2) creates the single account from SEED_USERNAME / SEED_PASSWORD (.env), if it does not exist
 * 3) adds some demo parcelles, vannes and a planification, only if the database has no parcelle yet
 * Safe to run several times.
 */
import 'dotenv/config';
import argon2 from 'argon2';
import sequelize from '../config/database';
import { Parcelle, Planification, User, Vanne } from '../api/models';

async function main(): Promise<void> {
  const username = process.env.SEED_USERNAME;
  const password = process.env.SEED_PASSWORD;
  if (!username || !password) {
    throw new Error('SEED_USERNAME et SEED_PASSWORD doivent être définis dans .env');
  }

  await sequelize.authenticate();
  await sequelize.sync(); // creates missing tables
  console.log('[seed] tables ready');

  // The single account. The password is stored as an Argon2 hash, never in clear.
  if (await User.findOne({ where: { username } })) {
    console.log(`[seed] account "${username}" already exists`);
  } else {
    await User.create({ username, passwordHash: await argon2.hash(password) });
    console.log(`[seed] account "${username}" created`);
  }

  // Demo data, only on an empty database
  if ((await Parcelle.count()) > 0) {
    console.log('[seed] parcelles already exist, demo data skipped');
  } else {
    const nord = await Parcelle.create({ nom: 'Parcelle Nord', localisation: 'Kébili', notes: 'Palmeraie' });
    const sud = await Parcelle.create({ nom: 'Parcelle Sud', localisation: 'Kébili', notes: 'Serre' });
    await Vanne.bulkCreate([
      { nom: 'Vanne 1', parcelleId: nord.id },
      { nom: 'Vanne 2', parcelleId: nord.id },
      { nom: 'Vanne 3', parcelleId: nord.id },
      { nom: 'Vanne A', parcelleId: sud.id },
      { nom: 'Vanne B', parcelleId: sud.id },
    ]);
    await Planification.create({
      parcelleId: nord.id,
      nom: 'Arrosage du matin',
      heureDebut: '06:00',
      dureeMinutes: 30,
      joursSemaine: [0, 1, 2, 3, 4, 5, 6],
    });
    console.log('[seed] demo data created (2 parcelles, 5 vannes, 1 planification)');
  }

  await sequelize.close();
}

main().catch((err) => {
  console.error('[seed] failed', err);
  process.exit(1);
});
