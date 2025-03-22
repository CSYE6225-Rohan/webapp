const { HealthCheck } = require('../model/model');
const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
const { File } = require('../model/model');
const { sequelize } = require('../config/db');
const logger = require('./logger');  // Import logger

const cloudwatch = new AWS.CloudWatch({ region: process.env.AWS_REGION });
const s3 = new AWS.S3({
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    region: process.env.AWS_REGION
});

// Utility function to send custom CloudWatch metrics
const sendCloudWatchMetric = async (name, value, unit = 'Count') => {
    try {
        const params = {
            MetricData: [{
                MetricName: name,
                Dimensions: [{ Name: 'API', Value: 'WebApp' }],
                Unit: unit,
                Value: value
            }],
            Namespace: 'CSYE6225/WebApp'
        };
        await cloudwatch.putMetricData(params).promise();
        logger.info(`Sent metric: ${name} - ${value} ${unit}`);
    } catch (error) {
        logger.error('Error sending CloudWatch metric', { stack: error.stack });
    }
};

// Utility function to measure execution time
const measureExecutionTime = async (name, fn) => {
    const start = Date.now();
    try {
        const result = await fn();
        const duration = Date.now() - start;
        await sendCloudWatchMetric(name, duration, 'Milliseconds');
        logger.info(`Execution time for ${name}: ${duration} ms`);
        return result;
    } catch (error) {
        logger.error(`Error measuring execution time for ${name}`, { stack: error.stack });
        throw error;
    }
};

// Helper function to get S3 bucket name
const getBucketName = async () => {
    try {
        const data = await measureExecutionTime('S3ListBucketsTime', () => s3.listBuckets().promise());

        if (data.Buckets.length === 1) {
            const bucketName = data.Buckets[0].Name;
            logger.info(`Bucket name retrieved: ${bucketName}`);
            return bucketName;
        } else {
            logger.warn(`Unexpected bucket count: ${data.Buckets.length}`);
        }
    } catch (error) {
        logger.error('Error retrieving S3 bucket name', { stack: error.stack });
    }
};

exports.getHealthStatus = async (req, res) => {
    logger.info(`GET /health - Checking API health status`);

    const start = Date.now();
    res.setHeader('Cache-Control', 'no-cache');

    try {
        await measureExecutionTime('DBConnectionTime', () => sequelize.authenticate());
        await measureExecutionTime('DBInsertTime', () =>
            HealthCheck.create({ datetime: new Date().toISOString() })
        );

        logger.info(`Health check successful`);
        res.status(200).send();
    } catch (error) {
        logger.error('Health check failed', { stack: error.stack });
        res.status(503).send();
    } finally {
        const duration = Date.now() - start;
        await sendCloudWatchMetric('GetHealthStatusAPITime', duration, 'Milliseconds');
        await sendCloudWatchMetric('GetHealthStatusAPICount', 1);
    }
};

exports.uploadFile = async (req, res) => {
    logger.info(`POST /upload - Uploading file`);

    if (!req.file) {
        logger.warn(`No file uploaded`);
        await sendCloudWatchMetric('UploadFileAPIErrorCount', 1);
        return res.status(400).send();
    }

    const fileKey = `uploads/${uuidv4()}-${req.file.originalname}`;
    const uploadDate = new Date().toISOString();
    const start = Date.now();

    try {
        const bucketName = await measureExecutionTime('S3GetBucketTime', getBucketName);

        if (!bucketName) {
            logger.error(`Failed to retrieve S3 bucket name`);
            await sendCloudWatchMetric('UploadFileAPIErrorCount', 1);
            return res.status(400).send();
        }

        const s3Response = await measureExecutionTime('S3UploadTime', () =>
            s3.upload({
                Bucket: bucketName,
                Key: fileKey,
                Body: req.file.buffer,
                ContentType: req.file.mimetype
            }).promise()
        );

        const url = `https://${bucketName}.s3.${process.env.AWS_REGION}.amazonaws.com/${fileKey}`;

        const file = await measureExecutionTime('DBInsertFileTime', () =>
            File.create({
                file_name: req.file.originalname,
                s3_key: fileKey,
                bucket_name: bucketName,
                content_type: req.file.mimetype,
                url: url,
                upload_date: uploadDate
            })
        );

        logger.info(`File uploaded successfully: ${file.id}`);
        res.status(201).json({
            file_name: req.file.originalname,
            id: file.id,
            url: url,
            upload_date: uploadDate
        });

    } catch (error) {
        logger.error('File upload failed', { stack: error.stack });
        await sendCloudWatchMetric('UploadFileAPIErrorCount', 1);
        res.status(400).send();
    } finally {
        const duration = Date.now() - start;
        await sendCloudWatchMetric('UploadFileAPITime', duration, 'Milliseconds');
        await sendCloudWatchMetric('UploadFileAPICount', 1);
    }
};

// ✅ API: Get File
exports.getFile = async (req, res) => {
    logger.info(`GET /file/${req.params.id} - Fetching file`);

    const start = Date.now();

    try {
        const file = await measureExecutionTime('DBFetchFileTime', () =>
            File.findByPk(req.params.id)
        );

        if (!file) {
            logger.warn(`File not found: ${req.params.id}`);
            await sendCloudWatchMetric('GetFileAPIErrorCount', 1);
            return res.status(404).send();
        }

        await measureExecutionTime('S3GetObjectTime', () =>
            s3.getObject({
                Bucket: file.bucket_name,
                Key: file.s3_key
            }).promise()
        );

        logger.info(`File retrieved successfully: ${file.id}`);
        res.status(200).json({
            file_name: file.file_name,
            id: file.id,
            url: file.url,
            upload_date: file.upload_date
        });

    } catch (error) {
        logger.error('Failed to retrieve file', { stack: error.stack });
        await sendCloudWatchMetric('GetFileAPIErrorCount', 1);
        res.status(404).send();
    } finally {
        const duration = Date.now() - start;
        await sendCloudWatchMetric('GetFileAPITime', duration, 'Milliseconds');
        await sendCloudWatchMetric('GetFileAPICount', 1);
    }
};

// ✅ API: Delete File
exports.deleteFile = async (req, res) => {
    logger.info(`DELETE /file/${req.params.id} - Deleting file`);

    const start = Date.now();

    try {
        const file = await measureExecutionTime('DBFetchFileTime', () =>
            File.findByPk(req.params.id)
        );

        if (!file) {
            logger.warn(`File not found: ${req.params.id}`);
            await sendCloudWatchMetric('DeleteFileAPIErrorCount', 1);
            return res.status(404).send();
        }

        await measureExecutionTime('S3DeleteObjectTime', () =>
            s3.deleteObject({
                Bucket: file.bucket_name,
                Key: file.s3_key
            }).promise()
        );

        await measureExecutionTime('DBDeleteFileTime', () => file.destroy());

        logger.info(`File deleted successfully: ${file.id}`);
        res.status(204).send();

    } catch (error) {
        logger.error('Failed to delete file', { stack: error.stack });
        await sendCloudWatchMetric('DeleteFileAPIErrorCount', 1);
        res.status(404).send();
    } finally {
        const duration = Date.now() - start;
        await sendCloudWatchMetric('DeleteFileAPITime', duration, 'Milliseconds');
        await sendCloudWatchMetric('DeleteFileAPICount', 1);
    }
};
