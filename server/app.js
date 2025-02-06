const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { spawn } = require('child_process');
const path = require('path');

const app = express();

app.use(bodyParser.json({ limit: '50mb' }));
app.use(cors({ origin: '*' }));

let authResult = null;
let registrationResult = null;
let emotionResult = null;
let estimatorProcess = null;

function runPythonScript(scriptName, args = []) {
  return new Promise((resolve, reject) => {
    const scriptPath = path.join(__dirname, '..', 'CAM', scriptName);
    const python = spawn('python', [scriptPath, ...args]);
    let result = '';

    python.stdout.on('data', (data) => {
      result += data.toString('utf8');
    });

    python.stderr.on('data', (data) => {
      console.error('Python 스크립트 오류:', data.toString());
    });

    python.on('close', (code) => {
      console.log(`Python 스크립트 종료 코드: ${code}`);
      if (code === 0) {
        resolve(result);
      } else {
        reject(new Error(`Python 스크립트 실행 실패: ${code}`));
      }
    });
  });
}

function startEstimator() {
  if (!estimatorProcess) {
    const scriptPath = path.join(__dirname, '..', 'CAM', 'estimator.py');
    estimatorProcess = spawn('python', [scriptPath]);
    estimatorProcess.stdout.on('data', (data) => {
      console.log(`estimator.py: ${data}`);
    });
    estimatorProcess.stderr.on('data', (data) => {
      console.error(`estimator.py 오류: ${data}`);
    });
    estimatorProcess.on('close', (code) => {
      console.log(`estimator.py 종료 코드: ${code}`);
      estimatorProcess = null;
    });
  }
}

function stopEstimator() {
  return new Promise((resolve, reject) => {
    if (estimatorProcess) {
      estimatorProcess.on('close', () => {
        estimatorProcess = null;
        resolve();
      });
      estimatorProcess.kill();
    } else {
      resolve();
    }
  });
}

app.startEstimator = startEstimator;

app.post('/start_estimator', (req, res) => {
  startEstimator();
  res.json({ message: 'estimator.py started' });
});

app.post('/register', async (req, res) => {
  const { username } = req.body;
  if (!username) {
    return res.status(400).json({ error: "사용자 이름이 필요합니다." });
  }

  try {
    const result = await runPythonScript('aws-face-reg.py', [username]);
    console.log('얼굴 등록 결과:\n', result);
    res.json({ message: "얼굴 등록 프로세스 완료", result });
  } catch (error) {
    console.error('AWS face registration script error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

app.post('/login', async (req, res) => {
  authResult = null;
  try {
    const result = await runPythonScript('aws-face-auth.py');
    console.log('얼굴 인증 결과:\n', result);
    res.json({ message: "얼굴 인증 프로세스 완료", result });
  } catch (error) {
    console.error('AWS face authentication script error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

app.post('/registration_result', (req, res) => {
  registrationResult = req.body;
  console.log('얼굴 등록 결과:\n', registrationResult);
  res.sendStatus(200);
});

app.post('/auth_result', (req, res) => {
  authResult = req.body;
  console.log('얼굴 인증 결과:\n', authResult);
  res.sendStatus(200);
});

app.post('/analyze_emotion', async (req, res) => {
  await stopEstimator();
  try {
    await runPythonScript('aws-emotion.py');
    console.log('감정 분석 결과:\n', emotionResult.result);
    res.json({ result: emotionResult.result });
  } catch (error) {
    console.error('Emotion analysis script error:', error.message);
    res.status(500).json({ error: error.message });
  }
  startEstimator();
});

app.post('/emotion_result', (req, res) => {
  emotionResult = req.body;
  console.log('Received /emotion_result with body:', req.body);
  if (!req.body) {
    res.status(400).send('Invalid request: "result" field is missing');
    return;
  }
  console.log('감정 분석 결과:\n', emotionResult);
  res.sendStatus(200);
});

app.get('/check_registration', (req, res) => {
  res.json(registrationResult || { registered: false, user_id: null });
});

app.get('/check_auth', (req, res) => {
  res.json(authResult || { authenticated: false, user_id: null });
});

app.post('/webcam_frame', (req, res) => {
  const { frame } = req.body;
  const io = req.app.get('io'); // server.js에서 설정한 io 객체를 가져옴
  io.emit('webcam_stream', frame);
  res.sendStatus(200);
});

app.post('/warning', (req, res) => {
  console.log('Received warning:', req.body);
  const io = req.app.get('io'); // server.js에서 설정한 io 객체를 가져옴
  io.emit('warning', req.body);
  res.sendStatus(200);
});

// 새로운 엔드포인트 추가
app.post('/run_aws_face_reg', async (req, res) => {
  try {
    const result = await runPythonScript('aws-face-reg.py');
    console.log('얼굴 등록 결과:\n', result);
    res.json({ result });
  } catch (error) {
    console.error('AWS face registration script error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

module.exports = app;