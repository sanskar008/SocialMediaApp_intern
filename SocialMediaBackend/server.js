require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const fileUpload = require('express-fileupload');
const otpRoutes = require('./routes/api/phoneNumber');
const userRoutes = require('./routes/api/users')
const feeds = require('./routes/api/feeds')
const stories = require('./routes/api/stories')
const mongo = require('./db/mongo');
const elastic = require('./db/elastic')
const reactions = require('./routes/api/reactions');
const comments = require('./routes/api/comments');
const chatRooms = require('./routes/api/chatRooms')
const calls = require('./routes/api/calls')
const liveStreams = require('./routes/api/liveStreams')
const notifications = require('./routes/api/notifications')
const block = require('./routes/api/block')
const ban = require('./routes/api/ban')
const recentSearches = require('./routes/api/recentSearches')
const { users: usersElastic} = require('./db/elastic')
const {users : usersMongo} = require('./db/mongo');




const http = require("http");
const SocketService = require("./services/socket/initializer");
const messageInteraction = require('./routes/api/messages');
// Enable CORS

const app = express();
app.use(cors());
app.use(bodyParser.urlencoded({ extended: true, limit: "50mb",parameterLimit: 1000000}));
app.use(bodyParser.json({ limit: "50mb" }));


app.use(fileUpload({
  createParentPath: true,
  useTempFiles: true,
}));

const server = http.createServer(app);
const socketService = new SocketService(server);



// Parse JSON request bodies

// Routes
app.use('/api' , ban);
app.use('/api' , calls );
app.use('/api' , feeds );
app.use('/api' , block );
app.use('/api' , stories );
app.use('/api' , comments );
app.use('/api' , reactions );
app.use('/api' , otpRoutes );
app.use('/api' , chatRooms );
app.use('/api' , reactions );
app.use('/api' , userRoutes );
app.use('/api' , liveStreams );
app.use('/api' , notifications);
app.use('/api' , recentSearches);
app.use('/api' , messageInteraction);




// Error-handling middleware
app.use((err, req, res, next) => {
    const status = err.status || 500;
    const message = err.message || 'Internal Server Error';
    console.error(`[Error] ${message}`);
    res.status(status).json({ error: message });
});


// Initialize MongoDB
const initializeMongo = async () => {
  try {
    await mongo.initialize();
    console.log('MongoDB initialized successfully');
  } catch (err) {
    console.error('Error initializing MongoDB:', err.message);
    process.exit(1);
  }
};

// Initialize Elasticsearch
const initializeElastic = async () => {
  try {
    await elastic.initialize();
    console.log('Elasticsearch initialized successfully');
  } catch (err) {
    console.error('Error initializing Elasticsearch:', err.message);
    process.exit(1);
  }
};

// Start Server
const startServer = async () => {
  await initializeMongo();
  await initializeElastic();
  server.listen(process.env.PORT, () => {
    console.log('Server is listening on', process.env.PORT);
  });
};

startServer();

