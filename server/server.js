require('dotenv').config(); // .env 파일에서 환경 변수 로드

const http = require('http');
const { Server } = require('socket.io');
const app = require('./app');

const server = http.createServer(app);
const io = new Server(server);
const PORT = process.env.PORT || 3000;

io.on('connection', (socket) => {
  console.log('클라이언트가 연결되었습니다.');

  socket.on('disconnect', () => {
    console.log('클라이언트 연결이 끊어졌습니다.');
    app.stopEstimator(); // 연결이 끊어지면 집중도 측정 금지
  });
});

// io 객체를 app에 설정하여 app.js에서도 사용할 수 있도록 함
app.set('io', io);

server.listen(PORT, () => {
  console.log(`서버가 ${PORT} 포트에서 실행 중입니다.`);
});