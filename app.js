const express = require('express');
const app = express();
const endpoints = require('./routes/endpoints');

// Set up the routes
const { sequelize, authenticate } = require('./config/db');

sequelize.sync();


const allowedRoutes = {
    "/healthz": ["GET"],
    "/v1/file": ["POST"],
    "/v1/file/:id": ["GET", "DELETE"]
};

app.use((req, res, next) => {
    if (req.path === "/healthz" && (req.headers['content-length'] && parseInt(req.headers['content-length']) > 0|| Object.keys(req.query).length > 0)) {
        return res.status(400).send();
    }
    next();
});

app.use('/', endpoints);

app.use((req, res) => {
    // Check if the request matches any defined endpoint
    const routeExists = Object.keys(allowedRoutes).some(route => {
        const regex = new RegExp(`^${route.replace(/:id/g, "[^/]+")}$`);
        return regex.test(req.path);
    });

    if (routeExists) {
        return res.status(405);
    }

    // If no matching route found, return 404 with custom headers
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
