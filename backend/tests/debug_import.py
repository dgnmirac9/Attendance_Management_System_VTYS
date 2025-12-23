
import sys
from unittest.mock import MagicMock

# Mock problematic dependencies
sys.modules["app.services.face_service"] = MagicMock()
sys.modules["deepface"] = MagicMock()
sys.modules["cv2"] = MagicMock()
sys.modules["numpy"] = MagicMock()

def test_debug_import():
    try:
        print("\n--- ATTEMPTING IMPORT ---")
        from app.api.v1 import attendances
        print("--- IMPORT SUCCESS ---")
        assert attendances is not None
    except Exception as e:
        print(f"\n--- IMPORT FAILED: {e} ---")
        import traceback
        traceback.print_exc()
        raise e
