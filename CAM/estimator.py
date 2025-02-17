import math
import cv2
import mediapipe as mp
import numpy as np
import requests
import base64
import time
import absl.logging
from datetime import datetime

# 로그 초기화
absl.logging.set_verbosity(absl.logging.INFO)

# Node.js 서버 URL
server_url = 'http://localhost:3000/webcam_frame'
warning_url = 'http://localhost:3000/warning'

# Mediapipe 초기화
mp_face_mesh = mp.solutions.face_mesh.FaceMesh(max_num_faces=1)
mp_drawing = mp.solutions.drawing_utils

# 경고 카운터 및 안전 상태 전송 플래그 추가
warning_counters = {
    "pitch": 0,
    "roll": 0,
    "left_eye_y": 0,
    "right_eye_y": 0
}
safe_counters = {
    "pitch": 0,
    "roll": 0,
    "left_eye_y": 0,
    "right_eye_y": 0
}
safe_sent = {
    "pitch": True,
    "roll": True,
    "left_eye_y": True,
    "right_eye_y": True
}
warning_sent = {
    "pitch": {"경고": False, "주의": False, "위험": False},
    "roll": {"경고": False, "주의": False, "위험": False},
    "left_eye_y": {"경고": False, "주의": False, "위험": False},
    "right_eye_y": {"경고": False, "주의": False, "위험": False}
}

def send_warning(level, axis, error):
    current_time = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    data = {'level': level, 'axis': axis, 'error': error, 'timestamp': current_time}
    try:
        response = requests.post(warning_url, json=data)
        print("Response from server:", response.text)
    except requests.exceptions.RequestException as e:
        print(f"Failed to send warning: {e}")

def process_warning(axis, error, levels, current_time):
    global warning_counters, safe_sent, warning_sent
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
    elif error > levels[2]:
        if status[axis]["start_time"] is None:
            status[axis]["start_time"] = current_time
        elif current_time - status[axis]["start_time"] >= 3:
            level = "위험"
    else:
        status[axis]["start_time"] = None
        warning_counters[axis] = 0  # 오류가 해소되면 경고 카운터 초기화
        level = "안전"  # 모든 오류가 기준 이하로 해소되면 안전 상태

    if level:
        if level == "안전":
            if safe_sent[axis] == True:
                safe_counters[axis] += 1
                if safe_counters[axis] >= 10:
                    send_warning(level, axis, 0)  # error 값을 0으로 설정하여 전송
                    safe_counters[axis] = 0  # 카운터 초기화
                    safe_sent[axis] = False
        elif not warning_sent[axis][level]:
            warning_counters[axis] += 1
            if warning_counters[axis] >= 10:  # 경고가 10번 감지되면 서버에 전송
                send_warning(level, axis, error)
                warning_counters[axis] = 0  # 서버에 전송 후 경고 카운터 초기화
                safe_sent[axis] = True
                warning_sent[axis] = {k: (k == level) for k in warning_sent[axis]}  # 해당 레벨만 True로 설정

def calculate_eye_center_and_radius(eye_landmarks, image_width, image_height):
    x_list = [int(landmark.x * image_width) for landmark in eye_landmarks]
    y_list = [int(landmark.y * image_height) for landmark in eye_landmarks]
    eye_center = (int(np.mean(x_list)), int(np.mean(y_list)))
    radius = int(max(np.max(x_list) - np.min(x_list), np.max(y_list) - np.min(y_list)) / 4)
    return eye_center, radius

def rotation_matrix_to_angles(rotation_matrix):
    x = math.atan2(rotation_matrix[2, 1], rotation_matrix[2, 2])
    z = math.atan2(rotation_matrix[1, 0], rotation_matrix[0, 0])
    return np.array([x, z]) * 180. / math.pi

# 초기값 설정
initial_pitch, initial_roll = None, None
initial_left_eye_center, initial_right_eye_center = None, None
status = {"pitch": {"start_time": None}, "roll": {"start_time": None}, "left_eye_y": {"start_time": None}, "right_eye_y": {"start_time": None}}
printed_initial_values = False

# 웹캠 캡처 객체 생성
cap = cv2.VideoCapture(0)
frame_interval = 0.1  # 프레임 전송 간격 (초)
last_frame_time = 0

while True:
    ret, frame = cap.read()
    if not ret:
        break

    current_time = time.time()
    if current_time - last_frame_time < frame_interval:
        continue
    last_frame_time = current_time

    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = mp_face_mesh.process(frame_rgb)
    frame_rgb = cv2.cvtColor(frame_rgb, cv2.COLOR_RGB2BGR)

    h, w, _ = frame.shape
    face_coordination_in_real_world = np.array([
        [285, 528, 200], [285, 371, 152], [197, 574, 128],
        [173, 425, 108], [360, 574, 128], [391, 425, 108]
    ], dtype=np.float64)
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

            print(f"Initial Face Coordination in Image: {face_coordination_in_image.tolist()}")

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

    frame_rgb = cv2.resize(frame_rgb, (320, 240))
    ret, buffer = cv2.imencode('.jpg', frame_rgb, [int(cv2.IMWRITE_JPEG_QUALITY), 70])
    frame_jpg = buffer.tobytes()
    encoded_frame = base64.b64encode(frame_jpg).decode('utf-8')

    response = requests.post(server_url, json={'frame': encoded_frame})

    cv2.imshow('Webcam', frame_rgb)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()