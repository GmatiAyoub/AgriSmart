/**
 * MODEL INDEX (assembly point)
 * Relationships:
 *   Parcelle 1---* Vanne          (deleting a parcelle deletes its vannes)
 *   Parcelle 1---* Planification  (deleting a parcelle deletes its planifications)
 */
import sequelize from '../../config/database';
import { User } from './user.model';
import { Parcelle } from './parcelle.model';
import { Vanne } from './vanne.model';
import { Planification } from './planification.model';

Parcelle.hasMany(Vanne, { foreignKey: 'parcelleId', as: 'vannes', onDelete: 'CASCADE' });
Vanne.belongsTo(Parcelle, { foreignKey: 'parcelleId', as: 'parcelle' });

Parcelle.hasMany(Planification, { foreignKey: 'parcelleId', as: 'planifications', onDelete: 'CASCADE' });
Planification.belongsTo(Parcelle, { foreignKey: 'parcelleId', as: 'parcelle' });

export { sequelize, User, Parcelle, Vanne, Planification };
