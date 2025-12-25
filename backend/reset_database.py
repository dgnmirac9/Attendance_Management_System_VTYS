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
    
    # Drop all tables with CASCADE
    print("Dropping all tables...")
    
    if settings.DATABASE_URL.startswith("sqlite"):
        Base.metadata.drop_all(bind=engine)
    else:
        # PostgreSQL specific: Drop all tables in public schema
        with engine.connect() as conn:
            # Disable constraint checking temporarily if needed, but CASCADE is better
            conn.execute(text("DO $$ DECLARE r RECORD; BEGIN FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE'; END LOOP; END $$;"))
            conn.commit()
            
    print("All tables dropped")
    
    # Create all tables
    print("Creating all tables...")
    Base.metadata.create_all(bind=engine)
    print("All tables created")
    
    # Verify tables
    with engine.connect() as conn:
        if settings.DATABASE_URL.startswith("sqlite"):
            result = conn.execute(text("SELECT name FROM sqlite_master WHERE type='table'"))
            tables = [row[0] for row in result]
        else:
            result = conn.execute(text("SELECT tablename FROM pg_tables WHERE schemaname='public'"))
            tables = [row[0] for row in result]
        
        print(f"\nCreated {len(tables)} tables:")
        for table in sorted(tables):
            print(f"  - {table}")
    
    print("\nDatabase reset complete!")

if __name__ == "__main__":
    reset_database()
