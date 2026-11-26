/**
 * ENTRY POINT
 * Boots everything in order: Express app -> database -> scheduler -> HTTP server.
 * No business logic lives here, it only wires the pieces together.
 */
import 'dotenv/config'; // Loads .env into process.env (must run before anything reads env vars)
import http from 'http';
import express from 'express';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import sequelize from './config/database';
import './api/models'; // Side-effect import: registers all models and their associations
import apiRouter from './api/api.route';
import { errorHandler, notFoundHandler } from './api/middleware/error.middleware';
import { startScheduler, stopScheduler } from './api/services/scheduler.service';

const app = express();

// --- Global middleware ---------------------------------------------------
app.use(cors()); // The mobile app sends a Bearer token, so no cookie/credentials rules are needed
app.use(express.json({ limit: '100kb' })); // Parses JSON bodies, with a size cap
app.use(cookieParser()); // Exposes req.cookies (the cookie is an alternative to the Bearer token)

// --- Routes and error handling --------------------------------------------
app.use('/api', apiRouter); // Everything is mounted under /api
app.use(notFoundHandler); // Unknown routes -> 404 JSON
app.use(errorHandler); // Must be LAST: turns thrown errors into JSON responses

const port = Number(process.env.PORT ?? 3000);
const server = http.createServer(app);

// --- Startup sequence ------------------------------------------------------
async function start(): Promise<void> {
  await sequelize.authenticate(); // Fail fast if the database is unreachable
  console.log('[db] connected');

  // Optional: auto-create missing tables (DB_SYNC=true). `pnpm run seed` does it as well.
  if (process.env.DB_SYNC === 'true') {
    await sequelize.sync();
    console.log('[db] tables synchronized');
  }

  startScheduler(); // Starts the loop that runs the planifications (simulation)
  server.listen(port, () => console.log(`[http] listening on port ${port}`));
}

// --- Graceful shutdown (Ctrl+C or process manager stop) ------------------
function shutdown(): void {
  stopScheduler();
  server.close(() => sequelize.close().finally(() => process.exit(0)));
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

start().catch((err) => {
  console.error('[startup] failed', err);
  process.exit(1);
});
