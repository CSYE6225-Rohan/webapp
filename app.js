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
    res.status(404).send();
});

module.exports = app;
