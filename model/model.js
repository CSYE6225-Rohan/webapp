const { Sequelize, DataTypes } = require('sequelize');

const { sequelize, authenticate } = require('..//config/db');

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

const File = sequelize.define('File', {
  id: {
    type: DataTypes.UUID,
    primaryKey: true,
    defaultValue: Sequelize.UUIDV4,  // Automatically generate UUID as primary key
  },
  file_name: {
    type: DataTypes.STRING,
    allowNull: false,  // The file name cannot be null
  },
  s3_key: {
    type: DataTypes.STRING,
    allowNull: false,  // The S3 key cannot be null
  },
  bucket_name: {
    type: DataTypes.STRING,
    allowNull: false,  // The bucket name cannot be null
  },
  content_type: {
    type: DataTypes.STRING,
    allowNull: false,  // The content type cannot be null
  },
  upload_date: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: Sequelize.fn('NOW'),  // Default value is the current timestamp in UTC
  },
  url: {
    type: DataTypes.STRING,  // This will be a virtual field, not stored in DB
    get() {
      return `https://${this.bucket_name}.s3.${process.env.AWS_REGION}.amazonaws.com/${this.s3_key}`;
    }
  }
}, {
  timestamps: false,  // No automatic createdAt or updatedAt fields
  tableName: 'files',  // Name of the table
});

module.exports = { HealthCheck, File };