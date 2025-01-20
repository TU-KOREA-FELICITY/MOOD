import cv2
import boto3
import requests
import json

def analyze_emotion():
    rekognition = boto3.client('rekognition')
    cap = cv2.VideoCapture(0)

    ret, frame = cap.read()
    if not ret:
        return {"error": "프레임 캡처 실패"}

    _, buffer = cv2.imencode('.jpg', frame)
    image_bytes = buffer.tobytes()

    response = rekognition.detect_faces(
        Image={'Bytes': image_bytes},
        Attributes=['ALL']
    )

    emotions_summary = {}
    for face in response['FaceDetails']:
        emotions = face['Emotions']
        total_confidence = sum(emotion['Confidence'] for emotion in emotions)
        adjusted_emotions = {
            emotion['Type']: (emotion['Confidence'] / total_confidence) * 100
            for emotion in emotions
        }
        emotions_summary.update(adjusted_emotions)

    cap.release()
    return emotions_summary

if __name__ == "__main__":
    result = analyze_emotion()
    try:
        headers = {'Content-Type': 'application/json; charset=utf-8'}
        response = requests.post('http://localhost:3000/emotion_result', json=result, headers=headers)
        if response.status_code == 200:
            print("결과가 성공적으로 서버로 전송되었습니다.")
        else:
            print("결과 전송 실패:", response.status_code)
    except requests.exceptions.RequestException as e:
        print("결과 전송 중 오류 발생:", e)