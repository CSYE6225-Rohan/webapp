const Check = require('../model/model'); // Import your model

exports.getHealthStatus = async (req, res) => {
    res.setHeader('Cache-Control', 'no-cache');
    const { sequelize, authenticate } = require('../config/db')
    
    //Checking database connection
    if (authenticate){
        console.log('Connection is intact.');

        try {
            //Now adding check log to table
            await Check.create({datetime:new Date().toISOString() });
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