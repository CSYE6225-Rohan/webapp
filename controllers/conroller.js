const {HealthCheck} = require('../model/model'); // Import your model for health db
const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
const {File} = require('../model/model'); // Import model for file db
const { sequelize } = require('../config/db');
// const multer = require('multer');

const s3 = new AWS.S3({
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    region: process.env.AWS_REGION
});

// const upload = multer({ storage: multer.memoryStorage() });

const getBucketName = async () => {
    try {
        const data = await s3.listBuckets().promise();
        if (data.Buckets.length === 1) {
            const bucketName = data.Buckets[0].Name;
            console.log("Bucket Name: ", bucketName);
            return bucketName;
        } else {
            console.error("More than one bucket or none found. Please check.");
        }
    } catch (error) {
        console.error("Error retrieving bucket name: ", error);
    }
};


exports.getHealthStatus = async (req, res) => {
    res.setHeader('Cache-Control', 'no-cache');
    const { sequelize, authenticate } = require('../config/db')
    
    //Checking database connection
    if (authenticate){
        console.log('Connection is intact.');

        try {
            //Now adding check log to table
            await HealthCheck.create({datetime:new Date().toISOString() });
            res.status(200).send();
        } catch (error) {
            console.error("Table doesn't exist.");
            res.status(503).send();
        }

    }
    else{
        console.error("Database connection lost.");
        res.status(503).send();
    }
};

exports.uploadFile = async (req, res) => {
    if (!req.file) {
        return res.status(400).send();
    }

    const fileKey = `uploads/${uuidv4()}-${req.file.originalname}`;
    const uploadDate = new Date().toISOString();

    try {
        const bucketName = await getBucketName();

        // Make sure the bucket name is a valid string
        if (!bucketName) {
            return res.status(400).send();
        }

        const s3Response = await s3.upload({
            Bucket: bucketName,
            Key: fileKey,
            Body: req.file.buffer,
            ContentType: req.file.mimetype
        }).promise();

        const url = `https://${bucketName}.s3.${process.env.AWS_REGION}.amazonaws.com/${fileKey}`;

        const file = await File.create({
            // id: uuidv4(),
            file_name: req.file.originalname,
            s3_key: fileKey,
            bucket_name: bucketName,
            content_type: req.file.mimetype,
            url: url,
            upload_date: uploadDate });

        res.status(201).json({
            file_name: req.file.originalname,
            id: file.id,
            url: url,
            upload_date: uploadDate });
    } catch (error) {
        console.error(error);
        res.status(400).send();
    }
};

exports.getFile = async (req, res) => {
    try {
        if (req.headers['content-length'] && parseInt(req.headers['content-length']) > 0|| Object.keys(req.query).length > 0)
            return res.status(400).send()
        const file = await File.findByPk(req.params.id);
        if (!file) {
            return res.status(404).send();
        }

        const s3Response = await s3.getObject({
            Bucket: file.bucket_name,
            Key: file.s3_key
        }).promise();

        // res.setHeader('Content-Type', file.content_type);
        res.status(200).json({file_name: file.file_name,
            id: file.id,
            url: file.url,
            upload_date: file.upload_date});
    } catch (error) {
        console.error(error);
        res.status(404).send();
    }
};

exports.deleteFile = async (req, res) => {
    try {
        const file = await File.findByPk(req.params.id);
        if (!file) {
            return res.status(404).send();
        }

        await s3.deleteObject({
            Bucket: file.bucket_name,
            Key: file.s3_key
        }).promise();

        await file.destroy();
        res.status(204).send();
    } catch (error) {
        console.error(error);
        res.status(404).send();
    }
};