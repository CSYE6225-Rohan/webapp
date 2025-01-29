const express = require('express');
const app = express();
const endpoints = require('./routes/endpoints')

// Set up the routes
const { sequelize, authenticate } = require('./config/db')

sequelize.sync();

// Middleware to reject requests with any payload or non get methods
app.use((req, res, next) => {
    console.log('1');
    if (req.headers['content-length'] && parseInt(req.headers['content-length']) > 0) 
        return res.status(400).send();
    if (req.method!='GET')
        return res.status(405).send()
    next();

});

app.use('/healthz', endpoints);

app.use("*", (_, res) => {
    res.status(404).send();
});


module.exports = app; 