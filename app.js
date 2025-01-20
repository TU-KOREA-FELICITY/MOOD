const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

const PORT = 3001; // 포트를 3001로 변경

app.use(bodyParser.json({ limit: '50mb' }));
app.use(cors({ origin: '*' }));

app.post('/webcam_frame', (req, res) => {
  const { frame } = req.body;
  io.emit('webcam_stream', frame);
  res.sendStatus(200);
});

app.post('/warning', (req, res) => {
  console.log('Received warning:', req.body);
  io.emit('warning', req.body);
  res.sendStatus(200);
});

io.on('connection', (socket) => {
  console.log('클라이언트가 연결되었습니다.');

  socket.on('disconnect', () => {
    console.log('클라이언트 연결이 끊어졌습니다.');
  });
});

server.listen(PORT, () => {
  console.log(`서버가 ${PORT} 포트에서 실행 중입니다.`);
});