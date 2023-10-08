import pymongo
from pymongo import MongoClient
import json
import os
import logging
import codecs

# Set up logging
logging.basicConfig(filename='mongo_insertion.log', level=logging.INFO, format='%(asctime)s:%(levelname)s:%(message)s')

# Define the MongoDB connection
client = MongoClient('mongodb://localhost:27017/')  # Update with your MongoDB URI if different
db = client['Centralized_Asset_Management_system']  # Update with your database name
collection = db['Scheduling']

# Define the path to the time file
time_file_path = r"<text path>"

# Function to update the time.txt file
def update_time_file():
    # Get the latest document from the collection
    latest_document = collection.find_one(sort=[('_id', pymongo.DESCENDING)])

    # Extract schHours and schMins
    schHours = latest_document['schHours']
    schMins = latest_document['schMins']

    # Format the time as HH:MM
    formatted_time = f"{schHours.zfill(2)}:{schMins.zfill(2)}"

    # Check if the file exists and read its content
    if os.path.exists(time_file_path):
        with open(time_file_path, 'r') as file:
            current_time = file.read().strip()
    else:
        current_time = ""

    # Update the file only if the value has changed
    if current_time != formatted_time:
        with open(time_file_path, 'w') as file:
            file.write(formatted_time + '\n')  # Ensure the format is correct and end with a newline

        print(f"Updated {time_file_path} with new time: {formatted_time}")
    else:
        print(f"No change in time. Current time in file is already {formatted_time}")

# Function to load JSON files into MongoDB
def load_json_to_mongodb():
    print("Clearing existing data...")
    for collection_name in ["CIS Benchmark Compliance", "Devices", "Software", "Lynis", "Nmap_output", "Files"]:
        db[collection_name].delete_many({})

    collection_map = {
        '_compliance': "CIS Benchmark Compliance",
        '_info': "Devices",
        '_software_inventory': "Software",
        '_lynis': "Lynis",
        '_nmap': "Nmap_output",
        '_classification': "Files"
    }

    path_to_json_files = r'<output file>'

    for file_name in os.listdir(path_to_json_files):
        file_path = os.path.join(path_to_json_files, file_name)
        collection_name = None

        with codecs.open(file_path, 'r', encoding='utf-8-sig') as file:
            content = file.read()

        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(content)

        for key, value in collection_map.items():
            if key in file_name:
                collection_name = value
                break

        if collection_name:
            collection = db[collection_name]
            try:
                with open(file_path, 'r') as file:
                    data = json.load(file)

                if isinstance(data, list):
                    collection.insert_many(data)
                else:
                    collection.insert_one(data)

                logging.info(f'Successfully inserted data from {file_name} into {collection_name}')
            except json.JSONDecodeError as e:
                logging.error(f'Error decoding JSON from {file_name}: {e}')
            except Exception as e:
                logging.error(f'Error processing {file_name}: {e}')
        else:
            logging.warning(f'No matching collection for {file_name}')

# Update the time file
update_time_file()

# Load JSON files into MongoDB
load_json_to_mongodb()
