import os
import sys
import time
import logging
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('whatsapp_qr')

def setup_driver():
    """Set up and return a configured Chrome WebDriver"""
    from selenium.webdriver.chrome.service import Service
    
    chrome_options = Options()
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--window-size=1920,1080")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--disable-extensions")
    
    # Don't make the browser headless so the QR code is visible
    # chrome_options.add_argument("--headless")
    
    try:
        # Try with webdriver_manager (recommended)
        try:
            from webdriver_manager.chrome import ChromeDriverManager
            service = Service(ChromeDriverManager().install())
            driver = webdriver.Chrome(service=service, options=chrome_options)
            return driver
        except Exception as fallback_error:
            logger.warning(f"Couldn't use webdriver_manager: {fallback_error}")
            
        # Try with explicit Chrome binary path
        chrome_paths = [
            "/usr/bin/google-chrome",
            "/usr/bin/chromium-browser",
            "/snap/bin/chromium",
            "/opt/google/chrome/google-chrome"
        ]
        
        for chrome_path in chrome_paths:
            if os.path.exists(chrome_path):
                logger.info(f"Using Chrome binary at: {chrome_path}")
                chrome_options.binary_location = chrome_path
                
                # Create a service with default chromedriver
                driver = webdriver.Chrome(options=chrome_options)
                return driver
        
        # If we got here, we couldn't find Chrome
        raise Exception("Chrome binary not found in expected locations")
    
    except Exception as e:
        logger.error(f"Failed to initialize WebDriver: {e}")
        return None


def open_whatsapp_web(driver):
    """Open WhatsApp Web and wait for QR code to appear"""
    try:
        # Set a reasonable page load timeout
        driver.set_page_load_timeout(60)
        
        # Navigate to WhatsApp Web
        driver.get("https://web.whatsapp.com/")
        logger.info("Opened WhatsApp Web")
        
        # Wait for either the QR code or the chat list to appear
        # (in case user is already logged in)
        try:
            logger.info("Waiting for QR code or chat list to appear...")
            WebDriverWait(driver, 30).until(
                lambda d: len(d.find_elements(By.XPATH, '//canvas[contains(@aria-label, "Scan me!")]')) > 0 or 
                          len(d.find_elements(By.XPATH, '//div[@id="side"]')) > 0
            )
            
            # Check if we're already logged in
            if len(driver.find_elements(By.XPATH, '//div[@id="side"]')) > 0:
                logger.info("Already logged in to WhatsApp Web!")
                return True
                
            # If we got here, the QR code is showing
            logger.info("QR Code is ready for scanning")
            logger.info("Please scan the QR code with your WhatsApp mobile app")
            
            # Take a screenshot to help the user see the QR code
            screenshot_path = os.path.join(os.getcwd(), "whatsapp_qr.png")
            driver.save_screenshot(screenshot_path)
            logger.info(f"QR code screenshot saved to: {screenshot_path}")
            
            # Wait for user to scan QR and WhatsApp to load
            WebDriverWait(driver, 180).until(
                lambda d: len(d.find_elements(By.XPATH, '//div[@id="side"]')) > 0
            )
            logger.info("Successfully logged in to WhatsApp Web!")
            return True
            
        except Exception as wait_error:
            logger.error(f"Error waiting for QR code or login: {wait_error}")
            
            # Try to take a screenshot anyway to help debug
            try:
                screenshot_path = os.path.join(os.getcwd(), "whatsapp_error.png")
                driver.save_screenshot(screenshot_path)
                logger.info(f"Error state screenshot saved to: {screenshot_path}")
            except:
                pass
                
            return False
            
    except Exception as e:
        logger.error(f"Error opening WhatsApp Web: {e}")
        return False

def main():
    """Main function to open WhatsApp Web and display QR code"""
    logger.info("Starting WhatsApp QR code generator")
    
    driver = setup_driver()
    if not driver:
        logger.error("Failed to set up WebDriver. Exiting.")
        return
    
    try:
        success = open_whatsapp_web(driver)
        
        if success:
            logger.info("WhatsApp Web is now ready for use.")
            # If successful, keep browser open for a while
            time.sleep(300)  # Keep the browser open for 5 minutes
        else:
            logger.info("Failed to complete WhatsApp Web login.")
            
    except KeyboardInterrupt:
        logger.info("Process interrupted by user.")
    finally:
        logger.info("Closing browser...")
        driver.quit()

if __name__ == "__main__":
    main()
