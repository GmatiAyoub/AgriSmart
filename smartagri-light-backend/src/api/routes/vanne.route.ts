/** VANNE ROUTES  (mounted at /api/vannes, protected) */
import { Router } from 'express';
import * as controller from '../controllers/vanne.controller';

const router = Router();

router.get('/', controller.list); // ?parcelleId=
router.post('/', controller.create);
router.get('/:id', controller.get);
router.put('/:id', controller.update);
router.delete('/:id', controller.remove);
router.post('/:id/commande', controller.commande); // open or close one vanne

export default router;
