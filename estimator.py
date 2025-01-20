import math
import cv2
import mediapipe as mp
import numpy as np
import time
import requests
import base64

# Node.js 서버 URL
server_url = 'http://localhost:3001/webcam_frame'
warning_url = 'http://localhost:3001/warning'

# Mediapipe 초기화
mp_face_mesh = mp.solutions.face_mesh.FaceMesh(max_num_faces=1)
mp_drawing = mp.solutions.drawing_utils

def send_warning(level, axis, error):
    data = {'level': level, 'axis': axis, 'error': error}
    try:
        response = requests.post(warning_url, json=data)
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
    elif error > levels[2]:
        if status[axis]["start_time"] is None:
            status[axis]["start_time"] = current_time
        elif current_time - status[axis]["start_time"] >= 3:
            level = "위험"
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

while True:
    ret, frame = cap.read()
    if not ret:
        print("Cannot read frame.")
        break

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

    ret, buffer = cv2.imencode('.jpg', frame_rgb)
    frame_jpg = buffer.tobytes()
    encoded_frame = base64.b64encode(frame_jpg).decode('utf-8')
    try:
        response = requests.post(server_url, json={'frame': encoded_frame})
        if response.status_code == 200:
            print("Frame transmission successful")
        else:
            print(f"Frame transmission failure: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print(f"Server connection error: {e}")

    cv2.imshow('Webcam', frame_rgb)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

    time.sleep(0.1)

cap.release()
cv2.destroyAllWindows()