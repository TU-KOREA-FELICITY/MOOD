import cv2
import numpy as np
from deepface import DeepFace
import json
import time
import requests

def load_features_from_json(filename="features.json"):
    try:
        with open(filename, "r") as file:
            return np.array(json.load(file))
    except FileNotFoundError:
        print("Features file not found. Please run the feature collection script first.")
        return None

def authenticate_person(test_features, stored_features, threshold=0.7):
    for i, stored_feature in enumerate(stored_features):
        similarity = np.dot(test_features, stored_feature) / (np.linalg.norm(test_features) * np.linalg.norm(stored_feature))
        if similarity > threshold:
            return i, True
    return None, False

def face_authentication():
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
    cap = cv2.VideoCapture(0)
    
    stored_features = load_features_from_json()
    if stored_features is None:
        return

    consecutive_success = 0
    authenticated_person = None
    
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, 1.3, 5)
        
        for (x, y, w, h) in faces:
            face = frame[y:y+h, x:x+w]
            embedding = DeepFace.represent(face, model_name="Facenet", enforce_detection=False)
            embedding = np.array(embedding[0]["embedding"])
            
            person_id, is_authenticated = authenticate_person(embedding, stored_features)
            
            if is_authenticated:
                cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)
                cv2.putText(frame, f"Authenticated: Person {person_id}", (x, y-10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)
                
                if person_id == authenticated_person:
                    consecutive_success += 1
                else:
                    consecutive_success = 1
                    authenticated_person = person_id
                
                if consecutive_success >= 3:
                    cv2.putText(frame, "Final Authentication Successful!", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
                    cv2.imshow('Face Authentication', frame)
                    cv2.waitKey(2000)
                    print("Final Authentication Successful! Sending result to server.")
                    
                    # 서버로 결과 전송
                    result = {"authenticated": True, "user_id": authenticated_person}
                    try:
                        response = requests.post("http://localhost:3000/auth_result", json=result)
                        if response.status_code == 200:
                            print("Authentication result sent successfully.")
                        else:
                            print(f"Failed to send authentication result. Status code: {response.status_code}")
                    except requests.exceptions.RequestException as e:
                        print(f"Error sending authentication result: {e}")
                    
                    return
            else:
                cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 0, 255), 2)
                cv2.putText(frame, "Not Authenticated", (x, y-10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 0, 255), 2)
                consecutive_success = 0
                authenticated_person = None
        
        cv2.imshow('Face Authentication', frame)
        
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    face_authentication()
