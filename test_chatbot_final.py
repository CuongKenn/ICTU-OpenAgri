#!/usr/bin/env python3
"""Test chatbot integration with Gemini."""
import requests
import json

BASE_URL = "http://localhost:8000/api/v1"

# Login
print("1. Logging in...")
login_response = requests.post(
    f"{BASE_URL}/users/login",
    json={"username": "admin", "password": "admin123"}
)
print(f"Login status: {login_response.status_code}")
if login_response.status_code != 200:
    print(f"Login failed: {login_response.text}")
    exit(1)

token = login_response.json().get("access_token")
print(f"Token: {token[:20]}..." if token else "No token")

headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

# Test chatbot
print("\n2. Testing chatbot...")
chatbot_payload = {
    "question": "Tôi đang trồng lúa, làm thế nào để có năng suất cao?"
}

response = requests.post(
    f"{BASE_URL}/chatbot/chat",
    json=chatbot_payload,
    headers=headers
)

print(f"Chatbot response status: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
