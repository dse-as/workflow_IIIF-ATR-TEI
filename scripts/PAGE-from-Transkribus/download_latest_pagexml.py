#! /usr/bin/python3

"""
Download the latest pagexml of all pages over several collections.

This code is largely based on https://github.com/history-unibas/Trankribus-API/blob/main/download_latest_pagexml.py
MIT License (c) 2023 University of Basel, Department of History
"""

import requests
import xml.etree.ElementTree as et
import time
import logging
import pandas as pd
from datetime import datetime
import argparse
import os

def get_sid(usr, pw):
    # Login to the API of transkribus and return the session id

    r = requests.post("https://transkribus.eu/TrpServer/rest/auth/login", data={"user": usr, "pw": pw})
    if r.status_code == requests.codes.ok:
        login_data = et.fromstring(r.text)
        return login_data.find("sessionId").text
    else:
        logging.error(f'Login failed: {r}')
        raise

def list_collections(sid):
    # Get information of all collections available for the account

    r = requests.get("https://transkribus.eu/TrpServer/rest/collections/list?JSESSIONID={}".format(sid))
    if r.status_code == requests.codes.ok:
        return r.json()
    else:
        logging.error(f'SessionID invalid? {r}')
        raise

def list_documents(sid, colid):
    # Get information of all documents of one collection

    r = requests.get("https://transkribus.eu/TrpServer/rest/collections/{}/list?JSESSIONID={}".format(colid, sid))
    if r.status_code == requests.codes.ok:
        return r.json()
    else:
        logging.error(f'SessionID or collectionID invalid? {r}')
        raise

def get_document_content(colid, docid, sid):
    # Get content of a specific document

    r = requests.get("https://transkribus.eu/TrpServer/rest/collections/{}/{}/fulldoc?JSESSIONID={}".format(colid,
                                                                                                            docid,
                                                                                                            sid))
    if r.status_code == requests.codes.ok:
        return r.json()
    else:
        logging.error(f'documentID or collectionID invalid? {r}')
        raise

def download_pagexml(url, path, n_retry=60):
    """Download a pagexml file.

    Args:
        url (str): Url to a page xml file.
        path (str): Target filepath to store the page xml file.
        n_retry (int): Number of retries by request error.

    Returns:
        None.
    """
    try:
        response = requests.get(url)
        response.raise_for_status()

        with open(path, "wb") as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
    except:
        if n_retry > 0:
            n_retry -= 1
            time.sleep(60)
            download_pagexml(url, path, n_retry)
        else:
            response.raise_for_status()

def main():
    # Define target directory for pageXMLs.
    dest_dir = os.path.join(os.getcwd(),'download')

    # Login to Transkribus.
    parser = argparse.ArgumentParser(description='Download PageXML files from Transkribus.')
    parser.add_argument('-u', '--user', help='<Required> Username', required=True)
    parser.add_argument('-p', '--password', help='<Required> Password', required=True)
    parser.add_argument('-c','--collections', nargs='+', help='<Required> Collection IDs', required=True)
    args = parser.parse_args()
    user = args.user
    password = args.password
    collections = args.collections
    sid = get_sid(user, password)
    
    # Read all available collections.
    coll = pd.DataFrame(list_collections(sid))

    # Save pagexmls of all pages within collections of interest.
    for col in coll.iterrows():
        if (str(col[1]['colId']) not in collections):
            continue
        docs = list_documents(sid, col[1]['colId'])

        print('Downloading collection ' + str(col[1]['colId']) + ' (' + str(len(docs)) + ' documents)')

        for doc in docs:
            pages = get_document_content(col[1]['colId'], doc['docId'], sid)

            print('Downloading document ' + str(doc['docId']) + ' (' + str(len(pages)) + ' pages)')

            # Create destination folder.
            dest_path = f"{dest_dir}/{col[1]['colId']}/page/{doc['title']}"
            if not os.path.exists(dest_path):
                os.makedirs(dest_path)

            for page in pages['pageList']['pages']:
                # Determine the latest transcript.
                timestamp_latest = datetime.min
                timestamp_latest_gt = datetime.min
                index_latest = None
                index_latest_gt = None
                index = -1
                for transcript in page['tsList']['transcripts']:
                    index += 1
                    timestamp = datetime.fromtimestamp(
                        transcript['timestamp']/1000
                        )
                    timestamp_latest = max(timestamp_latest, timestamp)
                    if timestamp_latest == timestamp:
                        index_latest = index

                if (index_latest_gt is not None
                    and index_latest != index_latest_gt):
                    index_latest = index_latest_gt

                # Download pagexml of latest transcript.
                url_latest = page['tsList']['transcripts'][index_latest]['url']
                filename_latest = page['tsList']['transcripts'][index_latest]['fileName']
                path = f'{dest_path}/{filename_latest}'
                download_pagexml(url_latest, path)

        print('Finished collection ' + str(col[1]['colId']))

if __name__ == "__main__":
    main()
