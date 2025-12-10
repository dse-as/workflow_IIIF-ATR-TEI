import json
import os
import requests
import logging
import re
from requests_toolbelt.multipart.encoder import MultipartEncoder
from lxml import etree
import time
import random

# Setup logging to both console and file
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),  # Log to console
        logging.FileHandler('output.log')  # Log to a file named output.log
    ]
)

# Global variables
issue_desc = None
session = None  # Session for Transkribus

def load_issue_data(issue_file='./issue-parser-result.json'):
    global issue_desc
    try:
        with open(issue_file) as f:
            issue_desc = json.load(f)
        logging.info("Issue data loaded successfully.")
    except Exception as e:
        logging.error(f"Error loading issue data: {e}")
        raise

def load_secrets():
    try:
        # Accessing the TRANSKRIBUS_CREDENTIALS secret as an environment variable
        transkribus_credentials = os.getenv("TRANSKRIBUS_CREDENTIALS")
        if transkribus_credentials is None:
            raise ValueError("TRANSKRIBUS_CREDENTIALS environment variable not found.")
        logging.info("Secrets loaded successfully.")
        return json.loads(transkribus_credentials)  # Returning the parsed JSON directly

    except Exception as e:
        logging.error(f"Error loading secrets: {e}")
        raise

def authenticate_with_transkribus(creds):
    """Authenticate and create a session with Transkribus."""
    global session
    session = requests.Session()
    try:
        response = session.post('https://transkribus.eu/TrpServer/rest/auth/login', data=creds)
        response.raise_for_status()
        logging.info("Successfully authenticated with Transkribus.")
    except requests.exceptions.RequestException as e:
        logging.error(f"Authentication failed: {e}")
        raise

def iiif_manifest(url):
    """Fetch the IIIF manifest data."""
    try:
        r = requests.get(url)
        r.raise_for_status()
        return r.json()
    except requests.exceptions.RequestException as e:
        logging.error(f"Error fetching IIIF manifest: {e}")
        raise

def get_pages(manifest):
    """Extract pages from IIIF manifest."""
    pages_dict = {}
    for page in manifest['items']:
        try:
            pages_dict[page['label']['en'][0]] = page['items'][0]['items'][0]['body']['id']
        except KeyError as e:
            logging.error(f"KeyError while extracting page info: {e}")
            continue
    logging.info(f"Extracted {len(pages_dict)} pages.")
    return pages_dict

def download_pages(pages, wait=1):
    """Download the images for each page."""
    page_dict = {}
    for page in enumerate(sorted(pages)):
        try:
            filename = page[1]
            base_url = pages[filename]
            base_url = base_url.removesuffix('/info.json')  # Clean up the URL
            full_url = f"{base_url}/full/max/0/default.jpg"
            r = requests.get(full_url, stream=True)
            page_dict[filename + ".jpg"] = r.content
            logging.info(f"Downloaded {filename}.jpg")
            time.sleep(wait)
        except Exception as e:
            logging.error(f"Error processing page {filename}: {e}")
            continue
    return page_dict

def upload_file(upload_id, file_name, file_data):
    """Upload a single file to Transkribus."""
    try:
        mp_encoder = MultipartEncoder(
            fields={'img': (file_name, file_data, 'application/octet-stream')}
        )
        cont = session.put(
            f'https://transkribus.eu/TrpServer/rest/uploads/{upload_id}', 
            data=mp_encoder, 
            headers={'Content-Type': mp_encoder.content_type}
        )
        cont.raise_for_status()  # Will raise an error for bad responses
        logging.info(f"File {file_name} uploaded successfully.")
    except Exception as e:
        logging.error(f"Failed to upload {file_name}: {e}")
        raise  # Reraise to handle in higher level if needed

def process_uploads(to_process, collection_id):
    """Process and upload all the pages for each manifest."""
    skipped = []
    result_output = []  # Collect the result output

    for processing in to_process:
        fail = False
        logging.info(f"Processing {processing}...")

        # Fetch IIIF manifest and download pages
        manifest = iiif_manifest(processing)
        pages = get_pages(manifest)
        files = download_pages(pages)

        if not files:
            logging.error(f"No files to upload for {processing}. Skipping.")
            skipped.append(processing)
            result_output.append(f"Processing {processing} - SKIPPED 🚫\nUpload object: None")
            continue

        pages_metadata = [{'fileName': val, 'pageNr': idx + 1} for idx, val in enumerate(sorted(files))]

        upload_obj = {
            "md": {
                "title": re.sub('https?://iiif.annemarie-schwarzenbach.ch/presentation/', '', processing),
                "externalId": re.sub('https?://iiif.annemarie-schwarzenbach.ch/presentation/', '', processing).replace('.json', '')
            },
            "pageList": {"pages": pages_metadata}
        }

        try:
            response = session.post(f'https://transkribus.eu/TrpServer/rest/uploads?collId={collection_id}', json=upload_obj)
            response.raise_for_status()
            response_xml = etree.fromstring(response.content)
            upload_id = response_xml.xpath('//uploadId/text()')[0]
            logging.info(f"Upload metadata successful. Got uploadId: {upload_id}")

            for key in sorted(files):
                try:
                    upload_file(upload_id, key, files[key])
                    time.sleep(random.randint(0, 2))
                except Exception as e:
                    logging.error(f"Failed to upload {key}. Error: {e}")
                    fail = True
                    break

            # Append both upload_obj and status **together**
            status_line = "FINISHED 🟢" if not fail else "FAILED 🚫"
            result_output.append(f"Upload object: {upload_obj}\nJob Status: {status_line}\n")

        except Exception as e:
            logging.error(f"Error processing {processing}: {e}")
            skipped.append(processing)
            result_output.append(f"Upload object: {upload_obj}\nJob Status: ERROR ❌ - {e}\n")

# (old pattern:)
################
# Processing https://iiif.annemarie-schwarzenbach.ch/presentation/letter_0349.json
# - with upload object: {'md': {'title': 'letter_0349.json', 'externalId': 'letter_0349'}, 'pageList': {'pages': [{'fileName': 'letter_0349_001.jpg', 'pageNr': 1}, {'fileName': 'letter_0349_002.jpg', 'pageNr': 2}]}}
# - successfully uploaded metadata, got id 10453419
# - transmitting file(s)
# - job status (18212681): FINISHED 🟢
# - done!
# ══════════════════════

        except Exception as e:
            logging.error(f"Error processing {processing}: {e}")
            skipped.append(processing)
            result_output.append(f"Processing {processing} - Error: {e}")

    return skipped, result_output

if __name__ == '__main__':
    try:
        # Load issue data and secrets
        load_issue_data()
        transkribus_credentials = load_secrets()

        # Authenticate with Transkribus
        authenticate_with_transkribus(transkribus_credentials)

        # Extract manifests and collection ID
        to_process = issue_desc['iiif-manifests'].splitlines()[1:-1]
        collection_id = re.search(r"\((\w+)\)", issue_desc['target-collection']).group(0)[1:-1]

        # Process the uploads
        skipped, result_output = process_uploads(to_process, collection_id)

        # Final logs
        if skipped:
            logging.warning(f"Skipped processing for the following manifests: {skipped}")
        else:
            logging.info("All manifests processed successfully.")

        # Output results
        with open('/tmp/output.log', 'a') as f:
            f.write("\n".join(result_output) + "\n")

    except Exception as e:
        logging.error(f"Workflow failed: {e}")
        with open('/tmp/output.log', 'a') as f:
            f.write(f"Workflow failed: {e}\n")
