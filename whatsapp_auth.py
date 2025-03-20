import sys
import os
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from webdriver_manager.chrome import ChromeDriverManager

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

# Import WhatsApp module
from app.whatsapp.whatsapp_sender import WhatsAppSender

def main():
    print("Initializing WhatsApp sender...")
    sender = WhatsAppSender()
    
    # Modify the initialize_whatsapp method to capture QR code
    original_initialize = sender.initialize_whatsapp
    
    def modified_initialize():
        """Modified initialize method to capture and save QR code"""
        # Use non-headless Chrome to see the QR code
        chrome_options = Options()
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--window-size=1920,1080")
        chrome_options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36")

        # Use webdriver-manager to get the correct ChromeDriver
        service = Service(ChromeDriverManager().install())
        
        # Override the headless option to see the QR code
        sender.driver = webdriver.Chrome(service=service, options=chrome_options)
        sender.driver.get("https://web.whatsapp.com/")
        
        print("\n>>> WhatsApp Web opened. Please scan the QR code with your phone's WhatsApp app <<<\n")
        print("Waiting for you to scan the QR code (60 seconds timeout)...")
        
        try:
            # Wait for login
            WebDriverWait(sender.driver, 60).until(
                EC.presence_of_element_located((By.XPATH, "//div[@contenteditable='true']"))
            )
            sender.logged_in = True
            print("\n✅ Authentication successful! You're now logged in.")
            print("The session is now active. You can close this script with Ctrl+C")
            
            # Keep the browser open to maintain the session
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                print("\nClosing session...")
                sender.close()
                
        except TimeoutException:
            print("\n❌ Authentication failed: QR code not scanned in time.")
            sender.close()
    
    # Replace the original method with our modified version
    sender.initialize_whatsapp = modified_initialize
    
    # Call the modified method
    try:
        sender.initialize_whatsapp()
    except Exception as e:
        print(f"Error during initialization: {str(e)}")
        if hasattr(sender, 'driver') and sender.driver:
            sender.close()

if __name__ == "__main__":
    main()
