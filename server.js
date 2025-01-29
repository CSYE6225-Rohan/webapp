const app = require('./app')
const PORT = 8080;

// Start server
app.listen(PORT, 
  console.log(`Server is running on http://localhost:${PORT}`)
);