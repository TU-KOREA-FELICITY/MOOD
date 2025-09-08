import cv2
import boto3
import numpy as np
import requests
import json

def analyze_emotion():
    # Rekognition 클라이언트 생성
    rekognition = boto3.client('rekognition')

    # 웹캠 열기
    cap = cv2.VideoCapture(0)

    # 프레임 캡처
    ret, frame = cap.read()
    if not ret:
        return "프레임 캡처 실패"

    # OpenCV 이미지를 JPEG로 인코딩
    _, buffer = cv2.imencode('.jpg', frame)

    # 바이트 배열로 변환
    image_bytes = buffer.tobytes()

    # Rekognition API 호출
    response = rekognition.detect_faces(
        Image={'Bytes': image_bytes},
        Attributes=['ALL']
    )

    # 결과 처리
    result = "감정 분석 결과:\n"
    for face in response['FaceDetails']:
        emotions = face['Emotions']
        total_confidence = sum(emotion['Confidence'] for emotion in emotions)
        adjusted_emotions = [{
            'Type': emotion['Type'],
            'Confidence': (emotion['Confidence'] / total_confidence) * 100
        } for emotion in emotions]

        for emotion in adjusted_emotions:
            result += f"{emotion['Type']}: {emotion['Confidence']:.2f}%\n"

    # 리소스 해제
    cap.release()

    return result

if __name__ == "__main__":
    result = analyze_emotion()

    # 결과를 서버로 전송
    payload = json.dumps({'result': result}, ensure_ascii=False).encode('utf-8')
    try:
        response = requests.post('http://localhost:3000/emotion_result', data=payload, headers={'Content-Type': 'application/json; charset=utf-8'})
        if response.status_code == 200:
            print("결과가 성공적으로 서버로 전송되었습니다.")
        else:
            print("결과 전송 실패:", response.status_code)
    except requests.exceptions.RequestException as e:
        print("결과 전송 중 오류 발생:", e)