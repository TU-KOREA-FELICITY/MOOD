const express = require('express');
const { spawn } = require('child_process');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(bodyParser.json());
app.use(cors({origin: '*'}));

let authResult = null;

app.post('/start_auth', (req, res) => {
    authResult = null;
    const python = spawn('python', ['face_auth.py']);

    python.stdout.on('data', (data) => {
        console.log('Python script output:', data.toString());
    });

    python.on('close', (code) => {
        console.log(`Python script exited with code ${code}`);
    });

    res.json({ message: "Authentication process started" });
});

app.post('/auth_result', (req, res) => {
    authResult = req.body;
    console.log('Received authentication result:', authResult);
    res.sendStatus(200);
});

app.get('/check_auth', (req, res) => {
    res.json(authResult || { authenticated: false, user_id: null });
});

app.listen(port, () => {
    console.log(`Server running at http://127.0.0.1:${port}`);
});

app.post('/test', (req, res) => {
  console.log('Received test request:', req.body);
  res.json({ message: 'Test request received successfully!' });
});
