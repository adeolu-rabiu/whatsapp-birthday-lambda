# /opt/whatsapp-birthday-lambda/dashboard/server.py
import os
from flask import Flask, jsonify, send_from_directory, request, Response
from flask_cors import CORS
import requests

API_BASE = os.getenv("API_BASE", "http://python-api:5000")

app = Flask(__name__, static_folder=".", static_url_path="")
CORS(app)  # optional now that we same-origin proxy

@app.after_request
def _no_cache(resp):
    resp.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    resp.headers["Pragma"] = "no-cache"
    resp.headers["Expires"] = "0"
    return resp

@app.route("/")
def index():
    return send_from_directory(".", "index.html")

@app.route("/config")
def config():
    # kept for debugging
    return jsonify({"apiBase": "/api", "target": API_BASE})

@app.route("/health")
def health():
    return jsonify({"status": "ok", "target": API_BASE})

# -------- proxy all API calls to python-api --------
@app.route("/api/<path:path>", methods=["GET", "POST", "PUT", "PATCH", "DELETE"])
def proxy(path):
    url = f"{API_BASE}/{path}"
    method = request.method

    # forward headers except host, and content
    headers = {k: v for k, v in request.headers.items() if k.lower() != "host"}
    data = request.get_data()
    params = request.args

    try:
        r = requests.request(method, url, headers=headers, params=params, data=data, timeout=30)
        # pass through status + body + content-type
        resp = Response(r.content, status=r.status_code)
        if "Content-Type" in r.headers:
            resp.headers["Content-Type"] = r.headers["Content-Type"]
        return resp
    except requests.RequestException as e:
        return jsonify({"ok": False, "error": str(e), "target": url}), 502
# ---------------------------------------------------

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

