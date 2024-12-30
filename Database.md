-- Users 테이블 생성
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY, -- 회원 고유 ID
    username VARCHAR(50) NOT NULL,          -- 사용자 이름
    country VARCHAR(50),                    -- 국가 정보
    preferred_genres TEXT,                   -- 선호 장르 (JSON 형태)
    profile_image_url TEXT,                    -- 프로필 이미지 URL
    status_message VARCHAR(255)          -- 상태 메시지
);

-- EmotionTags 테이블 생성
CREATE TABLE EmotionTags (
    emotion_id INT AUTO_INCREMENT PRIMARY KEY, -- 감정 태그 고유 ID
    emotion_name VARCHAR(50) NOT NULL,         -- 감정 이름
    description TEXT,                           -- 감정 태그 설명
    icon_url TEXT,                               -- 감정을 시각적으로 표현할 아이콘 이미지 URL
    color_code VARCHAR(7)                              -- 감정을 나타내는 색상 코드(ex. #FF5733)
);

-- RecommendationLogs 테이블 생성
CREATE TABLE RecommendationLogs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,  -- 로그 고유 ID
    user_id INT,                            -- 사용자 ID
    track_id VARCHAR(100) NOT NULL,         -- Spotify 트랙 ID
    genre VARCHAR(50),                      -- 추천된 트랙의 장르
    played_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 곡이 재생된 시간
    is_liked BOOLEAN,                       -- 좋아요 여부
    FOREIGN KEY (user_id) REFERENCES Users(user_id), -- Users 테이블 참조
    detected_emotion_id INT,               -- 인식된 감정 태그 ID
    FOREIGN KEY (detected_emotion_id) REFERENCES EmotionTags(emotion_id)
);

-- GenrePreferences 테이블 생성
CREATE TABLE GenrePreferences (
    user_id INT,                            -- 사용자 ID
    genre VARCHAR(50) NOT NULL,             -- 장르 이름
    preference_score FLOAT NOT NULL,        -- 장르 선호 점수
    PRIMARY KEY (user_id, genre),           -- 복합 기본 키 설정
    FOREIGN KEY (user_id) REFERENCES Users(user_id), -- Users 테이블 참조
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP -- 점수 갱신 시간
);

-- UserActivityLogs 테이블 생성
CREATE TABLE UserActivityLogs (
    activity_id INT AUTO_INCREMENT PRIMARY KEY, -- 고유 ID
    user_id INT NOT NULL,                       -- 사용자 ID
    emotion_id INT,                             -- 감정 태그 ID
    activity_type VARCHAR(50) NOT NULL,         -- 행동 유형 (예: "play", "skip")
    track_id VARCHAR(100),                      -- 관련 트랙 ID
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 기록 시간
    warnings_received INT DEFAULT 0,                            -- 경고 횟수
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (emotion_id) REFERENCES EmotionTags(emotion_id)
);

-- EmotionTrackMapping 테이블 생성
CREATE TABLE EmotionTrackMapping (
    emotion_id INT NOT NULL,            -- 감정 태그 ID
    track_id VARCHAR(100) NOT NULL,    -- Spotify 트랙 ID
    relevance_score FLOAT NOT NULL,    -- 연관 점수 (0~1)
    PRIMARY KEY (emotion_id, track_id),
    FOREIGN KEY (emotion_id) REFERENCES EmotionTags(emotion_id)
);

-- RealTimeEmotionLogs 테이블 생성
CREATE TABLE RealTimeEmotionLogs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,   -- 고유 ID
    user_id INT NOT NULL,                    -- 사용자 ID
    emotion_id INT NOT NULL,                 -- 감정 태그 ID
    confidence FLOAT NOT NULL,               -- 감정 신뢰도
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 기록 시간
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (emotion_id) REFERENCES EmotionTags(emotion_id)
);

-- FocusWarningLogs 테이블 생성
CREATE TABLE FocusWarningLogs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    pitch FLOAT NOT NULL, -- 기록된 pitch 값
    roll FLOAT NOT NULL,  -- 기록된 roll 값
    warning_level VARCHAR(50), -- 경고 수준 (예: "low", "high")
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
