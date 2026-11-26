/**
 * PARCELLE MODEL  (table `parcelles`)
 * A piece of land. It owns its vannes and its planifications.
 */
import { DataTypes, Model, type CreationOptional, type InferAttributes, type InferCreationAttributes } from 'sequelize';
import sequelize from '../../config/database';

export class Parcelle extends Model<InferAttributes<Parcelle>, InferCreationAttributes<Parcelle>> {
  declare id: CreationOptional<number>;
  declare nom: string;
  declare culture: CreationOptional<string>;
  declare humidite: CreationOptional<number>;
  declare seuil: CreationOptional<number>;
  declare localisation: CreationOptional<string | null>;
  declare notes: CreationOptional<string | null>;
  declare createdAt: CreationOptional<Date>;
  declare updatedAt: CreationOptional<Date>;
}

Parcelle.init(
  {
    id: { type: DataTypes.INTEGER.UNSIGNED, autoIncrement: true, primaryKey: true },
    nom: { type: DataTypes.STRING(100), allowNull: false },
    culture: { type: DataTypes.STRING(100), allowNull: false, defaultValue: 'Tomates' },
    humidite: { type: DataTypes.FLOAT, allowNull: false, defaultValue: 30 },
    seuil: { type: DataTypes.FLOAT, allowNull: false, defaultValue: 40 },
    localisation: { type: DataTypes.STRING(150), allowNull: true },
    notes: { type: DataTypes.TEXT, allowNull: true },
    createdAt: DataTypes.DATE, // Filled automatically by Sequelize
    updatedAt: DataTypes.DATE,
  },
  { sequelize, tableName: 'parcelles' }
);
