#!/usr/bin/env python3
"""
Group name normalization for fuzzy matching
"""

def normalize_group_name(name):
    """Strip and normalize whitespace in group names"""
    if not name:
        return name
    return ' '.join(name.strip().split())

def find_matching_group(groups, target_name):
    """
    Find group with fuzzy matching (handles whitespace differences)
    
    Args:
        groups: List of group dicts from wppconnect
        target_name: Group name to search for (from DynamoDB)
    
    Returns:
        Matching group dict or None
    """
    normalized_target = normalize_group_name(target_name)
    
    # Try exact match first
    for group in groups:
        if group.get('name') == target_name:
            return group
    
    # Try normalized match
    for group in groups:
        if normalize_group_name(group.get('name', '')) == normalized_target:
            return group
    
    return None

def get_group_id(groups, group_name):
    """
    Get group ID with fuzzy matching
    
    Args:
        groups: List of groups from wppconnect
        group_name: Group name to find
    
    Returns:
        Group ID or None
    """
    group = find_matching_group(groups, group_name)
    return group.get('id') if group else None

# Test
if __name__ == '__main__':
    test_groups = [
        {'id': '123@g.us', 'name': 'Huawei UK Alumni '},  # with space
        {'id': '456@g.us', 'name': 'Family_Corner'},
    ]
    
    # Test cases
    test_names = [
        'Huawei UK Alumni',   # without space
        'Huawei UK Alumni ',  # with space
    ]
    
    for name in test_names:
        result = find_matching_group(test_groups, name)
        print(f"Searching for: [{name}]")
        print(f"Found: {result.get('name') if result else 'None'}")
        print()
