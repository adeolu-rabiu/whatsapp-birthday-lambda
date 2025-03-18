import datetime
from app.lib import db, whatsapp

def get_todays_birthdays():
    # Get today's date in MM-DD format
    today = datetime.datetime.now().strftime("%m-%d")
    # Query DynamoDB for birthdays on this date
    return db.query_birthdays_by_date(today)

def lambda_handler(event, context):
    # Get today's birthdays
    birthdays = get_todays_birthdays()
    
    # Send WhatsApp messages
    whatsapp.send_birthday_messages(birthdays)
    
    return {
        'statusCode': 200,
        'body': '{"message": "Birthday notifications sent successfully"}'
    }
