/** PLANIFICATION ROUTES  (mounted at /api/planifications, protected) */
import { Router } from 'express';
import * as controller from '../controllers/planification.controller';

const router = Router();

router.get('/', controller.list); // ?parcelleId=
router.post('/', controller.create);
router.get('/:id', controller.get);
router.put('/:id', controller.update);
router.delete('/:id', controller.remove);

export default router;
