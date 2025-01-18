const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { exec } = require('child_process');
const { Server } = require('ws'); // WebSocket 서버를 추가합니다.

const app = express();
const PORT = 3001; // 포트를 3001로 변경

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// WebSocket 서버 설정
const wss = new Server({ port: 3002 }); // WebSocket 서버 포트를 3002로 설정합니다.

wss.on('connection', ws => {
  console.log('WebSocket client connected');
  ws.on('message', message => {
    console.log('Received message from client:', message);
  });
  ws.on('close', () => {
    console.log('WebSocket client disconnected');
  });
});

// 기존의 로그인 관련 코드
app.post('/login', (req, res) => {
  // 로그인 로직
  res.status(200).send({ success: true });
});

// 집중도 인식을 위한 엔드포인트 추가
app.post('/detect-concentration', (req, res) => {
  exec('python3 estimator.py', (error, stdout, stderr) => {
    if (error) {
      console.error(`exec error: ${error}`);
      return res.status(500).send({ error: 'Failed to execute estimator.py' });
    }
    console.log(`stdout: ${stdout}`);
    console.error(`stderr: ${stderr}`);

    // estimator.py의 출력 결과를 클라이언트로 전송
    res.status(200).send({ result: stdout });
  });
});

// 경고 메시지를 수신하기 위한 엔드포인트 추가
app.post('/warning', (req, res) => {
  console.log('Received warning:', req.body);

  // WebSocket을 통해 Flutter 앱으로 경고 메시지를 전송
  wss.clients.forEach(client => {
    if (client.readyState === client.OPEN) {
      client.send(JSON.stringify(req.body));
    }
  });

  res.status(200).send({ success: true });
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});