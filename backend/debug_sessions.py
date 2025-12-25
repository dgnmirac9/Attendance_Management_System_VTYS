
import requests
import json
import datetime

BASE_URL = "http://localhost:8000/api/v1"

def debug_sessions():
    # 1. Login
    login_data = {
        "username": "ahmet.yilmaz@firat.edu.tr", # Assuming this user exists from previous context or seed
        "password": "password123"
    }
    
    # Try alternate user if needed, but let's assume one exists.
    # Actually, better to use the user that is creating sessions.
    
    print(f"Logging in as {login_data['username']}...")
    try:
        # OAuth2PasswordRequestForm expects form data
        resp = requests.post(f"{BASE_URL}/auth/login", data=login_data)
        if resp.status_code != 200:
            print(f"Login failed: {resp.text}")
            return
            
        token = resp.json()['access_token']
        headers = {"Authorization": f"Bearer {token}"}
        print("Login successful.")
        
        # 2. Get User Profile to find a course
        me_resp = requests.get(f"{BASE_URL}/users/me", headers=headers)
        user_id = me_resp.json()['user_id']
        print(f"User ID: {user_id}")
        
        # 3. Get Courses (to find a valid course_id)
        courses_resp = requests.get(f"{BASE_URL}/courses/instructor", headers=headers)
        courses = courses_resp.json()
        
        if not courses:
            print("No courses found for this instructor.")
            return

        course_id = courses[0]['course_id']
        print(f"Checking sessions for Course ID: {course_id}")
        
        # 4. Get Sessions (Mobile Endpoint)
        sessions_url = f"{BASE_URL}/attendance/mobile/course/{course_id}/sessions"
        sessions_resp = requests.get(sessions_url, headers=headers)
        sessions = sessions_resp.json()
        
        print("\n--- RAW BACKEND RESPONSE ---")
        print(json.dumps(sessions, indent=2))
        print("----------------------------\n")
        
        # 5. Simulate Mobile Parsing
        print("--- MOBILE LOGIC SIMULATION ---")
        now_utc = datetime.datetime.utcnow()
        print(f"Mobile simulation Time (UTC): {now_utc}")
        
        for session in sessions:
            sid = session.get('id') or session.get('attendance_id')
            is_active = session.get('isActive') or session.get('is_active')
            end_time_str = session.get('endTime') or session.get('end_time')
            
            print(f"\nSession {sid}:")
            print(f"  Unknown isActive from JSON: {is_active} (Type: {type(is_active)})")
            
            # Mobile Logic
            is_active_bool = (is_active is True) # Strict check? No, Dart is session['isActive'] == true
            
            if is_active:
                print("  Status: ACTIVE flag is SET")
                if end_time_str:
                    try:
                        # Parsing logic
                        # Python datetime.fromisoformat doesn't handle 'Z' nicely in older versions, 
                        # but let's look at the string format first.
                        print(f"  EndTime String: '{end_time_str}'")
                        
                        # Manual parse sim
                        # If string ends with Z, good. If not, append Z.
                        # Dart: DateTime.parse(str)
                        
                        # Let's perform the boolean check manually
                        # Assuming ISO format
                        if end_time_str.endswith('Z'):
                             end_time_str = end_time_str[:-1] # Remove Z for python fromisoformat
                        
                        end_time = datetime.datetime.fromisoformat(end_time_str)
                        
                        print(f"  Parsed EndTime: {end_time}")
                        print(f"  Now UTC:        {now_utc}")
                        
                        if now_utc < end_time:
                            print("  RESULT: >>> BUTTON SHOULD SHOW <<<")
                        else:
                            print("  RESULT: Session Expired")
                            
                    except Exception as e:
                        print(f"  Parse Error: {e}")
                else:
                    print("  No EndTime: >>> BUTTON SHOULD SHOW <<<")
            else:
                print("  Status: Closed")

    except Exception as e:
        print(f"Script Error: {e}")

if __name__ == "__main__":
    debug_sessions()
