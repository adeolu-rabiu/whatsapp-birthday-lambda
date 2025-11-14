with open('app.py', 'r') as f:
    content = f.read()

# Find and replace the test_whatsapp function
old_function = '''@app.route("/test-whatsapp", methods=["POST"])
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
        return jsonify({"error": str(e)}), 500'''

new_function = '''@app.route("/test-whatsapp", methods=["POST"])
def test_whatsapp():
    """Test WhatsApp connection using the smart send_message function"""
    try:
        import sys
        import os
        
        # Add whatsapp directory to path
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'whatsapp'))
        from whatsapp_birthday_service import send_message
        
        data = request.json
        group = data.get("group")
        message = data.get("message", "�� Test message from Birthday Bot API")

        if not group:
            return jsonify({"error": "group parameter required"}), 400

        # Use the smart send_message function with all variants
        success = send_message(group, message)
        
        if success:
            return jsonify({
                "status": "success",
                "message": "Message sent successfully",
                "group": group
            })
        else:
            return jsonify({
                "status": "failed",
                "message": "Failed to send message (check logs for details)",
                "group": group
            }), 500
            
    except Exception as e:
        app.logger.error(f"Error testing WhatsApp: {str(e)}")
        return jsonify({"error": str(e)}), 500'''

content = content.replace(old_function, new_function)

with open('app.py', 'w') as f:
    f.write(content)

print("✅ Updated test-whatsapp endpoint to use send_message with variants")
