const { Sequelize, DataTypes } = require('sequelize');

const { sequelize, authenticate } = require('..//config/db')

const HealthCheck = sequelize.define('HealthCheck', {
  checkId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,  // Auto-incrementing primary key
  },
  datetime: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: Sequelize.fn('NOW'),  // Default value is the current timestamp in UTC
  },
}, {
  // Additional options
  timestamps: false,  // No automatic createdAt or updatedAt fields
  tableName: 'health_checks',  // Name of the table
});


module.exports = HealthCheck;