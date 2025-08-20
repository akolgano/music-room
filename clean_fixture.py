#!/usr/bin/env python3
import json


def clean_sample_fixture():
    fixture_paths = [
        'sample.json',
        'apps/playlists/fixtures/sample.json'
    ]
    
    for fixture_path in fixture_paths:
        try:
            with open(fixture_path, 'r') as f:
                data = json.load(f)
            
            print(f"Found fixture: {fixture_path}")
            print(f"Original entries: {len(data)}")
            
            cleaned_data = [
                item for item in data 
                if item.get('model') != 'contenttypes.contenttype'
            ]
            
            print(f"After cleaning: {len(cleaned_data)}")
            
            with open(f"{fixture_path}.backup", 'w') as f:
                json.dump(data, f, indent=2)
            
            with open(fixture_path, 'w') as f:
                json.dump(cleaned_data, f, indent=2)
            
            print(f"Cleaned {fixture_path}")
            print(f"Backup saved as {fixture_path}.backup")
            return True
            
        except FileNotFoundError:
            continue
        except Exception as e:
            print(f"Error: {e}")
            return False
    
    print("No fixture file found")
    return False


if __name__ == "__main__":
    clean_sample_fixture()
