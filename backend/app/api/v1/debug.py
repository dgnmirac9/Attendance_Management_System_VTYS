"""Debug endpoints for development - shows database tables and data"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import inspect, text
from typing import Dict, List, Any

from app.database import get_db
from app.config import settings

router = APIRouter()


@router.get(
    "/tables",
    summary="List all database tables",
    description="""
    **Development Only Endpoint**
    
    Lists all tables in the database with their column information.
    This endpoint is only available in development environment.
    
    Returns:
    - Table names
    - Column names and types for each table
    - Row counts
    """,
    response_model=Dict[str, Any]
)
async def list_tables(db: Session = Depends(get_db)):
    """List all database tables and their structure"""
    
    # Only allow in development
    if settings.ENVIRONMENT != "development":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This endpoint is only available in development environment"
        )
    
    try:
        inspector = inspect(db.bind)
        tables_info = {}
        
        for table_name in inspector.get_table_names():
            # Get columns
            columns = []
            for column in inspector.get_columns(table_name):
                columns.append({
                    "name": column["name"],
                    "type": str(column["type"]),
                    "nullable": column["nullable"],
                    "default": str(column["default"]) if column["default"] else None,
                })
            
            # Get row count
            result = db.execute(text(f"SELECT COUNT(*) FROM {table_name}"))
            row_count = result.scalar()
            
            tables_info[table_name] = {
                "columns": columns,
                "row_count": row_count,
                "primary_keys": inspector.get_pk_constraint(table_name)["constrained_columns"],
                "foreign_keys": [
                    {
                        "constrained_columns": fk["constrained_columns"],
                        "referred_table": fk["referred_table"],
                        "referred_columns": fk["referred_columns"],
                    }
                    for fk in inspector.get_foreign_keys(table_name)
                ],
            }
        
        return {
            "database": str(db.bind.url).split("@")[1] if "@" in str(db.bind.url) else "unknown",
            "total_tables": len(tables_info),
            "tables": tables_info,
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve table information: {str(e)}"
        )


@router.get(
    "/table/{table_name}",
    summary="Get table data",
    description="""
    **Development Only Endpoint**
    
    Retrieves all data from a specific table.
    
    Parameters:
    - **table_name**: Name of the table to query
    - **limit**: Maximum number of rows to return (default: 100)
    
    Returns:
    - Table data as list of dictionaries
    - Column names
    - Total row count
    """,
    response_model=Dict[str, Any]
)
async def get_table_data(
    table_name: str,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get data from a specific table"""
    
    # Only allow in development
    if settings.ENVIRONMENT != "development":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This endpoint is only available in development environment"
        )
    
    try:
        inspector = inspect(db.bind)
        
        # Check if table exists
        if table_name not in inspector.get_table_names():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Table '{table_name}' not found"
            )
        
        # Get column names
        columns = [col["name"] for col in inspector.get_columns(table_name)]
        
        # Get total count
        count_result = db.execute(text(f"SELECT COUNT(*) FROM {table_name}"))
        total_count = count_result.scalar()
        
        # Get data with limit
        result = db.execute(text(f"SELECT * FROM {table_name} LIMIT :limit"), {"limit": limit})
        rows = result.fetchall()
        
        # Convert to list of dicts
        data = []
        for row in rows:
            row_dict = {}
            for i, col_name in enumerate(columns):
                value = row[i]
                # Convert datetime and other types to string for JSON serialization
                if value is not None and not isinstance(value, (str, int, float, bool)):
                    value = str(value)
                row_dict[col_name] = value
            data.append(row_dict)
        
        return {
            "table_name": table_name,
            "columns": columns,
            "total_rows": total_count,
            "returned_rows": len(data),
            "limit": limit,
            "data": data,
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve table data: {str(e)}"
        )


@router.get(
    "/stats",
    summary="Database statistics",
    description="""
    **Development Only Endpoint**
    
    Provides quick statistics about the database:
    - Total number of tables
    - Row counts for each table
    - Database size information
    """,
    response_model=Dict[str, Any]
)
async def database_stats(db: Session = Depends(get_db)):
    """Get database statistics"""
    
    # Only allow in development
    if settings.ENVIRONMENT != "development":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This endpoint is only available in development environment"
        )
    
    try:
        inspector = inspect(db.bind)
        table_names = inspector.get_table_names()
        
        stats = {
            "total_tables": len(table_names),
            "tables": {},
        }
        
        for table_name in table_names:
            result = db.execute(text(f"SELECT COUNT(*) FROM {table_name}"))
            row_count = result.scalar()
            stats["tables"][table_name] = row_count
        
        # Get database size (PostgreSQL specific)
        try:
            db_name = str(db.bind.url.database)
            size_result = db.execute(
                text("SELECT pg_size_pretty(pg_database_size(:db_name))"),
                {"db_name": db_name}
            )
            stats["database_size"] = size_result.scalar()
        except:
            stats["database_size"] = "N/A"
        
        return stats
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve database stats: {str(e)}"
        )


@router.post(
    "/clear-table/{table_name}",
    summary="Clear table data",
    description="""
    **Development Only Endpoint - USE WITH CAUTION**
    
    Deletes all data from a specific table.
    This operation cannot be undone!
    
    Parameters:
    - **table_name**: Name of the table to clear
    
    Returns:
    - Number of rows deleted
    """,
    response_model=Dict[str, Any]
)
async def clear_table(table_name: str, db: Session = Depends(get_db)):
    """Clear all data from a table (development only)"""
    
    # Only allow in development
    if settings.ENVIRONMENT != "development":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This endpoint is only available in development environment"
        )
    
    try:
        inspector = inspect(db.bind)
        
        # Check if table exists
        if table_name not in inspector.get_table_names():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Table '{table_name}' not found"
            )
        
        # Get count before deletion
        count_result = db.execute(text(f"SELECT COUNT(*) FROM {table_name}"))
        rows_before = count_result.scalar()
        
        # Delete all rows
        db.execute(text(f"DELETE FROM {table_name}"))
        db.commit()
        
        return {
            "table_name": table_name,
            "rows_deleted": rows_before,
            "message": f"Successfully cleared {rows_before} rows from {table_name}",
        }
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to clear table: {str(e)}"
        )
