const express = require('express');
const router = express.Router();
const multer = require('multer');
const { getHealthStatus, uploadFile, getFile, deleteFile } = require('../controllers/conroller');

const upload = multer({ storage: multer.memoryStorage() });

// Allowed routes
router.get('/healthz', getHealthStatus);
// router.get('/cicd', getHealthStatus);
router.post('/v1/file', upload.single('file'), (req, res, next) => {
    uploadFile(req, res).catch(next); // Pass errors to next middleware
});

// Centralized error-handling middleware
router.use((err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        return res.status(400).send();
    }
    next(err); // Pass other errors to the default error handler
});
router.get('/v1/file/:id', getFile);
router.delete('/v1/file/:id', deleteFile);

// Catch-all for unsupported methods
const allowedRoutes = {
    '/healthz': ['GET'],
    '/v1/file': ['POST'],
    '/v1/file/:id': ['GET', 'DELETE']
};

router.all('*', (req, res) => {
    const route = Object.keys(allowedRoutes).find(r => {
        const regex = new RegExp(`^${r.replace(/:id/g, '[^/]+')}$`);
        return regex.test(req.path);
    });

    if (route && !allowedRoutes[route].includes(req.method)) {
        return res.status(405).send();
    }

    res.status(404).send();
});

module.exports = router;