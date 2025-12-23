import requests
import json

BASE_URL = "http://localhost:8000/api/v1"
# Use known instructor/student login or token if needed.
# But for now, I'll assumem I can just hit the endpoint and see 401 or 422 to verify path/schema.

def test_check_in_schema():
    url = f"{BASE_URL}/attendance/check-in"
    
    # Try 1: check_in_data as JSON body (will fail if File is required)
    # Try 2: Multipart with check_in_data as form field
    
    files = {
        'face_image': ('test.jpg', b'fake_image_content', 'image/jpeg')
    }
    
    # Payload trying strict Pydantic parsing style (FastAPI sometimes expects 'check_in_data' field)
    data = {
        'check_in_data': json.dumps({'attendance_id': 1})
    }
    
    print(f"Testing POST {url} with multipart...")
    try:
        response = requests.post(url, files=files, data=data)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_check_in_schema()
