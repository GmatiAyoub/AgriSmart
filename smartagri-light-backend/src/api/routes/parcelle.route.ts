/** PARCELLE ROUTES  (mounted at /api/parcelles, protected) */
import { Router } from 'express';
import * as controller from '../controllers/parcelle.controller';

const router = Router();

router.get('/', controller.list);
router.post('/', controller.create);
router.get('/:id', controller.get);
router.put('/:id', controller.update);
router.delete('/:id', controller.remove);
router.post('/:id/irrigation', controller.irrigation); // open or close ALL the vannes

export default router;
