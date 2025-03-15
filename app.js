const express = require('express');
const app = express();
const endpoints = require('./routes/endpoints')

// Set up the routes
const { sequelize, authenticate } = require('./config/db')

sequelize.sync();

// Middleware to reject requests with any payload or non get methods
// app.use((req, res, next) => {
   
//     if (req.method!='GET')
//         return res.status(405).send()
//     if ((req.headers['content-length'] && parseInt(req.headers['content-length']) > 0) || Object.keys(req.query).length > 0) 
//         return res.status(400).send();
    
//     next();

// });

app.use('/', endpoints);

app.use("*", (_, res) => {
    res.status(404).set({
        'Cache-Control': 'no-cache',
        'Content-Length': '0',
        'Content-Type': 'application/octet-stream',
        'ETag': 'W/"0-2jmj7l5rSw0yVb/vlWAYkK/YBwk"',
        'Expires': '-1',
        'X-Powered-By': 'Express',
        'Server': 'nginx',
        'RateLimit': '10000-in-1min; r=9999; t=60',
        'RateLimit-Policy': '10000-in-1min; q=10000; w=60; pk=:NGFmOTQ2ZWNkYjdl:'
    }).send();
});


module.exports = app; 