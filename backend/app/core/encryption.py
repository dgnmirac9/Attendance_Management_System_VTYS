"""Encryption utilities for sensitive data"""

from cryptography.fernet import Fernet
import base64
from app.config import settings
from app.core.exceptions import AppException


class EncryptionService:
    """Service for encrypting and decrypting sensitive data"""
    
    def __init__(self):
        """Initialize encryption service with key from settings"""
        try:
            # Ensure the key is properly formatted (base64 encoded, 44 chars)
            key = settings.ENCRYPTION_KEY
            
            # If key is not base64 encoded, encode it
            if len(key) != 44:
                # Generate a proper key from the provided string
                key_bytes = key.encode('utf-8')
                # Pad or truncate to 32 bytes
                key_bytes = key_bytes[:32].ljust(32, b'0')
                # Base64 encode
                key = base64.urlsafe_b64encode(key_bytes).decode('utf-8')
            
            self.cipher = Fernet(key.encode('utf-8'))
        except Exception as e:
            raise AppException(
                message=f"Failed to initialize encryption service: {str(e)}",
                status_code=500
            )
    
    def encrypt(self, data: str) -> str:
        """
        Encrypt string data
        
        Args:
            data: Plain text string to encrypt
            
        Returns:
            Encrypted string (base64 encoded)
        """
        try:
            data_bytes = data.encode('utf-8')
            encrypted_bytes = self.cipher.encrypt(data_bytes)
            return encrypted_bytes.decode('utf-8')
        except Exception as e:
            raise AppException(
                message=f"Encryption failed: {str(e)}",
                status_code=500
            )
    
    def decrypt(self, encrypted_data: str) -> str:
        """
        Decrypt encrypted data
        
        Args:
            encrypted_data: Encrypted string (base64 encoded)
            
        Returns:
            Decrypted plain text string
        """
        try:
            encrypted_bytes = encrypted_data.encode('utf-8')
            decrypted_bytes = self.cipher.decrypt(encrypted_bytes)
            return decrypted_bytes.decode('utf-8')
        except Exception as e:
            raise AppException(
                message=f"Decryption failed: {str(e)}",
                status_code=500
            )


# Create singleton instance
encryption_service = EncryptionService()
