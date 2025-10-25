#!/usr/bin/env python3
"""
WhatsApp Birthday Bot - Flask API
Main application entry point
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import sys
import subprocess
import threading
from datetime import datetime

# Add app directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

app = Flask(__name__)
CORS(app)

# Configuration
WHATSAPP_BOT_URL = os.getenv("BAILEYS_URL", "http://wppconnect-bot:3005")

@app.route("/")
def index():
    """Root endpoint"""
    return jsonify({
        "name": "WhatsApp Birthday Bot API",
        "version": "1.0",
        "endpoints": {
            "health": "/health",
            "birthdays": "/birthdays (GET, POST)",
            "birthdays/:id": "/birthdays/:id (DELETE)",
            "today_birthdays": "/today-birthdays",
            "groups": "/groups",
            "send_birthday_messages": "/send-birthday-messages",
            "test_whatsapp": "/test-whatsapp"
        }
    })

@app.route("/health")
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "ok",
        "service": "python-api",
        "timestamp": datetime.utcnow().isoformat(),
        "whatsapp_bot": WHATSAPP_BOT_URL
    })

@app.route("/birthdays", methods=["GET"])
def get_birthdays():
    """Get all birthdays from DynamoDB"""
    try:
        from db.dynamodb_dao import DynamoDBDAO
        
        dao = DynamoDBDAO()
        birthdays = dao.get_all_birthdays()
        return jsonify(birthdays)
    except Exception as e:
        app.logger.error(f"Error fetching birthdays: {str(e)}")
        return jsonify({"error": str(e), "birthdays": []}), 500

@app.route("/birthdays", methods=["POST"])
def add_birthday():
    """Add a new birthday"""
    try:
        data = request.json
        
        # Validate required fields
        required_fields = ["name", "birth_month_day"]
        if not all(field in data for field in required_fields):
            return jsonify({"error": "Missing required fields: name, birth_month_day"}), 400
        
        from db.dynamodb_dao import DynamoDBDAO
        
        dao = DynamoDBDAO()
        result = dao.add_birthday(data)
        return jsonify({"status": "created", "data": result}), 201
    except Exception as e:
        app.logger.error(f"Error adding birthday: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route("/birthdays/<birthday_id>", methods=["DELETE"])
def delete_birthday(birthday_id):
    """Delete a birthday"""
    try:
        from db.dynamodb_dao import DynamoDBDAO
        
        dao = DynamoDBDAO()
        dao.delete_birthday(birthday_id)
        return jsonify({"status": "deleted", "id": birthday_id})
    except Exception as e:
        app.logger.error(f"Error deleting birthday: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route("/groups", methods=["GET"])
def get_groups():
    """Get WhatsApp groups from wppconnect-bot"""
    try:
        import requests
        
        response = requests.get(f"{WHATSAPP_BOT_URL}/groups", timeout=5)
        return jsonify(response.json())
    except Exception as e:
        app.logger.error(f"Error fetching groups: {str(e)}")
        return jsonify({"error": str(e), "groups": []}), 500

@app.route("/send-birthday-messages", methods=["POST"])
def send_birthday_messages():
    """Manually trigger birthday message sending"""
    try:
        def run_birthday_service():
            try:
                result = subprocess.run(
                    ["python3", "/app/app/whatsapp/whatsapp_birthday_service.py"],
                    capture_output=True,
                    text=True,
                    timeout=60,
                    cwd="/app/app"
                )
                app.logger.info(f"Birthday service output: {result.stdout}")
                if result.stderr:
                    app.logger.error(f"Birthday service errors: {result.stderr}")
            except Exception as e:
                app.logger.error(f"Error running birthday service: {str(e)}")
        
        thread = threading.Thread(target=run_birthday_service)
        thread.daemon = True
        thread.start()
        
        return jsonify({
            "status": "started",
            "message": "Birthday service running in background"
        })
    except Exception as e:
        app.logger.error(f"Error starting birthday service: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route("/test-whatsapp", methods=["POST"])
def test_whatsapp():
    """Test WhatsApp connection by sending a message"""
    try:
        import requests
        
        data = request.json
        group = data.get("group")
        message = data.get("message", "🧪 Test message from Birthday Bot API")
        
        if not group:
            return jsonify({"error": "group parameter required"}), 400
        
        response = requests.post(
            f"{WHATSAPP_BOT_URL}/send",
            json={"group": group, "message": message},
            timeout=10
        )
        
        return jsonify(response.json())
    except Exception as e:
        app.logger.error(f"Error testing WhatsApp: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route("/today-birthdays", methods=["GET"])
def get_today_birthdays():
    """Get birthdays for today"""
    try:
        from db.dynamodb_dao import DynamoDBDAO
        
        dao = DynamoDBDAO()
        today = datetime.now().strftime("%m-%d")
        
        all_birthdays = dao.get_all_birthdays()
        today_birthdays = [b for b in all_birthdays if b.get("birth_month_day") == today]
        
        return jsonify({
            "date": today,
            "count": len(today_birthdays),
            "birthdays": today_birthdays
        })
    except Exception as e:
        app.logger.error(f"Error fetching today's birthdays: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Not found"}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal server error"}), 500

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    debug = os.getenv("DEBUG", "false").lower() == "true"
    
    print("=" * 50)
    print(f"🚀 WhatsApp Birthday Bot API")
    print(f"   Port: {port}")
    print(f"   Debug: {debug}")
    print(f"   WhatsApp Bot: {WHATSAPP_BOT_URL}")
    print(f"   Python Path: {sys.path[0]}")
    print("=" * 50)
    
    app.run(host="0.0.0.0", port=port, debug=debug)
