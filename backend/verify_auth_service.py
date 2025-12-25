"""Simple verification script for authentication service"""

from app.services.auth_service import auth_service
from app.core.exceptions import AuthenticationError

def test_password_hashing():
    """Test password hashing and verification"""
    print("Testing password hashing...")
    
    password = "TestPassword123!"
    hashed = auth_service.hash_password(password)
    
    print(f"  Original password: {password}")
    print(f"  Hashed password: {hashed[:50]}...")
    
    # Verify correct password
    is_valid = auth_service.verify_password(password, hashed)
    print(f"  Correct password verification: {is_valid}")
    assert is_valid, "Password verification failed for correct password"
    
    # Verify incorrect password
    is_invalid = auth_service.verify_password("WrongPassword", hashed)
    print(f"  Incorrect password verification: {is_invalid}")
    assert not is_invalid, "Password verification should fail for incorrect password"
    
    print("✓ Password hashing test passed\n")


def test_token_generation():
    """Test JWT token generation and decoding"""
    print("Testing JWT token generation...")
    
    user_id = 1
    email = "test@example.com"
    role = "student"
    
    # Create token
    token = auth_service.create_access_token(user_id, email, role)
    print(f"  Generated token: {token[:50]}...")
    
    # Decode token
    payload = auth_service.decode_token(token)
    print(f"  Decoded payload: {payload}")
    
    assert payload["sub"] == str(user_id), "User ID mismatch"
    assert payload["email"] == email, "Email mismatch"
    assert payload["role"] == role, "Role mismatch"
    assert "exp" in payload, "Expiration not in payload"
    
    print("✓ Token generation test passed\n")


def test_invalid_token():
    """Test invalid token handling"""
    print("Testing invalid token handling...")
    
    invalid_token = "invalid.token.here"
    
    try:
        auth_service.decode_token(invalid_token)
        print("✗ Should have raised AuthenticationError")
        assert False, "Should have raised AuthenticationError"
    except AuthenticationError as e:
        print(f"  Correctly raised AuthenticationError: {e.message}")
        print("✓ Invalid token test passed\n")


def test_token_expiration():
    """Test token expiration calculation"""
    print("Testing token expiration...")
    
    expiration = auth_service.get_token_expiration()
    print(f"  Token expiration: {expiration}")
    print(f"  Expiration minutes: {auth_service.access_token_expire_minutes}")
    
    print("✓ Token expiration test passed\n")


if __name__ == "__main__":
    print("=" * 60)
    print("Authentication Service Verification")
    print("=" * 60 + "\n")
    
    try:
        test_password_hashing()
        test_token_generation()
        test_invalid_token()
        test_token_expiration()
        
        print("=" * 60)
        print("All tests passed! ✓")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n✗ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
