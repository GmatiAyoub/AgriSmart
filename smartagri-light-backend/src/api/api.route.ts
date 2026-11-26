/**
 * CENTRAL API ROUTER  (mounted at /api by server.ts)
 * Public routes first, then the auth gate, then protected routes.
 */
import { Router } from 'express';
import authRoutes from './routes/auth.route';
import parcelleRoutes from './routes/parcelle.route';
import vanneRoutes from './routes/vanne.route';
import planificationRoutes from './routes/planification.route';
import { requireAuth } from './middleware/userAuth.middleware';

const router = Router();

router.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

// Public: login/logout only (no registration)
router.use('/auth', authRoutes);

// Everything registered BELOW this line requires a valid token
router.use(requireAuth);
router.use('/parcelles', parcelleRoutes);
router.use('/vannes', vanneRoutes);
router.use('/planifications', planificationRoutes);

export default router;
