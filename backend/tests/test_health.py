"""Test health check endpoint"""

import pytest


def test_health_check(client):
    """Test health check endpoint returns 200"""
    response = client.get("/health")
    
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "version" in data


def test_root_endpoint(client):
    """Test root endpoint returns API info"""
    response = client.get("/")
    
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert data["message"] == "C-Lens API"
    assert "docs" in data
