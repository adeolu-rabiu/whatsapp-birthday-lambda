import time
import os
import logging
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
import json
from http.server import BaseHTTPRequestHandler, HTTPServer
import threading

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("simple_whatsapp.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("simple_whatsapp")

class WhatsAppBot:
    def __init__(self):
        self.setup_driver()
        
    def setup_driver(self):
        logger.info("Setting up Chrome driver")
        options = Options()
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        
        service = Service(ChromeDriverManager().install())
        self.driver = webdriver.Chrome(service=service, options=options)
        logger.info("Chrome driver initialized")
        
    def login_to_whatsapp(self):
        logger.info("Opening WhatsApp Web")
        self.driver.get("https://web.whatsapp.com/")
        
        logger.info("Waiting for WhatsApp to load...")
        WebDriverWait(self.driver, 60).until(
            lambda d: len(d.find_elements(By.XPATH, '//div[@id="side"]')) > 0
        )
        logger.info("WhatsApp Web loaded successfully")
        
    def send_message(self, group_name, message):
        logger.info(f"Sending message to {group_name}")
        
        # Search for the group
        search_box = WebDriverWait(self.driver, 10).until(
            EC.presence_of_element_located((By.XPATH, '//div[@contenteditable="true"]'))
        )
        search_box.clear()
        search_box.send_keys(group_name)
        time.sleep(2)
        
        # Click on the group
        group_element = WebDriverWait(self.driver, 10).until(
            EC.presence_of_element_located((By.XPATH, f'//span[@title="{group_name}"]'))
        )
        group_element.click()
        logger.info(f"Group {group_name} found and clicked")
        
        # Wait for chat to load
        message_box = WebDriverWait(self.driver, 10).until(
            EC.presence_of_element_located((By.XPATH, '//div[@contenteditable="true"][@data-tab="10"]'))
        )
        
        # Type message
        message_box.clear()
        
        # Handle multi-line messages
        lines = message.split('\n')
        for i, line in enumerate(lines):
            message_box.send_keys(line)
            if i < len(lines) - 1:
                message_box.send_keys(Keys.SHIFT + Keys.ENTER)
        
        # Send the message
        send_button = self.driver.find_element(By.XPATH, '//span[@data-icon="send"]')
        send_button.click()
        
        # Wait for message to process
        time.sleep(5)
        logger.info(f"Message sent to {group_name}")
        return True
        
    def start_http_server(self):
        whatsapp_bot = self
        
        class Handler(BaseHTTPRequestHandler):
            def do_POST(self):
                if self.path == '/send-message':
                    content_length = int(self.headers['Content-Length'])
                    post_data = self.rfile.read(content_length).decode('utf-8')
                    
                    try:
                        data = json.loads(post_data)
                        group_name = data.get('name')
                        message = data.get('message')
                        
                        if group_name and message:
                            success = whatsapp_bot.send_message(group_name, message)
                            
                            self.send_response(200)
                            self.send_header('Content-type', 'application/json')
                            self.end_headers()
                            self.wfile.write(json.dumps({"status": "success"}).encode())
                        else:
                            self.send_response(400)
                            self.send_header('Content-type', 'application/json')
                            self.end_headers()
                            self.wfile.write(json.dumps({"status": "error", "message": "Missing name or message"}).encode())
                    except Exception as e:
                        self.send_response(500)
                        self.send_header('Content-type', 'application/json')
                        self.end_headers()
                        self.wfile.write(json.dumps({"status": "error", "message": str(e)}).encode())
                else:
                    self.send_response(404)
                    self.end_headers()
            
            def do_GET(self):
                if self.path == '/health':
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({"status": "healthy"}).encode())
                else:
                    self.send_response(404)
                    self.end_headers()
        
        # Start server in a separate thread
        server = HTTPServer(('0.0.0.0', 3003), Handler)
        server_thread = threading.Thread(target=server.serve_forever)
        server_thread.daemon = True
        server_thread.start()
        logger.info("HTTP server started on port 3003")

# Main execution
if __name__ == "__main__":
    try:
        logger.info("Starting WhatsApp Bot")
        bot = WhatsAppBot()
        bot.login_to_whatsapp()
        bot.start_http_server()
        
        logger.info("Bot is running. Press Ctrl+C to exit")
        
        # Keep the script running
        while True:
            time.sleep(60)
            logger.info("Bot is still running...")
            
    except KeyboardInterrupt:
        logger.info("Bot stopped by user")
    except Exception as e:
        logger.error(f"Error: {e}")
