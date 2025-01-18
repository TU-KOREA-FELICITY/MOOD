import math
import cv2
import mediapipe as mp
import numpy as np
import time
import pygame
import requests  # requests 모듈을 import합니다.
from flask import Flask, Response
from flask_socketio import SocketIO, emit
import base64
import threading
import logging

# 로그 설정
logging.basicConfig(level=logging.DEBUG)

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet')

mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(min_detection_confidence=0.5, min_tracking_confidence=0.5)
cap = cv2.VideoCapture(0)

def rotation_matrix_to_angles(rotation_matrix):
    x = math.atan2(rotation_matrix[2, 1], rotation_matrix[2, 2])
    z = math.atan2(rotation_matrix[1, 0], rotation_matrix[0, 0])
    return np.array([x, z]) * 180. / math.pi

def play_sound(file_path):
    pygame.mixer.init()
    pygame.mixer.music.load(file_path)
    pygame.mixer.music.play()

# Initialize variables
initial_pitch, initial_roll = None, None
initial_left_eye_center, initial_right_eye_center = None, None
printed_initial_values = False
status = {"pitch": {"start_time": None}, "roll": {"start_time": None}, "left_eye_y": {"start_time": None}, "right_eye_y": {"start_time": None}}
last_left_eye_y, last_right_eye_y = None, None

def send_warning(level, axis, error):
    url = 'http://localhost:3001/warning'  # app.js의 서버 주소와 포트
    data = {'level': level, 'axis': axis, 'error': error}
    try:
        response = requests.post(url, json=data)
        print(response.text)
    except requests.exceptions.RequestException as e:
        print(f"Failed to send warning: {e}")

def process_warning(axis, error, levels, current_time):
    level = None
    if levels[0] < error <= levels[1]:
        if status[axis]["start_time"] is None:
            status[axis]["start_time"] = current_time
        elif current_time - status[axis]["start_time"] >= 3:
            level = "경고"
    elif levels[1] < error <= levels[2]:
        if status[axis]["start_time"] is None:
            status[axis]["start_time"] = current_time
        elif current_time - status[axis]["start_time"] >= 3:
            level = "주의"
            play_sound('alert_50.mp3')
    elif error > levels[2]:
        if status[axis]["start_time"] is None:
            status[axis]["start_time"] = current_time
        elif current_time - status[axis]["start_time"] >= 3:
            level = "위험"
            play_sound('alert_100.mp3')
    else:
        status[axis]["start_time"] = None

    if level:
        print(f"[{level}] {axis.capitalize()} 오류 {levels[0]}~{levels[1]}범위 초과")
        send_warning(level, axis, error)

def calculate_eye_center_and_radius(eye_landmarks, image_width, image_height):
    x_list = [int(landmark.x * image_width) for landmark in eye_landmarks]
    y_list = [int(landmark.y * image_height) for landmark in eye_landmarks]
    eye_center = (int(np.mean(x_list)), int(np.mean(y_list)))
    radius = int(max(np.max(x_list) - np.min(x_list), np.max(y_list) - np.min(y_list)) / 4)
    return eye_center, radius

@app.route('/video_feed')
def video_feed():
    logging.debug('video_feed route accessed')
    return Response(gen_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')

@socketio.on('connect')
def handle_connect():
    logging.debug('Client connected')

@socketio.on('disconnect')
def handle_disconnect():
    logging.debug('Client disconnected')

def gen_frames():
    global initial_pitch, initial_roll, initial_left_eye_center, initial_right_eye_center, printed_initial_values
    while cap.isOpened():
        success, frame = cap.read()
        if not success:
            logging.error('Failed to read frame from camera')
            break
        else:
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = face_mesh.process(frame_rgb)
            frame_rgb = cv2.cvtColor(frame_rgb, cv2.COLOR_RGB2BGR)

            face_coordination_in_real_world = np.array([
                [285, 528, 200], [285, 371, 152], [197, 574, 128],
                [173, 425, 108], [360, 574, 128], [391, 425, 108]
            ], dtype=np.float64)

            h, w, _ = frame.shape
            face_coordination_in_image = []

            if results.multi_face_landmarks:
                for face_landmarks in results.multi_face_landmarks:
                    for idx, lm in enumerate(face_landmarks.landmark):
                        if idx in [1, 9, 57, 130, 287, 359]:
                            x, y = int(lm.x * w), int(lm.y * h)
                            face_coordination_in_image.append([x, y])

                    face_coordination_in_image = np.array(face_coordination_in_image, dtype=np.float64)
                    focal_length = 1 * w
                    cam_matrix = np.array([[focal_length, 0, w / 2], [0, focal_length, h / 2], [0, 0, 1]])
                    dist_matrix = np.zeros((4, 1), dtype=np.float64)
                    success, rotation_vec, transition_vec = cv2.solvePnP(
                        face_coordination_in_real_world, face_coordination_in_image, cam_matrix, dist_matrix)
                    rotation_matrix, jacobian = cv2.Rodrigues(rotation_vec)
                    angles = rotation_matrix_to_angles(rotation_matrix)
                    pitch, roll = angles

                    left_eye_landmarks = [face_landmarks.landmark[i] for i in [33, 133, 160, 158, 144, 153, 154, 155, 133, 173]]
                    left_eye_center, left_eye_radius = calculate_eye_center_and_radius(left_eye_landmarks, w, h)
                    cv2.circle(frame_rgb, left_eye_center, left_eye_radius, (0, 255, 0), 2)
                    cv2.putText(frame_rgb, f'{left_eye_center}', (left_eye_center[0] - 50, left_eye_center[1] - 10),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

                    right_eye_landmarks = [face_landmarks.landmark[i] for i in [362, 263, 387, 385, 373, 380, 374, 386, 263, 467]]
                    right_eye_center, right_eye_radius = calculate_eye_center_and_radius(right_eye_landmarks, w, h)
                    cv2.circle(frame_rgb, right_eye_center, right_eye_radius, (0, 255, 0), 2)
                    cv2.putText(frame_rgb, f'{right_eye_center}', (right_eye_center[0] - 50, right_eye_center[1] - 10),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

                    if initial_pitch is None or initial_roll is None or initial_left_eye_center is None or initial_right_eye_center is None:
                        initial_pitch, initial_roll = pitch, roll
                        initial_left_eye_center, initial_right_eye_center = left_eye_center, right_eye_center
                        if not printed_initial_values:
                            print(f"Initial Pitch: {initial_pitch:.2f}, Initial Roll: {initial_roll:.2f}")
                            print(f"Initial Left Eye Center: {initial_left_eye_center}, Initial Right Eye Center: {initial_right_eye_center}")
                            printed_initial_values = True

                    current_time = time.time()
                    pitch_error = abs(pitch - initial_pitch)
                    roll_error = abs(roll - initial_roll)

                    left_eye_y_error = abs(left_eye_center[1] - initial_left_eye_center[1])
                    right_eye_y_error = abs(right_eye_center[1] - initial_right_eye_center[1])

                    process_warning("pitch", pitch_error, [15, 25, 50], current_time)
                    process_warning("roll", roll_error, [15, 30, 45], current_time)

                    process_warning("left_eye_y", left_eye_y_error, [30, 60, 90], current_time)
                    process_warning("right_eye_y", right_eye_y_error, [30, 60, 90], current_time)

                    for i, info in enumerate(zip(('pitch', 'roll'), angles)):
                        k, v = info
                        text = f'{k}: {int(v)}'
                        cv2.putText(frame_rgb, text, (20, i * 30 + 20), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (200, 0, 200), 2)

                    # 집중도 인식 결과 전송
                    concentration_result = f"Pitch: {pitch_error:.2f}, Roll: {roll_error:.2f}"
                    socketio.emit('concentration', concentration_result)
            else:
                # 얼굴이 감지되지 않는 경우 초기값으로 설정
                pitch_error = 0
                roll_error = 0
                left_eye_y_error = 0
                right_eye_y_error = 0

            ret, buffer = cv2.imencode('.jpg', frame_rgb)
            frame_jpg = buffer.tobytes()
            encoded_frame = base64.b64encode(frame_jpg).decode('utf-8')
            socketio.emit('video_feed', encoded_frame)
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + frame_jpg + b'\r\n')

            # Display the frame with annotations
            cv2.imshow('Webcam', frame_rgb)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

def run_flask():
    logging.debug('Starting Flask server')
    socketio.run(app, port=5000)

if __name__ == '__main__':
    flask_thread = threading.Thread(target=run_flask)
    flask_thread.start()

    # Start the OpenCV frame generation
    for _ in gen_frames():
        pass

    flask_thread.join()

    # Release resources
    cap.release()
    cv2.destroyAllWindows()