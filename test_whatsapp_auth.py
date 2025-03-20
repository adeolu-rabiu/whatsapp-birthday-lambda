import sys
import os

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

# Import WhatsApp module
from app.whatsapp.whatsapp_sender import WhatsAppSender

def main():
    print("Initializing WhatsApp sender...")
    sender = WhatsAppSender()
    
    print("Starting WhatsApp session...")
    sender.start_session()
    
    print("If you see this message, please check for QR code image file or scan instructions")
    print("After scanning the QR code with your phone, the session should be authenticated")

if __name__ == "__main__":
    main()
