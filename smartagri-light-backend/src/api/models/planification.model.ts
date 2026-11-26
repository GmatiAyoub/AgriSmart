/**
 * PLANIFICATION MODEL  (table `planifications`)
 * A recurring timer for a whole parcelle: "open all its vannes at HH:mm on these weekdays
 * for N minutes". The scheduler service reads these rows and runs them (simulation).
 */
import { DataTypes, Model, type CreationOptional, type InferAttributes, type InferCreationAttributes } from 'sequelize';
import sequelize from '../../config/database';

export class Planification extends Model<InferAttributes<Planification>, InferCreationAttributes<Planification>> {
  declare id: CreationOptional<number>;
  declare parcelleId: number;
  declare nom: string;
  declare heureDebut: string; // 'HH:mm' in the farm's local time
  declare dureeMinutes: number;
  declare joursSemaine: number[]; // 0 = dimanche ... 6 = samedi (stored as a JSON array)
  declare active: CreationOptional<boolean>;
  declare derniereExecution: CreationOptional<string | null>; // 'YYYY-MM-DD'; prevents running twice a day
  declare actifJusqua: CreationOptional<Date | null>; // set while running: when the scheduler must stop it
  declare createdAt: CreationOptional<Date>;
  declare updatedAt: CreationOptional<Date>;
}

Planification.init(
  {
    id: { type: DataTypes.INTEGER.UNSIGNED, autoIncrement: true, primaryKey: true },
    parcelleId: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
    nom: { type: DataTypes.STRING(100), allowNull: false },
    heureDebut: { type: DataTypes.STRING(5), allowNull: false },
    dureeMinutes: { type: DataTypes.SMALLINT.UNSIGNED, allowNull: false },
    joursSemaine: { type: DataTypes.JSON, allowNull: false },
    active: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
    derniereExecution: { type: DataTypes.STRING(10), allowNull: true },
    actifJusqua: { type: DataTypes.DATE, allowNull: true },
    createdAt: DataTypes.DATE,
    updatedAt: DataTypes.DATE,
  },
  { sequelize, tableName: 'planifications' }
);
