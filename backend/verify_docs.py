"""Verify API documentation configuration"""
import sys
import os

# Add the backend directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.main import app

def verify_documentation():
    """Verify that API documentation is properly configured"""
    
    print("=" * 60)
    print("C-Lens API Documentation Verification")
    print("=" * 60)
    
    # Check basic app configuration
    print(f"\n✓ App Title: {app.title}")
    print(f"✓ App Version: {app.version}")
    print(f"✓ Docs URL: {app.docs_url}")
    print(f"✓ ReDoc URL: {app.redoc_url}")
    
    # Check if description is set
    if app.description and len(app.description) > 100:
        print(f"✓ Description: {len(app.description)} characters")
        print(f"  Preview: {app.description[:100]}...")
    else:
        print("✗ Description not properly set")
        return False
    
    # Check contact info
    if app.contact:
        print(f"✓ Contact: {app.contact}")
    
    # Check license info
    if app.license_info:
        print(f"✓ License: {app.license_info}")
    
    # Check OpenAPI tags
    if app.openapi_tags:
        print(f"\n✓ OpenAPI Tags: {len(app.openapi_tags)} tags defined")
        for tag in app.openapi_tags:
            print(f"  - {tag['name']}: {tag['description'][:50]}...")
    else:
        print("✗ OpenAPI tags not defined")
        return False
    
    # Generate OpenAPI schema
    print("\n✓ Generating OpenAPI schema...")
    openapi_schema = app.openapi()
    
    # Check security schemes
    if "components" in openapi_schema and "securitySchemes" in openapi_schema["components"]:
        print(f"✓ Security Schemes: {list(openapi_schema['components']['securitySchemes'].keys())}")
    else:
        print("✗ Security schemes not defined")
        return False
    
    # Check examples
    if "components" in openapi_schema and "examples" in openapi_schema["components"]:
        print(f"✓ Examples: {len(openapi_schema['components']['examples'])} examples defined")
        for example_name in openapi_schema['components']['examples'].keys():
            print(f"  - {example_name}")
    else:
        print("✗ Examples not defined")
        return False
    
    # Check endpoints
    if "paths" in openapi_schema:
        print(f"\n✓ API Endpoints: {len(openapi_schema['paths'])} paths defined")
        for path, methods in openapi_schema['paths'].items():
            for method in methods.keys():
                if method in ['get', 'post', 'put', 'delete', 'patch']:
                    print(f"  - {method.upper()} {path}")
    else:
        print("✗ No API paths defined")
        return False
    
    # Check authentication endpoints
    auth_endpoints = [
        "/api/v1/auth/register",
        "/api/v1/auth/login",
        "/api/v1/auth/logout"
    ]
    
    print("\n✓ Authentication Endpoints:")
    for endpoint in auth_endpoints:
        if endpoint in openapi_schema['paths']:
            methods = [m.upper() for m in openapi_schema['paths'][endpoint].keys() if m in ['get', 'post', 'put', 'delete']]
            print(f"  - {endpoint}: {', '.join(methods)}")
            
            # Check if endpoint has proper documentation
            for method in ['post', 'get']:
                if method in openapi_schema['paths'][endpoint]:
                    endpoint_data = openapi_schema['paths'][endpoint][method]
                    if 'summary' in endpoint_data:
                        print(f"    Summary: {endpoint_data['summary']}")
                    if 'description' in endpoint_data and len(endpoint_data['description']) > 50:
                        print(f"    Description: {len(endpoint_data['description'])} characters")
                    if 'responses' in endpoint_data:
                        print(f"    Responses: {', '.join(endpoint_data['responses'].keys())}")
        else:
            print(f"  ✗ {endpoint} not found")
            return False
    
    print("\n" + "=" * 60)
    print("✓ All documentation checks passed!")
    print("=" * 60)
    print("\nTo view the documentation:")
    print("1. Start the server: uvicorn app.main:app --reload")
    print("2. Open Swagger UI: http://localhost:8000/docs")
    print("3. Open ReDoc: http://localhost:8000/redoc")
    print("4. View OpenAPI JSON: http://localhost:8000/openapi.json")
    print("\nDocumentation files created:")
    print("- backend/API_DOCUMENTATION.md (Comprehensive guide)")
    print("- backend/API_QUICK_REFERENCE.md (Quick reference)")
    
    return True

if __name__ == "__main__":
    try:
        success = verify_documentation()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n✗ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
