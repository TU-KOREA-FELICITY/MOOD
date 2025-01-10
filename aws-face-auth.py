import boto3
import cv2
import uuid
import os
import requests

# AWS client setup
s3 = boto3.client('s3')
rekognition = boto3.client('rekognition')

# Capture face using webcam
def capture_image():
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Cannot open webcam.")
        return None

    ret, frame = cap.read()
    if ret:
        image_name = f"capture_{uuid.uuid4()}.jpg"
        cv2.imwrite(image_name, frame)
        print(f"Image captured: {image_name}")
        cap.release()
        return image_name
    else:
        print("Cannot read frame.")
        cap.release()
        return None

# Upload image to S3
def upload_to_s3(image_name, bucket_name, object_name):
    try:
        s3.upload_file(image_name, bucket_name, object_name)
        print(f"Image temporarily uploaded to S3: s3://{bucket_name}/{object_name}")
        return True
    except Exception as e:
        print(f"Error during S3 upload: {e}")
        return False

# Compare faces
def compare_faces(bucket_name, image_name, collection_id):
    try:
        response = rekognition.search_faces_by_image(
            CollectionId=collection_id,
            Image={'S3Object': {'Bucket': bucket_name, 'Name': image_name}},
            MaxFaces=1,
            FaceMatchThreshold=95
        )

        if len(response['FaceMatches']) > 0:
            match = response['FaceMatches'][0]
            print(f"Matching face found!")
            print(f"Confidence: {match['Similarity']:.2f}%")
            print(f"Person ID: {match['Face']['ExternalImageId']}")
            return {"authenticated": True, "user_id": match['Face']['ExternalImageId']}
        else:
            print("No matching face found.")
            return {"authenticated": False, "user_id": None}
    except Exception as e:
        print(f"Error during face comparison: {e}")
        return {"authenticated": False, "user_id": None}

# Main execution code
if __name__ == "__main__":
    bucket_name = 'felicity-mood'
    collection_id = 'mood'

    image_name = capture_image()
    if image_name:
        object_name = f"temp/{image_name}"
        if upload_to_s3(image_name, bucket_name, object_name):
            result = compare_faces(bucket_name, object_name, collection_id)
            os.remove(image_name)  # Delete local image
            s3.delete_object(Bucket=bucket_name, Key=object_name)  # Delete temporary S3 image

            # Send result to server
            requests.post('http://localhost:3000/auth_result', json=result)
