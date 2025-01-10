const express = require('express');
const { spawn } = require('child_process');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(bodyParser.json());
app.use(cors({origin: '*'}));

let authResult = null;
let registrationResult = null;

app.post('/register', (req, res) => {
  const { username } = req.body;
  if (!username) {
    return res.status(400).json({ error: "사용자 이름이 필요합니다." });
  }

  const python = spawn('python', ['aws-face-reg.py', username]);

  python.stdout.on('data', (data) => {
    console.log('Python 스크립트 출력:', data.toString());
  });

  python.stderr.on('data', (data) => {
    console.error('Python 스크립트 오류:', data.toString());
  });

  python.on('close', (code) => {
    console.log(`Python 스크립트 종료 코드: ${code}`);
    res.json({ message: "얼굴 등록 프로세스 완료" });
  });
});

app.post('/login', (req, res) => {
  authResult = null;
  const python = spawn('python', ['aws-face-auth.py']);

  python.stdout.on('data', (data) => {
    console.log('Python 스크립트 출력:', data.toString());
  });

  python.stderr.on('data', (data) => {
    console.error('Python 스크립트 오류:', data.toString());
  });

  python.on('close', (code) => {
    console.log(`Python 스크립트 종료 코드: ${code}`);
  });

  res.json({ message: "얼굴 인증 프로세스 시작됨" });
});

app.post('/registration_result', (req, res) => {
  registrationResult = req.body;
  console.log('얼굴 등록 결과:', registrationResult);
  res.sendStatus(200);
});

app.post('/auth_result', (req, res) => {
  authResult = req.body;
  console.log('얼굴 인증 결과:', authResult);
  res.sendStatus(200);
});

app.get('/check_registration', (req, res) => {
  res.json(registrationResult || { registered: false, user_id: null });
});

app.get('/check_auth', (req, res) => {
  res.json(authResult || { authenticated: false, user_id: null });
});

app.listen(port, () => {
  console.log(`서버 실행 중: http://127.0.0.1:${port}`);
});
