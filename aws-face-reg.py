import boto3
import cv2
import uuid
import os
import sys
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
        print(f"Image uploaded to S3: s3://{bucket_name}/{object_name}")
        return True
    except Exception as e:
        print(f"Error during S3 upload: {e}")
        return False

# Create collection
def create_collection(collection_id):
    try:
        rekognition.create_collection(CollectionId=collection_id)
        print(f"Collection created: {collection_id}")
    except rekognition.exceptions.ResourceAlreadyExistsException:
        print(f"Collection already exists: {collection_id}")

# Register face
def index_face(bucket_name, image_name, collection_id, person_id):
    response = rekognition.index_faces(
        CollectionId=collection_id,
        Image={'S3Object': {'Bucket': bucket_name, 'Name': image_name}},
        ExternalImageId=person_id,
        DetectionAttributes=['ALL']
    )
    face_id = response['FaceRecords'][0]['Face']['FaceId']
    print(f"Face registered.\nFace ID: {face_id}")
    return face_id

# Main execution code
if __name__ == "__main__":
    bucket_name = 'felicity-mood'
    collection_id = 'mood'

    create_collection(collection_id)

    if len(sys.argv) > 1:
        person_id = sys.argv[1]
    else:
        print("No username was entered.")
        sys.exit(1)

    image_name = capture_image()
    if image_name:
        object_name = f"faces/{person_id}/{image_name}"
        if upload_to_s3(image_name, bucket_name, object_name):
            face_id = index_face(bucket_name, object_name, collection_id, person_id)
            os.remove(image_name)  # Delete local image

            # Send result to server
            result = {"registered": True, "user_id": person_id, "face_id": face_id}
            requests.post('http://localhost:3000/registration_result', json=result)
