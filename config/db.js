const { Sequelize } = require('sequelize');
const path = process.env.NODE_ENV === '.env';
require('dotenv').config({ path });

const sequelize = new Sequelize(process.env.database, process.env.username, process.env.password, {
    host: process.env.hostname,
    dialect: 'mysql'
});

const authenticate = sequelize.authenticate().then(
    () => {
        console.log('Connection has been established successfully.');
    }).catch((error) => {
        console.error('Unable to connect to the database: ', error);
    });

module.exports = { sequelize, authenticate };
