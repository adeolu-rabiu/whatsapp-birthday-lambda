import os
import time
import logging
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

logger = logging.getLogger()
logger.setLevel(logging.INFO)

class WhatsAppSender:
    def __init__(self):
        self.driver = None
        self.logged_in = False
    
    def initialize_whatsapp(self):
        """Initialize WhatsApp Web in headless Chrome"""
        chrome_options = Options()
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--window-size=1920,1080")
        chrome_options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36")
        
        # Start WebDriver
        self.driver = webdriver.Chrome(options=chrome_options)
        self.driver.get("https://web.whatsapp.com/")
        
        # Wait for QR code scan or automatic login
        try:
            logger.info("Waiting for WhatsApp to load...")
            WebDriverWait(self.driver, 30).until(
                EC.presence_of_element_located((By.XPATH, "//div[@contenteditable='true']"))
            )
            self.logged_in = True
            logger.info("WhatsApp loaded successfully")
        except TimeoutException:
            logger.error("QR code needs to be scanned manually")
            raise Exception("QR code scan required. Cannot proceed in Lambda environment.")
    
    def navigate_to_group(self, group_name):
        """Navigate to a specific WhatsApp group"""
        if not self.logged_in:
            raise Exception("Not logged in to WhatsApp")
        
        logger.info(f"Navigating to group: {group_name}")
        
        search_box = self.driver.find_element(By.XPATH, "//div[@contenteditable='true']")
        search_box.click()
        search_box.send_keys(group_name)
        
        try:
            group_title = WebDriverWait(self.driver, 10).until(
                EC.presence_of_element_located((By.XPATH, f"//span[@title='{group_name}']"))
            )
            group_title.click()
            WebDriverWait(self.driver, 10).until(
                EC.presence_of_element_located((By.XPATH, "//footer"))
            )
            logger.info(f"Successfully navigated to group: {group_name}")
        except TimeoutException:
            logger.error(f"Group not found: {group_name}")
            raise Exception(f"Group not found: {group_name}")
    
    def send_message(self, message):
        """Send a message to the current chat"""
        if not self.logged_in:
            raise Exception("Not logged in to WhatsApp")
        
        try:
            input_box = self.driver.find_element(By.XPATH, "//div[@contenteditable='true']")
            input_box.click()
            input_box.send_keys(message)
            send_button = self.driver.find_element(By.XPATH, "//span[@data-icon='send']")
            send_button.click()
            time.sleep(2)
            logger.info("Message sent successfully")
        except Exception as e:
            logger.error(f"Failed to send message: {str(e)}")
            raise Exception(f"Failed to send message: {str(e)}")
    
    def close(self):
        """Close the WebDriver session"""
        if self.driver:
            self.driver.quit()
            logger.info("WebDriver session closed")
