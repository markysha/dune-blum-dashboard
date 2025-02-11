import os
import yaml
from dune_client.client import DuneClient
from dotenv import load_dotenv
import sys
import codecs

# Set the default encoding to UTF-8
sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

dotenv_path = os.path.join(os.path.dirname(__file__), '..', '.env')
load_dotenv(dotenv_path)

dune = DuneClient.from_env()

# Read the queries.yml file
queries_yml = os.path.join(os.path.dirname(__file__), '..', 'queries.yml')
with open(queries_yml, 'r', encoding='utf-8') as file:
    data = yaml.safe_load(file)

# Extract the query_ids from the data
query_ids = [id for id in data['query_ids']]

print("Updating", len(query_ids), "queries.")

successed = 0

for id in query_ids:
    query = dune.get_query(id)
    print('PROCESSING: query {}, {}'.format(query.base.query_id, query.base.name))

    # Check if query file exists in /queries folder
    queries_path = os.path.join(os.path.dirname(__file__), '..', 'queries')
    files = os.listdir(queries_path)
    found_files = [file for file in files if str(id) == file.split('___')[-1].split('.')[0]]
    
    if len(found_files) != 0:
        file_path = os.path.join(os.path.dirname(__file__), '..', 'queries', found_files[0])
        # Read the content of the file
        with open(file_path, 'r', encoding='utf-8') as file:
            text = file.read()

            try:
                # Update existing file
                query_id = str(query.base.query_id)  # Ensure query_id is a string
                result = dune.update_query(
                    query_id=query_id,
                    query_sql=text,
                    name=query.base.name  # Preserve the original query name
                )
                print(f'SUCCESS: updated query {query_id} to dune')
                successed += 1
            except Exception as e:
                print(f'ERROR updating query {query.base.query_id}: {str(e)}')
                continue
    else:
        print(f'ERROR: file not found, query id {query.base.query_id}')

print("Updated", successed, "of", len(query_ids), "queries.")