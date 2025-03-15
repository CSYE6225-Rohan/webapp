const express = require('express');
const router = express.Router();
const multer = require('multer');
const { getHealthStatus, uploadFile, getFile, deleteFile } = require('../controllers/conroller');

const upload = multer({ storage: multer.memoryStorage() });

router.get('/healthz', getHealthStatus);
router.post('/v1/file', upload.single('file'), uploadFile);
router.get('/v1/file/:id', getFile);
router.delete('/v1/file/:id', deleteFile);

module.exports = router;