"""Clear all data from database tables"""

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal, engine
from app.models.user import User, Student, Instructor
from app.models.token import Token
from sqlalchemy import text

def clear_database():
    """Delete all records from all tables"""
    db = SessionLocal()
    
    try:
        print("🗑️  Clearing database...")
        
        # Delete in correct order (respecting foreign keys)
        tables_to_clear = [
            ("tokens", Token),
            ("students", Student),
            ("instructors", Instructor),
            ("users", User),
        ]
        
        for table_name, model in tables_to_clear:
            count = db.query(model).count()
            if count > 0:
                db.query(model).delete()
                print(f"  ✓ Deleted {count} records from {table_name}")
            else:
                print(f"  - {table_name} already empty")
        
        db.commit()
        print("\n✅ Database cleared successfully!")
        
        # Verify
        print("\n📊 Current counts:")
        for table_name, model in tables_to_clear:
            count = db.query(model).count()
            print(f"  - {table_name}: {count}")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    clear_database()
