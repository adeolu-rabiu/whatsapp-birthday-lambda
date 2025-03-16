import boto3
import logging
import os
from boto3.dynamodb.conditions import Key

logger = logging.getLogger()
logger.setLevel(logging.INFO)

class BirthdayDAO:
    def __init__(self):
        """Initialize the DynamoDB connection"""
        self.dynamodb = boto3.resource('dynamodb')
        self.birthdays_table = self.dynamodb.Table(os.getenv('BIRTHDAYS_TABLE', 'Birthdays'))
        self.groups_table = self.dynamodb.Table(os.getenv('GROUPS_TABLE', 'WhatsAppGroups'))

    def get_whatsapp_groups(self):
        """Retrieve all WhatsApp groups from DynamoDB"""
        try:
            response = self.groups_table.scan()
            return response.get('Items', [])
        except Exception as e:
            logger.error(f"Error retrieving WhatsApp groups: {str(e)}")
            return []

    def get_todays_birthdays(self, group_id, month_day):
        """Get today's birthdays in a group"""
        month, day = month_day
        try:
            response = self.birthdays_table.query(
                IndexName='GroupMonthDayIndex',
                KeyConditionExpression=(
                    Key('group_id').eq(group_id) & 
                    Key('birth_month_day').eq(f"{month:02d}-{day:02d}")
                )
            )
            return response.get('Items', [])
        except Exception as e:
            logger.error(f"Error fetching birthdays: {str(e)}")
            return []

    def add_birthday(self, birthday_data):
        """Add a new birthday to DynamoDB"""
        try:
            birth_date = birthday_data['birth_date']
            month_day = '-'.join(birth_date.split('-')[1:])
            birthday_data['birth_month_day'] = month_day

            if 'birthday_id' not in birthday_data:
                birthday_data['birthday_id'] = f"{birthday_data['group_id']}-{birthday_data['name'].replace(' ', '-').lower()}"

            self.birthdays_table.put_item(Item=birthday_data)
            return True
        except Exception as e:
            logger.error(f"Error adding birthday: {str(e)}")
            return False

    def update_birthday(self, birthday_id, group_id, update_data):
        """Update an existing birthday record"""
        try:
            update_expr = "SET "
            expr_attr_values = {}

            for key, value in update_data.items():
                update_expr += f"{key} = :{key}, "
                expr_attr_values[f":{key}"] = value
            
            update_expr = update_expr[:-2]  # Remove last comma

            response = self.birthdays_table.update_item(
                Key={'birthday_id': birthday_id, 'group_id': group_id},
                UpdateExpression=update_expr,
                ExpressionAttributeValues=expr_attr_values,
                ReturnValues="UPDATED_NEW"
            )
            return response.get('Attributes', {})
        except Exception as e:
            logger.error(f"Error updating birthday: {str(e)}")
            return {}

    def delete_birthday(self, birthday_id, group_id):
        """Delete a birthday record"""
        try:
            self.birthdays_table.delete_item(
                Key={'birthday_id': birthday_id, 'group_id': group_id}
            )
            return True
        except Exception as e:
            logger.error(f"Error deleting birthday: {str(e)}")
            return False
