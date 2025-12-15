"""Reset database - Delete and recreate all tables"""

import os
from sqlalchemy import create_engine, text
from app.database import Base
from app.models import user, course, attendance, assignment, content, token
from app.config import settings

def reset_database():
    """Drop all tables and recreate them"""
    
    # Delete existing database file if SQLite
    if settings.DATABASE_URL.startswith("sqlite"):
        db_file = settings.DATABASE_URL.replace("sqlite:///", "").replace("sqlite://", "")
        if os.path.exists(db_file):
            os.remove(db_file)
            print(f"✓ Deleted database file: {db_file}")
    
    # Create engine
    engine = create_engine(settings.DATABASE_URL)
    
    # Drop all tables
    print("Dropping all tables...")
    Base.metadata.drop_all(bind=engine)
    print("✓ All tables dropped")
    
    # Create all tables
    print("Creating all tables...")
    Base.metadata.create_all(bind=engine)
    print("✓ All tables created")
    
    # Verify tables
    with engine.connect() as conn:
        if settings.DATABASE_URL.startswith("sqlite"):
            result = conn.execute(text("SELECT name FROM sqlite_master WHERE type='table'"))
            tables = [row[0] for row in result]
        else:
            result = conn.execute(text("SELECT tablename FROM pg_tables WHERE schemaname='public'"))
            tables = [row[0] for row in result]
        
        print(f"\n✓ Created {len(tables)} tables:")
        for table in sorted(tables):
            print(f"  - {table}")
    
    print("\n✅ Database reset complete!")

if __name__ == "__main__":
    reset_database()
