import cv2
import base64
import requests
import time

# 웹캠 캡처 객체 생성
cap = cv2.VideoCapture(0)

# Node.js 서버 URL
server_url = 'http://localhost:3000/webcam_frame'

while True:
    # 프레임 읽기
    ret, frame = cap.read()
    if not ret:
        print("Cannot read frame.")
        break

    # 프레임을 JPEG로 인코딩
    _, buffer = cv2.imencode('.jpg', frame)

    # JPEG 이미지를 base64로 인코딩
    jpg_as_text = base64.b64encode(buffer).decode()

    # Node.js 서버로 전송
    try:
        response = requests.post(server_url, json={'frame': jpg_as_text})
        if response.status_code == 200:
            print("Frame transmission successful")
        else:
            print(f"Frame transmission failure: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print(f"Server connection error: {e}")

    # 화면에 프레임 표시 (선택사항)
    cv2.imshow('Webcam', frame)

    # 'q' 키를 누르면 종료
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

    # 프레임 전송 간격 조절 (필요에 따라 조정)
    time.sleep(0.1)

# 자원 해제
cap.release()
cv2.destroyAllWindows()