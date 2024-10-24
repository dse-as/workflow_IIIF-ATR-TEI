# Workflow IIIF-ATR-TEI

Scripts for Transkribus-related workflows:

* upload IIIF Manifest to Transkribus
* download PAGE XML from Transkribus
* transform PAGE XML to TEI

## Download PAGE

```bash
python scripts/PAGE-from-Transkribus/download_latest_pagexml.py -u 'YOUR-USERNAME' -p 'YOUR-PASSWORD' -c 'YOUR-COLLECTION-ID1' 'YOUR-COLLECTION-ID2'
```

## PAGE to TEI

```bash
python scripts/PAGE-to-raw-TEI/page2TEI.py -i download -o download_out
```


