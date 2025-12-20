import requests
import sys
import random
import time

BASE_URL = "http://localhost:8000/api/v1"

# Test Data (Dynamic to avoid conflicts)
rand_suffix = int(time.time())
INSTRUCTOR_EMAIL = f"instructor_{rand_suffix}@test.com"
INSTRUCTOR_PASS = "Pass1234"
STUDENT_EMAIL = f"student_{rand_suffix}@test.com"
STUDENT_PASS = "Pass1234"

instructor_token = ""
student_token = ""
created_course_id = 0
created_attendance_id = 0

def print_result(name, success, detail=""):
    status = "[PASS]" if success else "[FAIL]"
    print(f"{status} - {name} {detail}")
    if not success:
        print(f"   -> Stopping tests due to failure.")
        sys.exit(1)

def login(email, password):
    url = f"{BASE_URL}/auth/login"
    try:
        # Endpoint expects JSON body (LoginRequest)
        json_data = {"email": email, "password": password}
        response = requests.post(url, json=json_data) 
        if response.status_code == 200:
            data = response.json()
            # Try both keys just in case
            return data.get("accessToken") or data.get("access_token")
            
        print(f"Login failed for {email}: {response.status_code} - {response.text}")
        return None
    except Exception as e:
        print(f"Error logging in: {e}")
        return None

def main():
    global instructor_token, student_token, created_course_id, created_attendance_id
    
    print(f">>> Starting Backend Endpoint Verification (Live Server) - Run ID: {rand_suffix}\n")

    # 1. AUTHENTICATION
    print("--- 1. Authentication ---")
    
    # Register Temp Instructor
    print(f"   -> Registering {INSTRUCTOR_EMAIL}...")
    reg_url = f"{BASE_URL}/auth/register"
    # Register expects Form Data (not JSON)
    reg_data = {
        "email": INSTRUCTOR_EMAIL,
        "password": INSTRUCTOR_PASS,
        "fullName": "Test Instructor", # Alias
        "role": "instructor",
        "title": "Dr."
    }
    res = requests.post(reg_url, data=reg_data)
    if res.status_code not in [200, 201] and res.status_code != 409:
         print(f"   -> Registration failed: {res.status_code} - {res.text}")
    
    instructor_token = login(INSTRUCTOR_EMAIL, INSTRUCTOR_PASS)   
    print_result("Instructor Login", instructor_token is not None)

    # Register Temp Student
    print(f"   -> Registering {STUDENT_EMAIL}...")
    reg_data_student = {
        "email": STUDENT_EMAIL,
        "password": STUDENT_PASS,
        "fullName": "Test Student", # Alias
        "role": "student",
        "studentNumber": f"2{str(rand_suffix)[-8:]}", # Exactly 9 digits
    }
    res = requests.post(reg_url, data=reg_data_student)
    if res.status_code not in [200, 201] and res.status_code != 409:
         print(f"   -> Student Registration failed: {res.status_code} - {res.text}")

    student_token = login(STUDENT_EMAIL, STUDENT_PASS)
    print_result("Student Login", student_token is not None)


    # 2. COURSES
    print("\n--- 2. Courses (Instructor) ---")
    headers_inst = {"Authorization": f"Bearer {instructor_token}"}
    headers_stud = {"Authorization": f"Bearer {student_token}"}

    # Create Course
    course_data = {
        "courseCode": "CS101-TEST", 
        "courseName": "Test Course", 
        "department": "CS",
        "description": "Test Description",
        "semester": "Fall 2024" # Required field
    }
    
    res = requests.post(f"{BASE_URL}/courses/", json=course_data, headers=headers_inst)
    
    if res.status_code == 422:
        print(f"   -> Create Course 422. Retrying with snake_case...")
        course_data_snake = {
            "course_code": "CS101-TEST",
            "course_name": "Test Course",
            "department": "CS",
            "description": "Test Description",
            "semester": "Fall 2024"
        }
        res = requests.post(f"{BASE_URL}/courses/", json=course_data_snake, headers=headers_inst)

    print_result("Create Course", res.status_code == 201 or res.status_code == 200, res.text)
    if res.status_code in [200, 201]:
        data = res.json()
        created_course_id = data.get("courseId") or data.get("course_id") or data.get("id")
        print(f"   -> Created Course ID: {created_course_id}")
    else:
        print_result("Create Course failed", False, res.text)

    # Get Courses (Instructor)
    res = requests.get(f"{BASE_URL}/courses/", headers=headers_inst)
    courses = res.json() # List
    # Check if created_course_id is in list
    found = False
    if isinstance(courses, list):
         found = any((c.get("id")==created_course_id or c.get("courseId")==created_course_id) for c in courses)
    
    print_result("Get Courses (Instructor)", found, f"Total courses: {len(courses)}")

    # 3. ATTENDANCE
    print("\n--- 3. Attendance (Instructor) ---")
    
    # Create Session
    session_data = {
        "courseId": created_course_id, # camelCase
        "sessionName": "Test Session",
        "description": "Testing delete",
        "durationMinutes": 60
    }
    res = requests.post(f"{BASE_URL}/attendance/", json=session_data, headers=headers_inst)
    
    if res.status_code == 422:
         print(f"   -> Create Session 422. Retrying with snake_case...")
         session_data_snake = {
            "course_id": created_course_id,
            "session_name": "Test Session",
            "description": "Testing delete",
            "duration_minutes": 60
         }
         res = requests.post(f"{BASE_URL}/attendance/", json=session_data_snake, headers=headers_inst)

    print_result("Create Attendance Session", res.status_code == 201, res.text)
    data = res.json()
    created_attendance_id = data.get("attendanceId") or data.get("attendance_id") 
    print(f"   -> Created Attendance ID: {created_attendance_id}")

    # Verify Mobile Endpoint (Get Sessions)
    res = requests.get(f"{BASE_URL}/attendance/mobile/course/{created_course_id}/sessions", headers=headers_inst)
    print_result("Get Mobile Sessions Endpoint", res.status_code == 200, res.text)
    
    sessions = res.json()
    found_session = False
    if isinstance(sessions, list):
        found_session = any((s.get("attendanceId") == created_attendance_id) for s in sessions)
    print_result("Verify Session in List", found_session)

    # DELETE Session (The Bug Fix)
    print(f"   -> Deleting Session ID: {created_attendance_id}")
    res = requests.delete(f"{BASE_URL}/attendance/{created_attendance_id}", headers=headers_inst)
    print_result("DELETE Attendance Session", res.status_code == 200, res.text)

    # Verify Deletion
    res = requests.get(f"{BASE_URL}/attendance/mobile/course/{created_course_id}/sessions", headers=headers_inst)
    sessions = res.json()
    deleted = True
    if isinstance(sessions, list):
        deleted = not any((s.get("attendanceId") == created_attendance_id) for s in sessions)
    print_result("Verify Deletion (Session gone)", deleted)


    # 4. COURSE DELETION (Cleanup)
    print("\n--- 4. Course Cleanup ---")
    res = requests.delete(f"{BASE_URL}/courses/{created_course_id}", headers=headers_inst)
    print_result("DELETE Course", res.status_code == 200)
    
    # Verify Course Gone from List (is_active filter test)
    res = requests.get(f"{BASE_URL}/courses/", headers=headers_inst)
    courses = res.json()
    gone = True
    if isinstance(courses, list):
        gone = not any((c.get("id")==created_course_id or c.get("courseId")==created_course_id) for c in courses)
    print_result("Verify Course Deletion (is_active filter)", gone)

    print("\n[OK] ALL TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    main()
