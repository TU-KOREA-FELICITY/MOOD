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
let emotionResult = null;

function runPythonScript(scriptName, args = []) {
  return new Promise((resolve, reject) => {
    const python = spawn('python', [scriptName, ...args]);
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
  try {
    await runPythonScript('aws-emotion.py');
    console.log('감정 분석 결과:\n', emotionResult);
    res.json({ result: emotionResult.result });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/emotion_result', (req, res) => {
    emotionResult = req.body;
    console.log('감정 분석 결과:\n', emotionResult);
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
