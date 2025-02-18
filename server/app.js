const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const { spawn } = require('child_process');
const path = require('path');
const pool = require('./database');

const app = express();
const SECRET_KEY = 'your_secret_key'; // JWT 비밀 키
const REFRESH_SECRET_KEY = 'your_refresh_secret_key'; // JWT 리프레시 비밀 키

app.use(bodyParser.json({ limit: '50mb' }));
app.use(cors({ origin: '*' }));

let webcamProcess;
let estimatorProcess;

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

function startEstimator(token) {
  if (!estimatorProcess) {
    const scriptPath = path.join(__dirname, '..', 'CAM', 'estimator.py');
    estimatorProcess = spawn('python', [scriptPath, token]);
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

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (token == null) {
    console.log('인증 실패: 토큰이 없음');
    console.log('요청 헤더:', req.headers);
    return res.status(401).send('인증 실패: 토큰이 없음');
  }

  jwt.verify(token, SECRET_KEY, (err, user) => {
    if (err) {
      console.log('인증 실패: 잘못된 토큰', err);
      return res.status(403).send('인증 실패: 잘못된 토큰');
    }
    req.user = user;
    next();
  });
}

function authenticateRefreshToken(req, res, next) {
  const refreshToken = req.headers['x-refresh-token'];
  if (refreshToken == null) return res.status(401).send('리프레시 토큰이 없음');

  jwt.verify(refreshToken, REFRESH_SECRET_KEY, (err, user) => {
    if (err) return res.status(403).send('잘못된 리프레시 토큰');
    req.user = user;
    next();
  });
}

app.startEstimator = startEstimator;

app.post('/start_estimator', authenticateToken, (req, res) => {
  try {
    startEstimator(req.body.token);
    res.status(200).json({ message: 'estimator.py started' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to start estimator.py', error: error.message });
  }
});

app.post('/register', async (req, res) => {
  const { username } = req.body;
  if (!username) {
    return res.status(400).json({ error: "사용자 이름이 필요합니다." });
  }
  try {
    startWebcam();
    setTimeout(async () => {
      try {
        stopWebcam();
        const result = await runPythonScript('aws-face-reg.py', [username]);
        console.log('얼굴 등록 결과:\n', result);
        res.json({ message: "얼굴 등록 프로세스 완료", result });
      } catch (error) {
        console.error('aws-face-reg.py 실행 중 오류:', error);
        res.status(500).json({ error: error.message });
      }
    }, 5000);
  } catch (error) {
    res.status(500).json({ error: error.message });
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
      const token = jwt.sign({ user_id: dbResult.insertId }, SECRET_KEY, { expiresIn: '1h' });
      const refreshToken = jwt.sign({ user_id: dbResult.insertId }, REFRESH_SECRET_KEY, { expiresIn: '7d' });
      
      // 회원 가입 완료 시 estimator.py 실행
      startEstimator(token);

      res.json({ message: "사용자 정보 저장 완료", token, refreshToken });
      console.log('JWT 생성:', token);
    } else {
      res.status(500).json({ error: "데이터베이스에 사용자 정보를 저장할 수 없습니다." });
    }
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      res.status(400).json({ error: '중복된 user_aws_id입니다.' });
    } else {
      console.error('사용자 정보 저장 중 오류:', error);
      res.status(500).json({ error: error.message });
    }
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
      const token = jwt.sign({ user_id: user.user_id }, SECRET_KEY, { expiresIn: '1h' });
      const refreshToken = jwt.sign({ user_id: user.user_id }, REFRESH_SECRET_KEY, { expiresIn: '7d' });
      
      // 로그인 성공 시 estimator.py 실행
      startEstimator(token);
      
      res.json({
        success: true,
        user: {
          user_id: user.user_id,
          user_aws_id: user.user_aws_id,
          user_name: user.user_name,
          car_type: user.car_type,
          fav_genre: user.fav_genre,
          fav_artist: user.fav_artist
        },
        token: token, // 토큰을 클라이언트에 반환
        refreshToken: refreshToken
      });
    } else {
      res.status(401).json({ success: false, message: '사용자를 찾을 수 없습니다.' });
    }
  } catch (error) {
    console.error('로그인 완료 중 오류:', error);
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

app.post('/analyze_emotion', authenticateToken, async (req, res) => {
  await stopEstimator();
  try {
    const result = await runPythonScript('aws-emotion.py');
    console.log('감정 분석 결과:\n', result);
    res.json({ result });
  } catch (error) {
    console.error('Emotion analysis script error:', error.message);
    res.status(500).json({ error: error.message });
  }
  startEstimator();
});

app.post('/emotion_result', authenticateToken, (req, res) => {
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

app.post('/warning', authenticateToken, async (req, res) => {
  console.log('Received warning:', req.body);
  const io = req.app.get('io'); // server.js에서 설정한 io 객체를 가져옴
  io.emit('warning', req.body);

  const { level, axis, timestamp } = req.body; // error 제거
  const user_id = req.user.user_id;

  if (user_id) {
    try {
      const [result] = await pool.query(
        'INSERT INTO focus (user_id, focus_level, axis, created_at) VALUES (?, ?, ?, ?)', // error 제거
        [user_id, level, axis, timestamp]
      );
      if (result.affectedRows === 1) {
        res.json({ message: 'Focus saved to database' });
      } else {
        res.status(500).json({ error: 'Failed to save focus to database' });
      }
    } catch (error) {
      console.error('Error saving focus to database:', error);
      res.status(500).json({ error: error.message });
    }
  } else {
    res.status(400).json({ error: 'User ID is missing' });
  }
});

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

app.post('/refresh_token', authenticateRefreshToken, (req, res) => {
  const { user_id } = req.user;
  const token = jwt.sign({ user_id }, SECRET_KEY, { expiresIn: '1h' });
  res.json({ token });
});

module.exports = app;