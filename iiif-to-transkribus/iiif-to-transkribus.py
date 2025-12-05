import json
import re
import requests
import time
import random
import os
from requests_toolbelt.multipart.encoder import MultipartEncoder
from lxml import etree
import logging

# Setup logging for debugging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

# Global variables (set by GitHub Action environment)
issue_desc = None
secrets = None

def load_issue_data(issue_file='./issue-parser-result.json'):
    global issue_desc
    try:
        with open(issue_file) as f:
            issue_desc = json.load(f)
        logging.info("Issue data loaded successfully.")
    except Exception as e:
        logging.error(f"Error loading issue data: {e}")
        raise

def load_secrets(secrets_file='./secrets.json'):
    global secrets
    try:
        with open(secrets_file) as f:
            secrets = json.load(f)
        logging.info("Secrets loaded successfully.")
    except Exception as e:
        logging.error(f"Error loading secrets: {e}")
        raise

def iiif_manifest(url):
    try:
        r = requests.get(url)
        r.raise_for_status()
        return r.json()
    except requests.exceptions.RequestException as e:
        logging.error(f"Error fetching IIIF manifest: {e}")
        raise

def get_pages(manifest):
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
    page_dict = {}
    for page in enumerate(sorted(pages)):
        try:
            filename = page[1]
            base_url = pages[filename]
            # Remove 'info.json' if it exists and build the full URL
            base_url = re.sub(r'/info\.json$', '', base_url)
            full_url = base_url + '/full/max/0/default.jpg'
            r = requests.get(full_url, stream=True)
            page_dict[filename + ".jpg"] = r.content
            logging.info(f"Downloaded {filename}.jpg")
            time.sleep(wait)
        except Exception as e:
            logging.error(f"Error processing page {filename}: {e}")
            continue
    return page_dict

def process_uploads(to_process, collection_id):
    skipped = []
    for processing in to_process:
        fail = False
        logging.info(f"Processing {processing}...")

        manifest = iiif_manifest(processing)
        pages = get_pages(manifest)
        files = download_pages(pages)

        pages_metadata = [{'fileName': val, 'pageNr': idx+1} for idx, val in enumerate(sorted(files))]

        upload_obj = {
            "md": {
                "title": re.sub('https?://iiif.annemarie-schwarzenbach.ch/presentation/', '', processing),
                "externalId": re.sub('https?://iiif.annemarie-schwarzenbach.ch/presentation/', '', processing).replace('.json', '')
            },
            "pageList": {"pages": pages_metadata}
        }

        logging.info(f"Created upload object: {upload_obj}")

        try:
            headers = {'Content-type': 'application/json'}
            response = requests.post(f'https://transkribus.eu/TrpServer/rest/uploads?collId={collection_id}', json=upload_obj, headers=headers)
            response.raise_for_status()
            response_xml = etree.fromstring(response.content)
            upload_id = response_xml.xpath('//uploadId/text()')[0]
            logging.info(f"Upload metadata successful. Got uploadId: {upload_id}")
            logging.info("Transmitting files...")

            for key in sorted(files):
                mp_encoder = MultipartEncoder(
                    fields={'img': (key, files[key], 'application/octet-stream')}
                )
                try:
                    upload_response = requests.put(
                        f'https://transkribus.eu/TrpServer/rest/uploads/{upload_id}', data=mp_encoder,
                        headers={'Content-Type': mp_encoder.content_type}
                    )
                    upload_response.raise_for_status()
                    response_xml = etree.fromstring(upload_response.content)
                    job_id = response_xml.xpath('//jobId/text()')[0]
                    logging.info(f"File {key} uploaded. Job ID: {job_id}")
                except Exception as e:
                    logging.error(f"Failed to upload {key}: {e}")
                    fail = True
                    break

            if not fail:
                job_status = requests.get(f'https://transkribus.eu/TrpServer/rest/jobs/{job_id}')
                job_status.raise_for_status()
                job_state = job_status.json().get("state")
                logging.info(f"Job status: {job_state} (ID: {job_id})")
            else:
                skipped.append(processing)

        except Exception as e:
            logging.error(f"Error processing {processing}: {e}")
            skipped.append(processing)

    return skipped

if __name__ == '__main__':
    try:
        # Load data from files
        load_issue_data()
        load_secrets()

        # Extract manifests and collection ID
        to_process = issue_desc['iiif-manifests'].splitlines()[1:-1]
        collection_id = re.search(r"\((\w+)\)", issue_desc['target-collection']).group(0)[1:-1]

        # Process uploads
        skipped = process_uploads(to_process, collection_id)

        # Final logs
        if skipped:
            logging.warning(f"Skipped processing for the following manifests: {skipped}")
        else:
            logging.info("All manifests processed successfully.")
    except Exception as e:
        logging.error(f"Workflow failed: {e}")
