const pool = require('../database');

const createTables = async () => {
  const userTable = `
    CREATE TABLE IF NOT EXISTS user (
      user_id INT AUTO_INCREMENT PRIMARY KEY,
      user_aws_id VARCHAR(50) UNIQUE NOT NULL,
      user_name VARCHAR(100) NOT NULL,
      car_type VARCHAR(100) NOT NULL,
      fav_genre VARCHAR(100),
      fav_artist VARCHAR(100)
    );
  `;

  const focusTable = `
    CREATE TABLE IF NOT EXISTS focus (
      focus_id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      focus_level INT NOT NULL,
      started_at TIMESTAMP NOT NULL,
      ended_at TIMESTAMP NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
    );
  `;

  const genreTable = `
    CREATE TABLE IF NOT EXISTS genre (
      genre_id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      genre VARCHAR(50) NOT NULL,
      score INT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
    );
  `;

  const emotionTable = `
    CREATE TABLE IF NOT EXISTS emotion (
      emotion_id INT AUTO_INCREMENT PRIMARY KEY,
      emotion_name VARCHAR(50) NOT NULL,
      tag VARCHAR(100) NOT NULL
    );
  `;

  const trackTable = `
    CREATE TABLE IF NOT EXISTS track (
      track_id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      track_uri VARCHAR(255) NOT NULL,
      genre_id INT NOT NULL,
      score INT NOT NULL,
      played_at TIMESTAMP NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
      FOREIGN KEY (genre_id) REFERENCES genre(genre_id) ON DELETE CASCADE
    );
  `;

  try {
    const connection = await pool.getConnection();
    await connection.query(userTable);
    await connection.query(focusTable);
    await connection.query(genreTable);
    await connection.query(emotionTable);
    await connection.query(trackTable);
    connection.release();
    console.log('All tables created successfully.');
  } catch (err) {
    console.error('Error creating tables:', err);
  }
};

createTables();

//ALTER TABLE focus ADD COLUMN axis VARCHAR(255);