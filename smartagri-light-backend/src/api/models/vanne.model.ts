/**
 * VANNE MODEL  (table `vannes`)
 * A valve (with its pump). It always belongs to one parcelle.
 * `etat` is SIMULATED: it changes when a command arrives, not when hardware reports back.
 */
import { DataTypes, Model, type CreationOptional, type InferAttributes, type InferCreationAttributes } from 'sequelize';
import sequelize from '../../config/database';

export const ETATS = ['ouverte', 'fermee'] as const;
export type Etat = (typeof ETATS)[number];

export class Vanne extends Model<InferAttributes<Vanne>, InferCreationAttributes<Vanne>> {
  declare id: CreationOptional<number>;
  declare nom: string;
  declare parcelleId: number;
  declare etat: CreationOptional<Etat>;
  declare etatMajLe: CreationOptional<Date | null>; // when `etat` last changed
  declare createdAt: CreationOptional<Date>;
  declare updatedAt: CreationOptional<Date>;
}

Vanne.init(
  {
    id: { type: DataTypes.INTEGER.UNSIGNED, autoIncrement: true, primaryKey: true },
    nom: { type: DataTypes.STRING(100), allowNull: false },
    parcelleId: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
    etat: { type: DataTypes.ENUM(...ETATS), allowNull: false, defaultValue: 'fermee' },
    etatMajLe: { type: DataTypes.DATE, allowNull: true },
    createdAt: DataTypes.DATE,
    updatedAt: DataTypes.DATE,
  },
  { sequelize, tableName: 'vannes' }
);
