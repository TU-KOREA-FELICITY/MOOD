const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const session = require('express-session');
const { spawn } = require('child_process');
const path = require('path');
const pool = require('./database');

const app = express();

app.use(bodyParser.json({ limit: '50mb' }));
app.use(cors({ origin: '*' }));

app.use(session({
  secret: 'your_secret_key',
  resave: false,
  saveUninitialized: true,
  cookie: { secure: false } // secure: true in production with HTTPS
}));

let authResult = null;
let registrationResult = null;
let emotionResult = null;
let estimatorProcess = null;
let webcamProcess = null;

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

function startWebcam() {
  const scriptPath = path.join(__dirname, '..', 'CAM', 'webcam.py');
  webcamProcess = spawn('python', [scriptPath]);
  webcamProcess.stdout.on('data', (data) => {
    console.log('webcam.py 실행');
  });
}

function stopWebcam() {
  if (webcamProcess) {
    webcamProcess.kill();
    console.log('webcam.py 종료');
  }
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
    startWebcam();
    // 5초 후 webcam.py 종료 및 aws-face-reg.py 실행
    setTimeout(async () => {
      try {
        stopWebcam();
        const result = await runPythonScript('aws-face-reg.py', [username]);
        console.log('얼굴 등록 결과:\n', result);
        res.json({ success: true, message: "얼굴 등록 프로세스 완료", result });
      } catch (error) {
        console.error('aws-face-reg.py 실행 중 오류:', error);
        res.status(500).json({ success: false, error: error.message });
      }
    }, 5000);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/register_complete', async (req, res) => {
  const { user_aws_id, username, car_type, fav_genre, fav_artist } = req.body;
  if (!user_aws_id || !username || !car_type) {
    return res.status(400).json({ error: "필수 입력 항목이 누락되었습니다." });
  }
  try {
    const [dbResult] = await pool.query(
      'INSERT INTO user (user_aws_id, user_name, car_type, fav_genre, fav_artist) VALUES (?, ?, ?, ?, ?)',
      [user_aws_id, username, car_type, fav_genre, fav_artist]
    );
    if (dbResult.affectedRows === 1) {
      res.json({ message: "사용자 정보 저장 완료" });
    } else {
      res.status(500).json({ error: "데이터베이스에 사용자 정보를 저장할 수 없습니다." });
    }
  } catch (error) {
    console.error('사용자 정보 저장 중 오류:', error);
    res.status(500).json({ error: error.message });
  }
});

app.post('/check_id_duplicate', async (req, res) => {
  const { user_aws_id } = req.body;

  try {
    const [dbResult] = await pool.query('SELECT user_aws_id FROM user WHERE user_aws_id = ?', [user_aws_id]);

    if (dbResult.length > 0) {
      res.json({
        success: false,
        message: 'ID가 이미 존재합니다.',
        isDuplicate: true,
        user_aws_id: user_aws_id
      });
    } else {
      res.json({
        success: true,
        message: '사용 가능한 ID입니다.',
        isDuplicate: false,
        user_aws_id: user_aws_id
      });
    }
  } catch (error) {
    console.error('ID 중복 확인 중 오류:', error);
    res.status(500).json({ success: false, message: '서버 오류가 발생했습니다.' });
  }
});

app.post('/login', async (req, res) => {
  try {
    startWebcam();
    const authResult = await new Promise((resolve, reject) => {
      setTimeout(async () => {
        try {
          stopWebcam();
          const result = await runPythonScript('aws-face-auth.py');
          console.log('얼굴 인증 결과:\n', result);
          resolve(result);
        } catch (error) {
          reject(error);
        }
      }, 5000);
    });
    res.json({ message: "얼굴 인증 프로세스 완료", result: authResult });
  } catch (error) {
    console.error('로그인 중 오류:', error);
    res.status(500).json({ error: error.message });
  }
});

app.post('/login_complete', async (req, res) => {
  const { user_aws_id } = req.body;

  try {
    const [dbResult] = await pool.query('SELECT * FROM user WHERE user_aws_id = ?', [user_aws_id]);

    if (dbResult.length > 0) {
      const user = dbResult[0];
      req.session.user = user;
      res.json({
        success: true,
        user: {
          user_id: user.user_id,
          user_aws_id: user.user_aws_id,
          user_name: user.user_name,
          car_type: user.car_type,
          fav_genre: user.fav_genre,
          fav_artist: user.fav_artist
        }
      });
    } else {
      res.status(401).json({ success: false, message: '사용자를 찾을 수 없습니다.' });
    }
  } catch (error) {
    console.error('로그인 완료 중 오류:', error);
    res.status(500).json({ success: false, message: '서버 오류가 발생했습니다.' });
  }
});

app.post('/user_info_update', async (req, res) => {
  const { user_aws_id, username, car_type } = req.body;

  try {
    const updateFields = [];
    const values = [];

    if (username !== undefined) {
      updateFields.push('user_name = ?');
      values.push(username);
    }

    if (car_type !== undefined) {
      updateFields.push('car_type = ?');
      values.push(car_type);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        message: '업데이트할 정보가 제공되지 않았습니다.'
      });
    }

    const query = `UPDATE user SET ${updateFields.join(', ')} WHERE user_aws_id = ?`;
    values.push(user_aws_id);

    const [dbResult] = await pool.query(query, values);

    if (dbResult.affectedRows > 0) {
      res.json({
        success: true,
        message: '사용자 정보가 성공적으로 업데이트되었습니다.',
        updatedUser: { user_aws_id, username, car_type }
      });
    } else {
      res.status(404).json({
        success: false,
        message: '해당 얼굴 id를 가진 사용자를 찾을 수 없습니다.',
        user_aws_id: user_aws_id
      });
    }
  } catch (error) {
    console.error('사용자 정보 업데이트 중 오류:', error);
    res.status(500).json({ success: false, message: '서버 오류가 발생했습니다.' });
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