import cv2
import numpy as np
from deepface import DeepFace
import json
import time

def collect_face_images(person_name, num_images=10):
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
    cap = cv2.VideoCapture(0)
    
    images = []
    count = 0
    last_capture_time = time.time()
    capture_interval = 1.5
    
    while count < num_images:
        ret, frame = cap.read()
        if not ret:
            break
        
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, 1.3, 5)
        
        current_time = time.time()
        time_since_last_capture = current_time - last_capture_time
        
        for (x, y, w, h) in faces:
            cv2.rectangle(frame, (x, y), (x+w, y+h), (255, 0, 0), 2)
            
            if time_since_last_capture >= capture_interval:
                face = frame[y:y+h, x:x+w]
                images.append(face)
                count += 1
                last_capture_time = current_time
                cv2.imshow('Captured Face', face)
        
        cv2.putText(frame, f"Capturing: {count}/{num_images}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
        cv2.imshow('Collecting Faces', frame)
        
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
    
    cap.release()
    cv2.destroyAllWindows()
    return images

def extract_face_features(images):
    features = []
    for img in images:
        try:
            rgb_img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            result = DeepFace.represent(rgb_img, model_name="Facenet", enforce_detection=False)
            if result:
                embedding = result[0]['embedding']
                features.append(embedding)
        except Exception as e:
            print(f"Error processing image: {e}")
    
    if features:
        return np.mean(features, axis=0)
    else:
        raise ValueError("No valid embeddings could be generated.")

def save_features_to_json(features, filename="features.json"):
    try:
        # 기존 JSON 파일 읽기
        try:
            with open(filename, "r") as file:
                data = json.load(file)
        except FileNotFoundError:
            data = []

        # 새로운 특징 추가
        data.append(features.tolist())

        # JSON 파일에 저장
        with open(filename, "w") as file:
            json.dump(data, file, indent=4)

        print(f"Features saved successfully.")
    except Exception as e:
        print(f"Error saving features: {e}")

def collect_and_save_features(num_images=10):
    print("Collecting face images...")
    images = collect_face_images("User", num_images)
    print("Extracting face features...")
    features = extract_face_features(images)
    save_features_to_json(features)

if __name__ == "__main__":
    collect_and_save_features()
