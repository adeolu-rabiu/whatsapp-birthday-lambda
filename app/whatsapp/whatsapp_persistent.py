import time
import os
import sys
import logging
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("whatsapp_persistent.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('whatsapp_persistent')

class WhatsAppPersistent:
    def __init__(self):
        self.driver = None
        self.setup_driver()
    
    def setup_driver(self):
        logger.info("Setting up Chrome driver")
        options = Options()
        options.add_argument("--no-sandbox")
        options.add_argument("--window-size=1920,1080")
        
        try:
            from webdriver_manager.chrome import ChromeDriverManager
            service = Service(ChromeDriverManager().install())
            self.driver = webdriver.Chrome(service=service, options=options)
            logger.info("Chrome driver set up successfully")
        except Exception as e:
            logger.error(f"Failed to initialize Chrome driver: {e}")
            sys.exit(1)
    
    def login_to_whatsapp(self):
        logger.info("Opening WhatsApp Web")
        self.driver.get("https://web.whatsapp.com/")
        
        try:
            # Wait for either QR code or chat list
            WebDriverWait(self.driver, 30).until(
                lambda d: len(d.find_elements(By.XPATH, '//canvas[contains(@aria-label, "Scan me!")]')) > 0 or 
                          len(d.find_elements(By.XPATH, '//div[@id="side"]')) > 0
            )
            
            # Check if QR code is showing
            if len(self.driver.find_elements(By.XPATH, '//canvas[contains(@aria-label, "Scan me!")]')) > 0:
                logger.info("QR code detected - please scan with your phone")
                
                # Take a screenshot of the QR code
                qr_path = os.path.join(os.getcwd(), "whatsapp_login_qr.png")
                self.driver.save_screenshot(qr_path)
                logger.info(f"QR code screenshot saved to: {qr_path}")
                
                # Wait for login
                WebDriverWait(self.driver, 300).until(
                    lambda d: len(d.find_elements(By.XPATH, '//div[@id="side"]')) > 0
                )
                logger.info("Successfully logged in to WhatsApp Web")
            else:
                logger.info("Already logged in to WhatsApp Web")
        except Exception as e:
            logger.error(f"Error during WhatsApp Web login: {e}")
            self.driver.quit()
            sys.exit(1)
    
    def send_message(self, group_name, message):
        try:
            logger.info(f"Sending message to group: {group_name}")
            
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
            
            # Type and send message
            message_box.clear()
            
            # Send message with proper line breaks
            lines = message.split('\n')
            for i, line in enumerate(lines):
                message_box.send_keys(line)
                if i < len(lines) - 1:
                    message_box.send_keys(Keys.SHIFT + Keys.ENTER)
            
            # Send the message
            send_button = self.driver.find_element(By.XPATH, '//span[@data-icon="send"]')
            send_button.click()
            
            # Wait for the message to be processed
            time.sleep(5)
            
            logger.info(f"Message sent to {group_name}")
            return True
        except Exception as e:
            logger.error(f"Error sending message to {group_name}: {e}")
            return False
    
    def check_connection(self):
        try:
            # Try to find the search box as a test of connection
            search_elements = self.driver.find_elements(By.XPATH, '//div[@contenteditable="true"]')
            return len(search_elements) > 0
        except:
            return False
    
    def maintain_connection(self):
        while True:
            try:
                if not self.check_connection():
                    logger.warning("WhatsApp connection lost, reconnecting...")
                    self.setup_driver()
                    self.login_to_whatsapp()
                else:
                    logger.info("WhatsApp connection still active")
                    
                # Click on a neutral element to keep session active
                try:
                    self.driver.find_element(By.XPATH, '//div[@id="side"]').click()
                except:
                    pass
                    
                # Sleep for a while before checking again
                time.sleep(300)  # Check every 5 minutes
            except Exception as e:
                logger.error(f"Error in maintain_connection: {e}")
                try:
                    self.driver.quit()
                except:
                    pass
                self.setup_driver()
                self.login_to_whatsapp()

if __name__ == "__main__":
    logger.info("Starting WhatsApp Persistent Connection Service")
    whatsapp = WhatsAppPersistent()
    whatsapp.login_to_whatsapp()
    
    # Send an initial test message if needed
    # whatsapp.send_message("Family Forum", "WhatsApp Persistent Service is now running")
    
    # Keep the connection alive
    whatsapp.maintain_connection()
