class WhatsAppSender:
    def __init__(self):
        self.initialized = True
        print("WhatsApp sender initialized")
        
    def send_message(self, phone_number, message):
        print(f"Sending message to {phone_number}: {message}")
        return True
