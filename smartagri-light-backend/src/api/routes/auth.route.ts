/**
 * AUTH ROUTES  (mounted at /api/auth)
 * Login and logout are public. There is deliberately NO register route.
 */
import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { loginHandler, logoutHandler, meHandler } from '../controllers/auth.controller';
import { requireAuth } from '../middleware/userAuth.middleware';

const router = Router();

// 10 login attempts per 15 minutes per IP: stops password guessing
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Trop de tentatives de connexion, réessayez plus tard', code: 'TROP_DE_TENTATIVES' },
});

router.post('/login', loginLimiter, loginHandler);
router.post('/logout', logoutHandler);
router.get('/me', requireAuth, meHandler); // lets the app check that its token is still valid

export default router;
