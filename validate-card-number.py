import re

def validate_credit_card(card_number):
    # Check if the card number starts with 4, 5, or 6 and has exactly 16 digits
    if not re.match(r"^[4-6]\d{3}-?\d{4}-?\d{4}-?\d{4}$", card_number):
        return False
    
    # Remove hyphens if present
    card_number = card_number.replace("-", "")
    
    # Check for consecutive repeated digits
    if re.search(r"(\d)\1{3,}", card_number):
        return False
    
    return True

testing_card_numbers = [
    "4123456789123456",
    "5123-4567-8912-3456",
    "61234-567-8912-3456",
    "4123356789123456",
    "5133-3367-8912-3456",
    "5123 - 3567 - 8912 - 3456",
]

user_input = input()
input_counts = int(user_input)

for card_number in range(input_counts):
    line = input()
    if validate_credit_card(line):
        print("Valid")
    else:
        print("Invalid")
