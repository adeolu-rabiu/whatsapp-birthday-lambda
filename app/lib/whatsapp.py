def format_message(birthday_data):
    """Format the WhatsApp message for the birthday person"""
    return f"Hey {birthday_data['name']}! {birthday_data['message']}"

class WhatsAppClient:
    def __init__(self):
        # In a real implementation, this would initialize Selenium or API client
        pass
        
    def send_message(self, recipient, message):
        # This would send message via WhatsApp in a real implementation
        pass

def send_birthday_messages(birthdays):
    """Send WhatsApp messages to all birthday people"""
    client = WhatsAppClient()
    
    # Send message to each birthday person
    for birthday in birthdays:
        message = format_message(birthday)
        # Send the formatted message
        client.send_message(birthday.get('phone', ''), message)
