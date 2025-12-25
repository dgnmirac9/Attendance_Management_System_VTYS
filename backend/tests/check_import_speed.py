import time
import sys
import os

# Add project root to path
sys.path.append(os.getcwd())

print("Measuring import time for app.services.face_service...")
start_time = time.time()

try:
    from app.services import face_service
    end_time = time.time()
    duration = end_time - start_time
    print(f"Import successful! Time taken: {duration:.4f} seconds")
    
    if duration < 1.0:
        print("[SUCCESS] Import is fast (lazy loading working)")
    else:
        print("[WARNING] Import is slow (lazy loading NOT working)")
        
except Exception as e:
    print(f"[ERROR] Import failed: {e}")
