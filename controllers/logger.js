const winston = require('winston');
require('winston-cloudwatch');

const cloudwatchConfig = {
    logGroupName: process.env.CLOUDWATCH_LOG_GROUP || 'CSYE6225-WebApp',
    logStreamName: `${process.env.NODE_ENV || 'development'}-stream`,
    awsRegion: process.env.AWS_REGION,
    jsonMessage: true
};

const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.Console(),
        // new winston.transports.Cloud Watch(cloudwatchConfig)
    ]
});

module.exports = logger;
