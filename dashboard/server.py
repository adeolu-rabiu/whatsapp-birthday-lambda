from flask import Flask, send_from_directory, jsonify, request
from flask_cors import CORS
import os
from dotenv import load_dotenv

# Load .env
load_dotenv()

# Get environment variables
API_BASE = os.getenv("API_BASE", "https://s9i0mo0564.execute-api.eu-west-2.amazonaws.com")

# Initialize Flask app
app = Flask(__name__, static_folder=".", static_url_path="")
CORS(app)

@app.route("/")
def index():
    return send_from_directory(".", "index.html")

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "target": API_BASE})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

