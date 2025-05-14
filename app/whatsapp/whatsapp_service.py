import logging
import time
import os
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("whatsapp.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('whatsapp_service')

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

logger.info("WhatsApp service starting...")

try:
    from whatsapp.whatsapp_sender import WhatsAppSender
    
    # Initialize WhatsApp
    whatsapp = WhatsAppSender()
    logger.info("WhatsApp sender initialized")
    
    # Keep the service running
    while True:
        logger.info("WhatsApp service is running...")
        time.sleep(60)
except Exception as e:
    logger.error(f"Error in WhatsApp service: {str(e)}")
    import traceback
    logger.error(traceback.format_exc())
